import 'dart:async';
import 'dart:io' show File;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;

import 'package:app/services/connection/connection_service.dart';
import 'package:app/services/inventory/picture_import_model.dart';
import 'package:app/services/inventory/product_image.dart';
import 'package:app/services/inventory/table_field_request.dart';
import 'package:app/services/inventory/table_field_type.dart';
import 'package:app/services/inventory/table_record_request.dart';
import 'package:app/services/stock/tables/table_normalize_model.dart';
import 'package:app/services/stock/tables/table_ready_model.dart';
import 'package:app/services/stock/tables/table_structure_model.dart';
import 'package:app/services/stock/tables/table_view_model.dart';
import 'package:app/services/stock/sources/inventory_source.dart';
import 'package:app/toolkit/api.dart';
import 'package:app/toolkit/deployment.dart';

/// Loading state of a table's structure
/// (`GET /inventory/products/builder/structure/<table_id>`).
enum TableStructureStatus { idle, loading, ready, error }

/// State of the latest records read (`POST /inventory/products/records/list/`).
enum TableViewStatus { idle, loading, ready, empty, error }

/// State of an open table: its structure and its records, read in chunks as
/// they are looked at.
///
/// Opening a table is **two phases**, in this order:
///
/// 1. **The structure** (`GET /inventory/products/builder/structure/<table_id>`): the table's
///    header, its fields and **how many records it has**. It is requested **only
///    once** per open table and is what lets the whole sheet be drawn —the
///    fields row, the columns and the table length— before the first record
///    arrives. The only thing that requests it again is something that changes
///    it: adding a column ([addField]), renaming it or changing its type
///    ([editField]), deleting it ([deleteField]) or adding a record ([add]).
///    Those re-reads happen with the sheet already drawn, so they **do not go
///    back through [TableStructureStatus.loading]**: they are flagged in
///    [isReloading] and the screen is neither unmounted nor loses its place.
/// 2. **The records** (`POST /inventory/products/records/list/`): they are read in pages, but
///    not like pages: the sheet is a single list as long as [records] says, and
///    each chunk is requested when it is about to come on screen
///    ([ensureRange]). There are no paging buttons nor an end that cuts the
///    table; scrolling down keeps going.
///
///    The read is a POST and not a GET because it is a search: the conditions,
///    the order and the paging travel in the body (here the table, the page
///    and, if searching, the search text are sent).
///
/// **Header search is part of that second phase** ([search]). What is written
/// travels in every records read (`MATCH`) and the rows that mention it in any
/// of their columns come back, counted and paged just like the whole table: the
/// sheet hides nothing it has, measures and asks over the result. Hiding would
/// mean searching the chunks that were looked at and not the table, which is a
/// different —and almost always incomplete— answer once the table goes past a
/// few pages.
///
/// Without a structure there is no second phase: if it fails, records are not
/// requested, because there would be no columns to read them against nor a
/// length to give the sheet.
///
/// Records are stored by **absolute index** within the table, not by page: so
/// row 900 is always in place 900 even if you reached it by jumping with the
/// scrollbar, and the blank rows at the end —the ones being written— stay
/// anchored after the last record without shifting every time a new chunk
/// arrives.
///
/// What is read is **not kept forever**: a table can have hundreds of thousands
/// of records and walking it entirely would leave it entirely in memory. A page
/// budget is kept ([_maxCachedPages]) and, once exceeded, the page farthest
/// from the one just read is forgotten; if you go back to it, it is requested
/// again. The budget is deliberately generous: it easily covers any reasonable
/// round trip, and only activates when scrolling the table end to end.
///
/// The table can also change **without anyone on this screen touching it**: when
/// an import finishes the backend types its columns, adds the image one and
/// rewrites the values already stored in them, all of that long after having
/// answered. When it lands, it notifies over the socket (`table/ready`, see
/// [TableReadyModel]) and this service re-reads the table wherever it is: it is
/// the same re-read as a hand-made column change, so it neither unmounts the
/// sheet nor loses where it was.
///
/// Unlike `TablesService` —which caches the company's table list and lives in
/// the app scope—, this service is ephemeral: the table screen itself owns it
/// and it is discarded on exit.
class TableViewService extends ChangeNotifier {
  TableViewService({InventorySource? source}) : _injected = source {
    _unlisten = ConnectionService().on(TableReadyModel.event, _onReady);
    _unlistenPictures = ConnectionService().on(PictureProgress.event, _onPictures);
  }

  final InventorySource? _injected;

  InventorySource get _source => _injected ?? Sources.inventory;

  TableStructureStatus _structureStatus = TableStructureStatus.idle;
  TableStructureModel _structure = const TableStructureModel();

  TableViewStatus _status = TableViewStatus.idle;

  /// `true` while the structure of a table that is **already drawn** is being
  /// re-read (a column was added, its type was changed, a row was saved). It is
  /// not the same as loading it: that shows in [structureStatus] and covers the
  /// screen; this is flagged in the top bar and does not touch the sheet.
  bool _reloading = false;

  /// `true` while a structure read is in flight. It prevents two of them from
  /// stepping on each other; it is kept apart from [structureStatus] because a
  /// re-read does not change that state.
  bool _reading = false;

  /// `true` when a structure re-read did not arrive. The sheet keeps showing
  /// the previous one —it is the only one there is— but it may be stale: the
  /// column change that triggered it did go through. This is what makes the top
  /// bar retry request it again instead of just reloading the chunks.
  bool _staleStructure = false;

  /// Records read, by absolute index within the table. It is sparse on
  /// purpose: from a table of thousands of rows only the ones that were looked
  /// at are present.
  final Map<int, TableRowModel> _rows = {};

  /// The bookkeeping of the chunk-by-chunk read: what was read, what is on its
  /// way and where the table ends.
  TablePaging _paging = TablePaging();

  /// The pages stored in [_rows], in the order they arrived.
  final List<int> _cached = [];

  /// The table being viewed. It is set on open and does not change while the
  /// screen stays alive.
  String? _tableId;

  /// Unsubscribes the `table/ready` listener. The service dies with the
  /// screen, so without this it would keep listening to a table nobody watches
  /// anymore.
  void Function()? _unlisten;

  /// Unsubscribes the `image/progress` listener ([_onPictures]).
  void Function()? _unlistenPictures;

  /// The gathered re-read of the pages in view after pictures landed ([_onPictures]).
  Timer? _picturesTimer;

  /// How long `image/progress` notices are gathered into one re-read. The backend already
  /// sends one per second at most; an import of a thousand pictures still re-reads the rows in
  /// view every few seconds, not every second.
  static const Duration _picturesGather = Duration(seconds: 3);

  /// `true` while a new item is being saved. Prevents re-entering [add] if it
  /// fires twice; the screen manages its own load state for the button.
  bool _saving = false;

  /// Records written here since the structure last counted them ([add] places them in the
  /// sheet before the backend's count says so).
  int _added = 0;

  /// What was written in the header search box, or empty if not searching. It
  /// travels in every records read (`MATCH`) and therefore **the backend does
  /// the filtering of the sheet**: it is not that the rows you have get hidden,
  /// it is that the ones requested already come filtered. It is the only way
  /// that works the same in a table of ten rows as in one of five hundred
  /// thousand, where what is in memory is a handful of chunks.
  String _query = "";

  /// How many rows match [query]. Each filtered page says it (`total`) and it
  /// is what measures the sheet while searching, instead of the records the
  /// table has.
  int _matches = 0;

  /// Which read is the current one. Changing the search throws away what was
  /// read and starts over, so a chunk already in transit would arrive with the
  /// rows of the previous search and be stored in the place of this one's: what
  /// was written is compared on return and the old chunk is discarded.
  int _generation = 0;

  /// How many records each chunk is read by. It is sent in the request instead
  /// of leaving the backend's default, so both ends count the rows the same:
  /// [TablePaging] translates a row to its page assuming every page is the same
  /// size.
  static const int _pageSize = 50;

  /// How many pages are kept at once. With [_pageSize] that is ten thousand
  /// rows in memory: far more than can be looked at, and a fixed ceiling even
  /// if the table has hundreds of thousands of records.
  static const int _maxCachedPages = 200;

  /// How long a normalization ([normalize]) is waited for.
  ///
  /// It is the only request of this screen that does not measure how long a
  /// query takes but how long a model takes reading the whole table: on one
  /// with many columns that is tens of seconds, and the deadline of any regular
  /// write —ten seconds— would count it as failed right when it is working.
  /// Cutting it off also does not cancel it: on the other side it keeps going
  /// and ends up writing, so giving up early only leaves the screen lying.
  static const Duration _normalizeTimeout = Duration(minutes: 3);

  TableStructureStatus get structureStatus => _structureStatus;
  TableStructureModel get structure => _structure;

  /// The table's columns. They come from the structure, not from the records:
  /// they are the same no matter which chunk is being looked at.
  List<TableFieldModel> get fields => _structure.fields;

  TableViewStatus get status => _status;

  /// `true` while some chunk is being fetched.
  bool get isLoadingRows => _paging.isReading;

  /// `true` while the structure of an already drawn table is being re-read.
  /// The top bar shows it: it is the only sign that the column change is still
  /// traveling, because the sheet does not move.
  bool get isReloading => _reloading;

  /// What is being searched, or empty if nothing is being searched.
  String get query => _query;

  /// `true` while the sheet is filtered by a search.
  bool get isSearching => _query.isNotEmpty;

  /// How many record rows the sheet has.
  ///
  /// The structure says it, so it is known before reading a single record: the
  /// sheet is born with its final length and the rows that have not arrived
  /// yet look empty until they come on screen. If the structure does not bring
  /// it, it falls back to the only thing that can be known —how far it was
  /// read— and the table grows as you scroll down.
  ///
  /// While searching it is the matching ones and not the ones the table has:
  /// the sheet measures what the search returned, which is what makes it
  /// scroll and request chunks over the result just like over the whole table.
  /// Until the first filtered page arrives it is zero, which is the only honest
  /// thing that can be said: how many match is known by the backend, not by the
  /// structure.
  int get records => isSearching
    ? _matches
    : _structure.records > 0 ? _structure.records + _added : _paging.known;

  /// The record of row [index], or `null` if that row has not been read yet.
  TableRowModel? rowAt(int index) => _rows[index];

  /// Makes sure the chunks covering the rows from [first] to [last] are
  /// requested.
  ///
  /// The sheet calls it when it scrolls, with the visible range plus a few more
  /// rows down: so the next chunk is requested before it is needed and the rows
  /// arrive already loaded instead of appearing blank.
  ///
  /// It walks page by page and not row by row: the visible range can be
  /// hundreds of rows and they all fall in two or three pages.
  ///
  /// The pages are requested outside the frame: this runs while drawing or
  /// scrolling, and notifying the load right there would repaint mid-build.
  void ensureRange(int first, int last) {
    if (_structureStatus != TableStructureStatus.ready) return;

    final from = math.max(0, first);
    if (last < from) return;

    // It is not known yet how many records are read at a time: the first page
    // is what reveals it, and until it arrives no other row can be translated.
    if (_paging.size <= 0) {
      _requestRow(0);
      return;
    }

    for (int index = from; index <= last; index += _paging.size) {
      _requestRow(index);
    }

    // The last row of the range may fall on a page that the previous step
    // jumped over.
    _requestRow(last);
  }

  void _requestRow(int index) {
    if (_rows.containsKey(index)) return;

    final page = _paging.request(index);
    if (page <= 0) return;

    scheduleMicrotask(() => _loadPage(page));
  }

  /// Opens a table: first its structure and, with it, the first chunk of
  /// records. It resets the state, because this service does not cache between
  /// tables: it lives and dies with the screen.
  ///
  /// [query] is whatever was in the header search box when opening it.
  /// Normally it is empty —the header is cleared when changing screens— but a
  /// table that mounts with something written has to open already filtered:
  /// otherwise the search box would say one thing and the sheet another.
  Future<void> open(String tableId, {String query = ""}) {
    _tableId = tableId;
    _structure = const TableStructureModel();
    _structureStatus = TableStructureStatus.idle;
    _reloading = false;
    _staleStructure = false;
    _rows.clear();
    // Another table, another page size: the bookkeeping starts from zero and
    // does not reuse the previous one.
    _paging = TablePaging();
    _status = TableViewStatus.idle;
    _query = query.trim();
    _matches = 0;
    _generation++;

    return _load();
  }

  /// Searches [query] in the table: the sheet goes on to show only the rows
  /// that mention it, in any of their columns.
  ///
  /// The screen calls it with what was written in the header search box, which
  /// is a single one for the whole home and searches over the section being
  /// looked at (see `HomeService.searchQuery`). Clearing the search box goes
  /// back to the whole table, which is the empty search.
  ///
  /// **The backend filters, not the sheet.** From a table of hundreds of
  /// thousands of rows there are only a few chunks in memory, so hiding the
  /// ones that do not match would search in what was looked at and not in the
  /// table: what is sent is the text (`MATCH`) and what comes back is the
  /// matching rows, counted and paged like any other read. That is why
  /// searching throws away what was read and starts over from the first row:
  /// the previous ones were from another sheet.
  ///
  /// With the table still not drawn nothing is requested: the read already in
  /// progress requests its first chunk when the structure finishes, and by then
  /// this has already written down with what text to request it.
  Future<void> search(String query) {
    final next = query.trim();
    if (next == _query) return Future.value();

    _query = next;
    _matches = 0;
    _generation++;
    _reset();
    notifyListeners();

    if (_structureStatus != TableStructureStatus.ready) return Future.value();

    final page = _paging.request(0);
    return page > 0 ? _loadPage(page) : Future.value();
  }

  /// Retries what failed. If the structure failed to arrive, it is requested
  /// whole again; if a chunk of records failed, repainting is enough: the sheet
  /// requests the visible rows by itself and the one that did not arrive is
  /// requested again there.
  ///
  /// A stale structure ([_staleStructure]) counts as a structure that failed to
  /// arrive, even if one is drawn: the column change that left it that way did
  /// go through, and without re-requesting it the sheet never shows it.
  Future<void> retry() {
    if (_structureStatus != TableStructureStatus.ready || _staleStructure) {
      return _load();
    }

    _paging.retry();
    _status = _rows.isEmpty ? TableViewStatus.idle : TableViewStatus.ready;
    notifyListeners();

    return Future.value();
  }

  /// Creates an item (a row) against `POST /inventory/products/records/manage/`.
  ///
  /// [values] are the captured data, indexed by FIELD_ID: they go in the `DATA`
  /// field of the body, next to the `TABLE_ID` of the open table (which the
  /// screen does not have to pass, the service puts it). The owner company
  /// travels in the `business_id` header, like in the rest of the APIs.
  ///
  /// Returns `true` if the creation went well. **The sheet does not blink for it**: with
  /// [row] (the values by slot) and the id the backend answers, the record is placed behind
  /// the last one at once, writable, and only its page is read again in place, so what the
  /// backend filled (a counter, the stock) arrives over a row already drawn. Without an id
  /// (or while searching, where the new row is not of the result) the table is re-read
  /// whole, which empties what was read.
  ///
  /// On error it shows the floating flag and returns `false`, leaving the draft
  /// intact to retry.
  Future<bool> add(
    BuildContext context,
    Map<String, dynamic> values, {
    List<dynamic>? row
  }) async {
    if (_saving) return false;

    final tableId = _tableId;
    if (tableId == null) return false;

    _saving = true;
    notifyListeners();

    try {
      final id = await _source.createRecord(createRecordRequest(tableId: tableId, values: values));

      _saving = false;

      if (row == null || id.isEmpty || isSearching) {
        await refresh();
        return true;
      }

      final index = records;

      _rows[index] = TableRowModel(row, id: id);
      if (_structure.records > 0) _added++;
      _paging.grow(index + 1);
      if (_status == TableViewStatus.empty || _status == TableViewStatus.idle) _status = TableViewStatus.ready;
      notifyListeners();

      unawaited(_rereadPage(_paging.pageOf(index)));

      return true;
    } catch (error) {
      if (kDebugMode) print("addProduct failed: $error");

      _saving = false;
      notifyListeners();

      if (!context.mounted) return false;

      // An `action` is a navigation instruction (expired session, etc.): it is
      // rethrown as is so whoever is responsible handles it.
      if (error is Map && error["action"] != null) throw error["action"];

      FloatFlag.of(context).fromError(
        error is Map && error.isNotEmpty ? error : {"message": error.toString()}
      );
      return false;
    }
  }

  /// Edits a cell of a record against `PUT /inventory/products/records/manage/`.
  ///
  /// This is what makes the sheet writable in full and not only in the bottom
  /// rows: you touch a cell of an already saved row, write and on exit the
  /// change travels. It goes cell by cell ([slot] is the field within the row
  /// and [fieldId] its FIELD_ID, the key it is stored under) because that is
  /// what was edited: sending the whole row would rewrite fields nobody looked
  /// at.
  ///
  /// **The change is seen instantly and travels behind**, like the column
  /// order: the cell shows what was just written without waiting for the
  /// backend and without re-reading the table, which at this scale is the
  /// difference between fixing a price and reloading the table. If it does not
  /// go through, the row goes back to the value it had and the error is shown
  /// in the floating flag.
  ///
  /// Returns `false` if there was no record to write to: the row has not been
  /// read yet, came without an id, or the field has no FIELD_ID.
  Future<bool> editRecord(
    BuildContext context, {
    required int row,
    required int slot,
    required String fieldId,
    required String value
  }) async {
    final tableId = _tableId;
    final record = _rows[row];

    if (tableId == null || record == null) return false;
    if (record.id.isEmpty || fieldId.isEmpty || slot < 0) return false;

    final before = record.at(slot);

    _rows[row] = record.withValue(slot, value);
    notifyListeners();

    try {
      await _source.editRecord(editRecordRequest(
        tableId: tableId,
        id: record.id,
        values: {fieldId: value}
      ));

      return true;
    } catch (error) {
      if (kDebugMode) print("editRecord failed: $error");

      _restore(row, record.id, slot, before);

      if (!context.mounted) return false;

      // An `action` is a navigation instruction (expired session, etc.): it is
      // rethrown as is so whoever is responsible handles it.
      if (error is Map && error["action"] != null) throw error["action"];

      FloatFlag.of(context).fromError(
        error is Map && error.isNotEmpty ? error : {"message": error.toString()}
      );
      return false;
    }
  }

  /// Writes [productId]'s stock as a movement left it (its `available`) in its row's `STOCK`
  /// cells, without re-reading: the inventory engine answered the balance.
  void writeStock(String productId, num available) {
    final stock = [
      for (final (slot, field) in fields.indexed)
        if (TableFieldType.from(field.type) == TableFieldType.stock) slot
    ];
    if (stock.isEmpty) return;

    for (final entry in _rows.entries) {
      if (entry.value.id != productId) continue;

      var row = entry.value;
      for (final slot in stock) {
        row = row.withValue(slot, available);
      }
      _rows[entry.key] = row;
    }

    notifyListeners();
  }

  /// Returns a cell to the value it had, after an edit that did not go through.
  ///
  /// While the change was traveling the table could have been re-read, or that
  /// chunk forgotten and re-requested: it is checked that the same record is
  /// still in that row before touching it, because writing to the current one
  /// would overwrite good data with old data.
  void _restore(int row, String id, int slot, dynamic value) {
    final current = _rows[row];
    if (current == null || current.id != id) return;

    _rows[row] = current.withValue(slot, value);
    notifyListeners();
  }

  /// Adds a photo to a product against `POST /inventory/products/records/images/`.
  ///
  /// The photo travels as multipart in the `FILE` field, with the table and the
  /// record next to it, and the backend does everything else: it re-encodes it
  /// to WebP, resizes it, renders the thumbnail that draws a cell and strips
  /// the metadata. What is uploaded is never the bytes that were picked.
  ///
  /// **It is not optimistic**, the opposite of [editRecord]: until the backend
  /// answers there is no id to put in the cell, so there is nothing to show
  /// ahead of time. What is seen meanwhile is the cell's loading, which the
  /// sheet carries ([SheetController.uploading]).
  ///
  /// The cell keeps the gallery the response returns and not the id that just
  /// came in: a product can have several photos and the first one is the cover,
  /// so who decides the order —and which is the cover— is the backend.
  ///
  /// Returns `false` if there was no record to upload it to (the row has not
  /// been read yet or came without an id) or if the upload did not go through,
  /// and in that case the error is shown in the floating flag.
  Future<bool> addImage(
    BuildContext context, {
    required int row,
    required int slot,
    required File file
  }) async {
    final tableId = _tableId;
    final record = _rows[row];

    if (tableId == null || record == null) return false;
    if (record.id.isEmpty || slot < 0) return false;

    try {
      _writeImages(row, record.id, slot, await _source.addImage(tableId, record.id, file));

      return true;
    } catch (error) {
      if (kDebugMode) print("addImage failed: $error");

      if (!context.mounted) return false;

      if (error is Map && error["action"] != null) throw error["action"];

      FloatFlag.of(context).fromError(
        error is Map && error.isNotEmpty ? error : {"message": error.toString()}
      );
      return false;
    }
  }

  /// Removes a photo from a product against
  /// `DELETE /inventory/products/records/images/<table>/<product>/<file>`.
  ///
  /// **The cell empties instantly and the delete travels behind**, like any
  /// edit: the photo is taken out of the gallery already on screen and, if the
  /// delete does not go through, the row goes back to the one it had.
  ///
  /// Only what this platform stores is deleted this way. An address that came
  /// in an import is company data and not one of our files: that one is deleted
  /// the way any cell value is deleted ([editRecord]).
  ///
  /// The backend deletes the bytes only when no other product shows them, and
  /// removing a photo the product does not have is the same to it: it is what
  /// was asked, and it already is that way.
  Future<bool> removeImage(
    BuildContext context, {
    required int row,
    required int slot,
    required String fileId
  }) async {
    final tableId = _tableId;
    final record = _rows[row];

    if (tableId == null || record == null) return false;
    if (record.id.isEmpty || slot < 0 || fileId.isEmpty) return false;

    final before = record.at(slot);
    final left = [
      for (final image in ProductImage.from(before))
        if (image.id != fileId) image
    ];

    _rows[row] = record.withValue(slot, ProductImage.valuesOf(left));
    notifyListeners();

    try {
      await _source.removeImage(tableId, record.id, fileId);

      return true;
    } catch (error) {
      if (kDebugMode) print("removeImage failed: $error");

      _restore(row, record.id, slot, before);

      if (!context.mounted) return false;

      if (error is Map && error["action"] != null) throw error["action"];

      FloatFlag.of(context).fromError(
        error is Map && error.isNotEmpty ? error : {"message": error.toString()}
      );
      return false;
    }
  }

  /// Leaves in the cell the gallery the backend returned.
  ///
  /// It is checked that the same record is still in that row, for the same
  /// reason as in [_restore]: an upload takes time, and meanwhile the table
  /// could have been re-read or that chunk re-requested.
  void _writeImages(int row, String id, int slot, List<ProductImage> images) {
    final current = _rows[row];
    if (current == null || current.id != id) return;

    _rows[row] = current.withValue(
      slot,
      ProductImage.valuesOf(images)
    );
    notifyListeners();
  }

  /// Re-reads the table after **adding a record**: the structure (the one that
  /// knows how many there are) and, with it, the chunks being viewed. What had
  /// already been read is discarded from the start, because a new record moves
  /// every one that goes behind it.
  Future<void> refresh() {
    _reset();
    return _load();
  }

  /// Re-reads the table after **a column change**.
  ///
  /// Unlike [refresh] it discards nothing in advance: the records are the same
  /// and stay in the same place, so what decides what to do with what was read
  /// is the structure that arrives. Adding a column or renaming it does not
  /// touch it ([fieldsGrewAtEnd]); deleting one, or the fields coming back in
  /// another order, only moves it ([fieldsRemap]). Re-requesting the pages is
  /// the last resort.
  Future<void> _reloadFields() => _load();

  /// The backend finished preparing a table. If it is the open one, it is
  /// re-read.
  ///
  /// How much is thrown away depends on whether the **values** changed and not
  /// the columns: when retyping a column the backend rewrites what was already
  /// stored in it (`Products.recast`), so the records in memory became stale
  /// even if the fields are the same and have to be requested again. If it
  /// retyped nothing —the table only gained its image column— the cheap
  /// re-read is enough, which keeps the pages already read.
  ///
  /// With the table still not drawn nothing is done: there is a read in
  /// progress or about to go out, and that one will bring the new structure.
  void _onReady(dynamic data) {
    if (_structureStatus != TableStructureStatus.ready) return;

    final report = TableReadyModel.fromEvent(data);
    if (report.isEmpty || report.id != _tableId) return;

    if (report.changedValues) {
      refresh();
    } else {
      _reloadFields();
    }
  }

  /// Pictures an import named became files of ours on some rows of [tables]
  /// (`PictureProgress`). If this table is one of them, the pages in view are read again
  /// **in place**: the rows stay drawn until their new values arrive, so the cells swap a
  /// pending name or address for the stored photo without the sheet blinking.
  void _onPictures(dynamic data) {
    if (_structureStatus != TableStructureStatus.ready || _tableId == null) return;
    if (!PictureProgress.fromJson(data).tables.contains(_tableId)) return;

    _picturesTimer ??= Timer(_picturesGather, () {
      _picturesTimer = null;
      unawaited(_rereadPages());
    });
  }

  /// Reads [page] again in place: its rows stay drawn until the answer replaces them.
  Future<void> _rereadPage(int page) async {
    if (page <= 0) return;

    _paging.forget(page);
    if (_paging.request(_paging.startOf(page)) == page) await _loadPage(page);
  }

  /// Reads again every page in the cache, keeping what it holds until the answer replaces it.
  Future<void> _rereadPages() async {
    for (final page in List<int>.from(_cached)) {
      _paging.forget(page);

      if (_paging.request(_paging.startOf(page)) == page) await _loadPage(page);
    }
  }

  @override
  void dispose() {
    _unlisten?.call();
    _unlisten = null;
    _unlistenPictures?.call();
    _unlistenPictures = null;
    _picturesTimer?.cancel();
    _picturesTimer = null;
    super.dispose();
  }

  /// Creates a column (field) against `POST /inventory/products/builder/fields/`.
  ///
  /// It is a modification of the open table's structure, not of its data: the
  /// field is added at the end ([fields] gives the [POSITION]) and the table
  /// does not have to pass it, the service puts it next to the `TABLE_ID`. The
  /// rest (name, description, type) comes from the sheet.
  ///
  /// Returns `true` if the creation went well; in that case it re-reads the
  /// structure —the one that just changed— and with it the records, which now
  /// have one more cell. On error it shows the floating flag and returns
  /// `false`.
  Future<bool> addField(
    BuildContext context, {
    required String name,
    required String description,
    required String type
  }) async {
    final tableId = _tableId;
    if (tableId == null) return false;

    try {
      await _source.createField(createFieldRequest(
        tableId: tableId,
        name: name,
        description: description,
        type: type,
        // The new column goes at the end: its position is the current count.
        position: _structure.fields.length
      ));

      await _reloadFields();
      return true;
    } catch (error) {
      if (kDebugMode) print("addField failed: $error");

      if (!context.mounted) return false;

      // An `action` is a navigation instruction (expired session, etc.): it is
      // rethrown as is so whoever is responsible handles it.
      if (error is Map && error["action"] != null) throw error["action"];

      FloatFlag.of(context).fromError(
        error is Map && error.isNotEmpty ? error : {"message": error.toString()}
      );
      return false;
    }
  }

  /// Edits a column against `PUT /inventory/products/builder/fields/`: its name, its type,
  /// the options of its list, or all three.
  ///
  /// This is what the field cell and its arrow do: the column is born as
  /// `TEXT` with the title that was written to it —that is all that is needed
  /// to create it— and afterwards it is corrected right there, with no forms in
  /// between. Creating an option in a list cell's dropdown goes the same way:
  /// an option is a property of the field, so it is saved by sending the list
  /// that must remain ([options]).
  ///
  /// Only what changes travels; the name always goes because the backend asks
  /// for it, so changing only the type sends the one the field already had.
  /// What is not sent (description, position) stays as it was. Returns `true`
  /// if the change went well, and in that case it re-reads the structure —the
  /// one that just changed— and with it the records, which now are read and
  /// aligned against the new type.
  Future<bool> editField(
    BuildContext context,
    TableFieldModel field, {
    String? name,
    String? type,
    List<String>? options
  }) async {
    // Without a FIELD_ID there is no field to edit: it is a column that was
    // seen but that the backend did not identify.
    if (field.id.isEmpty) return false;

    try {
      await _source.editField(editFieldRequest(
        id: field.id,
        name: name ?? field.name,
        type: type,
        options: options
      ));

      await _reloadFields();
      return true;
    } catch (error) {
      if (kDebugMode) print("editField failed: $error");

      if (!context.mounted) return false;

      // An `action` is a navigation instruction (expired session, etc.): it is
      // rethrown as is so whoever is responsible handles it.
      if (error is Map && error["action"] != null) throw error["action"];

      FloatFlag.of(context).fromError(
        error is Map && error.isNotEmpty ? error : {"message": error.toString()}
      );
      return false;
    }
  }

  /// Saves the order of the columns against `PUT /inventory/products/builder/fields/`.
  ///
  /// [ordered] are the fields as they must remain, and each one's position is
  /// its place in that list.
  ///
  /// The one for **all** of them is sent and not only for the ones that moved,
  /// because the backend does not rearrange the neighbors: it stores the
  /// position it is given and then sorts by it, so renumbering only a stretch
  /// would leave repeated positions and the order would end up depending on how
  /// the database returns them. It is as many requests as columns —a few dozen
  /// at most—, they all go together and only on releasing a column, which is
  /// not something done often.
  ///
  /// **It does not re-read the structure**, and that is what makes dragging a
  /// column free: the sheet already shows the new order (it applied it on
  /// release, waiting for nobody) and re-reading it would only bring the same
  /// fields in the same order, discarding along the way the pages being looked
  /// at. What was just saved is only noticed the next time the table is opened,
  /// which is exactly when it matters.
  ///
  /// Returns `true` if all of them went through. If one fails, the sheet goes
  /// back to the previous order ([SheetColumns.restoreOrder]) and some position
  /// may be half-written on the other side: the next drag that goes well
  /// renumbers them all again and evens them out.
  Future<bool> reorderFields(
    BuildContext context,
    List<TableFieldModel> ordered
  ) async {
    if (ordered.length < 2) return true;

    try {
      await Future.wait([
        for (final (position, field) in ordered.indexed)
          if (field.id.isNotEmpty)
            _source.editField(editFieldRequest(
              id: field.id,
              name: field.name,
              position: position
            ))
      ]);

      return true;
    } catch (error) {
      if (kDebugMode) print("reorderFields failed: $error");

      if (!context.mounted) return false;

      if (error is Map && error["action"] != null) throw error["action"];

      FloatFlag.of(context).fromError(
        error is Map && error.isNotEmpty ? error : {"message": error.toString()}
      );
      return false;
    }
  }

  /// Saves a column's width against `PUT /inventory/products/builder/fields/`.
  ///
  /// The width is a property **of the table**, not of whoever looks at it: it
  /// is stored with the field and the structure brings it, so the table opens
  /// the same for everyone in the company. It travels on releasing the edge and
  /// not while dragging —a drag is dozens of events per second— and it is sent
  /// whole, in logical pixels: the fraction a drag leaves means nothing on the
  /// other side.
  ///
  /// **It does not re-read the structure**, for the same reason as the column
  /// order ([reorderFields]): the sheet already shows the new width and
  /// re-reading would only bring the same fields, discarding along the way the
  /// pages being looked at.
  ///
  /// Returns `true` if it went through. If not, whoever called it returns the
  /// column to the width it had; the error was already shown by the floating
  /// flag.
  Future<bool> resizeField(
    BuildContext context,
    TableFieldModel field, {
    required double width
  }) async {
    if (field.id.isEmpty || width <= 0) return false;

    try {
      await _source.editField(editFieldRequest(
        id: field.id,
        name: field.name,
        width: width.round()
      ));

      return true;
    } catch (error) {
      if (kDebugMode) print("resizeField failed: $error");

      if (!context.mounted) return false;

      // An `action` is a navigation instruction (expired session, etc.): it is
      // rethrown as is so whoever is responsible handles it.
      if (error is Map && error["action"] != null) throw error["action"];

      FloatFlag.of(context).fromError(
        error is Map && error.isNotEmpty ? error : {"message": error.toString()}
      );
      return false;
    }
  }

  /// Deletes a column against `DELETE /inventory/products/builder/fields/`.
  ///
  /// It takes the column and everything loaded in it, so whoever calls it must
  /// have confirmed it before: the service does not ask.
  ///
  /// Returns `true` if the delete went well, and in that case it re-reads the
  /// structure —there is one column less— and with it the records, which now
  /// have one cell less.
  Future<bool> deleteField(BuildContext context, TableFieldModel field) async {
    if (field.id.isEmpty) return false;

    try {
      await _source.deleteField(field.id);

      await _reloadFields();
      return true;
    } catch (error) {
      if (kDebugMode) print("deleteField failed: $error");

      if (!context.mounted) return false;

      if (error is Map && error["action"] != null) throw error["action"];

      FloatFlag.of(context).fromError(
        error is Map && error.isNotEmpty ? error : {"message": error.toString()}
      );
      return false;
    }
  }

  /// Normalizes the table against `POST /inventory/products/builder/normalize/`: it gives each column
  /// the type that fits what it has stored and seeds how much of it the agent
  /// sees.
  ///
  /// It is the same pass that runs by itself at the end of an import, requested
  /// by hand. It serves the tables that did not have it —the ones built by
  /// hand, column by column, or the ones imported with normalization off— and
  /// to look again at one whose data changed since then.
  ///
  /// **It only reviews the columns nobody touched**, so repeating it does not
  /// undo a type or a visibility chosen by hand. That is why the service asks
  /// nothing: there is nothing to lose that the user wrote.
  ///
  /// It has its own deadline and not the one of a regular write: on the other
  /// side a sample of each column is read and a model is asked what it means,
  /// and that takes what a model takes, not what an `UPDATE` takes.
  ///
  /// When it returns the table must be re-read, and how much is thrown away
  /// depends on whether the **values** were rewritten: retyping a column
  /// rewrites what was already stored in it (`Products.recast`), so the records
  /// in memory became stale even if the columns are the same. It is the same
  /// split the `table/ready` notice does ([_onReady]) —and for the same
  /// reason—: this route does not emit it, because it answers when it already
  /// finished.
  ///
  /// Returns what changed, or `null` if it did not go through; in that case the
  /// error was already shown in the floating flag and the table stays as it
  /// was.
  Future<TableNormalizeModel?> normalize(BuildContext context) async {
    final tableId = _tableId;
    if (tableId == null) return null;

    try {
      final report = await _source.normalize(tableId, timeout: _normalizeTimeout);

      if (report.changedValues) {
        await refresh();
      } else {
        await _reloadFields();
      }

      return report;
    } catch (error) {
      if (kDebugMode) print("normalize failed: $error");

      if (!context.mounted) return null;

      // An `action` is a navigation instruction (expired session, etc.): it is
      // rethrown as is so whoever is responsible handles it.
      if (error is Map && error["action"] != null) throw error["action"];

      FloatFlag.of(context).fromError(
        error is Map && error.isNotEmpty ? error : {"message": error.toString()}
      );
      return null;
    }
  }

  /// Forgets the records read, without touching the structure or the page size,
  /// which do not change.
  void _reset() {
    _rows.clear();
    _cached.clear();
    _paging.reset();
    _status = TableViewStatus.idle;
  }

  /// Keeps the cache within budget.
  void _trimCache(int around) {
    while (true) {
      final page = pageToForget(
        _cached,
        around: around,
        budget: _maxCachedPages
      );
      if (page == null) return;

      _cached.remove(page);
      _forget(page);
    }
  }

  /// Forgets a page: its rows and the read mark, so it can be requested again if
  /// you go back to it.
  void _forget(int page) {
    final start = _paging.startOf(page);

    for (int offset = 0; offset < _paging.size; offset++) {
      _rows.remove(start + offset);
    }

    _paging.forget(page);
  }

  /// The two phases, in order: the structure and, if it came, the first chunk
  /// of records. This is what runs on opening the table, on retry and after
  /// everything that changes it.
  Future<void> _load() async {
    if (!await _loadStructure()) return;

    // The first chunk is requested the same way as the rest: row 0 is always
    // on page 1, which is also the one that reveals how many records are read
    // at a time.
    final page = _paging.request(0);
    if (page > 0) await _loadPage(page);
  }

  /// First phase: the table's structure.
  ///
  /// Returns `true` if it ended up loaded and the records can be continued
  /// with. A structure that fails to arrive leaves the screen in error: without
  /// columns there is nothing to draw, not even the fields row.
  ///
  /// **An already drawn table never goes back to a blank screen.** Re-reading
  /// the structure —adding a column, changing its type, deleting it, saving a
  /// row— happens with the sheet mounted and the user looking at whatever row:
  /// going through [TableStructureStatus.loading] would unmount the grid, and
  /// with it the scroll position (you would have to scroll back down to where
  /// you were) and the cell that was being written. That is why a re-read is
  /// flagged separately ([isReloading]), in the top bar, and the state stays at
  /// `ready` the whole way through.
  Future<bool> _loadStructure() async {
    if (_reading) return false;

    final tableId = _tableId;
    if (tableId == null) return false;

    // The table is already drawn: this is a re-read, not a load.
    final reload = _structureStatus == TableStructureStatus.ready;

    _reading = true;
    _reloading = reload;
    if (!reload) _structureStatus = TableStructureStatus.loading;
    notifyListeners();

    final structure = await _source.structure(tableId).then<TableStructureModel?>((structure) => structure).catchError((error) {
      if (kDebugMode) print("loadTableStructure failed: $error");
      return null;
    });

    _reading = false;
    _reloading = false;

    if (structure == null) {
      // A re-read that fails keeps what was there: the old structure is still the
      // table's and throwing it away would leave the screen in error over a
      // column change that never went through. The notice goes up top, like the
      // one for a chunk that did not arrive.
      if (reload) {
        _staleStructure = true;
        _status = TableViewStatus.error;
      } else {
        _structureStatus = TableStructureStatus.error;
      }

      notifyListeners();
      return false;
    }

    final before = [for (final field in _structure.fields) field.id];

    _structure = structure;
    _structureStatus = TableStructureStatus.ready;
    _added = 0;

    // The error a previous re-read that had not arrived set is lifted: this one
    // did arrive, so the structure is no longer stale.
    if (_staleStructure) {
      _staleStructure = false;
      _status = _rows.isEmpty ? TableViewStatus.idle : TableViewStatus.ready;
    }

    // What was read still works as is if the previous fields are where they were,
    // which is what happens on renaming a column or adding one: nothing is
    // touched and whatever pages you have are kept, which at this scale is the
    // difference between adding a column and scrolling down the whole table
    // again.
    //
    // If they moved —the order just saved, a column that is no longer there—
    // the rows still have the same values, only in another place: they are
    // rearranged in a single pass and the pages are saved all the same.
    // Re-requesting them is the last resort, for when there is no FIELD_ID to
    // pair the two lists with.
    final after = [for (final field in _structure.fields) field.id];

    if (!fieldsGrewAtEnd(before, after)) {
      final remap = fieldsRemap(before, after);

      if (remap == null) {
        _reset();
      } else {
        _remapRows(remap);
      }
    }

    notifyListeners();

    return true;
  }

  /// Rearranges the records read to the current fields, with the map that
  /// [fieldsRemap] returns.
  ///
  /// It is a pass over what is in memory, not over the table: at most it is the
  /// [_maxCachedPages] pages of the budget, and it only runs when the fields
  /// changed place.
  void _remapRows(List<int> remap) {
    for (final index in _rows.keys.toList(growable: false)) {
      final row = _rows[index]!;

      _rows[index] = TableRowModel(
        [for (final position in remap) position < 0 ? null : row.at(position)],
        // The record is still the same one: what moved are its columns.
        id: row.id
      );
    }
  }

  /// Second phase: a chunk of records (`POST /inventory/products/records/list/`).
  ///
  /// From the body that search accepts, the minimum is sent here: the table,
  /// which page, how many rows each and —if searching— the text that was
  /// written (`MATCH`). No `WHERE` or `SORT`, which are per-column conditions:
  /// the sheet does not have them, it shows the table in the order the backend
  /// returns it.
  ///
  /// `MATCH` changes nothing about how it reads: the search is paged and
  /// counted like the whole table, only over the matching rows. That is why
  /// searching a table of five hundred thousand rows costs the same as opening
  /// it, and there is never a moment when the sheet has to hold everything.
  ///
  /// Each page is stored in its place within the table, not at the end of
  /// whatever is there: the row at index 900 is the same whether it was reached
  /// by scrolling or in one jump.
  ///
  /// The rows are reordered against the structure ([TableViewModel.alignedTo]):
  /// the columns were already fixed by the first phase, and from here only the
  /// values come out.
  Future<void> _loadPage(int page) async {
    final tableId = _tableId;

    if (tableId == null) {
      _paging.failed(page);
      return;
    }

    // Which search this chunk goes out with. If it changes while in transit,
    // what comes back is no longer of this sheet.
    final generation = _generation;

    _status = TableViewStatus.loading;
    notifyListeners();

    final data = await _source
        .records(tableId, page: page, size: _pageSize, match: _query)
        .then<({TableViewModel page, int? total})?>((data) => data)
        .catchError((error) {
      if (kDebugMode) print("loadTableRecords failed: $error");
      return null;
    });

    // Something else was searched while this was in transit: these rows are from
    // the previous search and their indexes from a sheet that no longer exists.
    // Even the failure is not recorded: that bookkeeping was thrown away too.
    if (generation != _generation) return;

    if (data == null) {
      _paging.failed(page);
      _status = TableViewStatus.error;
      notifyListeners();
      return;
    }

    final rows = data.page
      .alignedTo(_structure.fields)
      .rows;

    // The chunk is stored in its place within the table, not at the end of
    // whatever is there: the page says where it starts.
    final start = _paging.read(page, rows.length, asked: _pageSize);
    for (final (offset, row) in rows.indexed) {
      _rows[start + offset] = row;
    }

    // How many match is said by the response, and it is what measures the
    // sheet while searching. If it does not come, what remains is the only
    // thing that can be known —how far it was read— and the search grows as
    // you scroll down, like a table whose structure does not say how many
    // records it has.
    if (isSearching) {
      _matches = data.total ?? _paging.known;
    }

    _cached.remove(page);
    _cached.add(page);
    _trimCache(page);

    _status = _rows.isEmpty ? TableViewStatus.empty : TableViewStatus.ready;
    notifyListeners();
  }
}

/// Whether the structure that just arrived is the previous one with, at most,
/// new fields **at the end**.
///
/// This is what decides if the records already read are still useful. A saved
/// row is a list of values aligned to the structure's fields (see
/// `TableViewModel.alignedTo`), so:
///
/// - Renaming a column or changing its type moves no value: the FIELD_IDs are
///   the same and in the same order.
/// - Adding a column at the end only leaves the rows short, and that cell shows
///   empty, which is exactly what fits a newly created field.
/// - Deleting a column, or the backend returning the fields in another order,
///   moves every value: then what was read can no longer be shown and has to be
///   requested again.
///
/// It matters from a few thousand records on: without this, touching a column
/// title throws away the pages being looked at and forces scrolling down the
/// table again.
bool fieldsGrewAtEnd(List<String> before, List<String> after) {
  if (after.length < before.length) return false;

  for (int index = 0; index < before.length; index++) {
    if (before[index] != after[index]) return false;
  }

  return true;
}

/// Which old position each new column comes from, to rearrange the records
/// already read instead of requesting them again.
///
/// It's the rescue of what [fieldsGrewAtEnd] discards. A saved row is a list
/// of values aligned to the fields as they were then (see
/// [TableViewModel.alignedTo]), so moving a column —or deleting it— **does
/// not invalidate what was read**: the values are still there and the only
/// thing that changed is where they're looked up. Returning that map is
/// enough to leave the rows as if they'd been requested with the new
/// structure.
///
/// A column that wasn't there before stays at `-1`, read as an empty cell:
/// that's the right behavior for a just-created field, where nothing is
/// loaded yet.
///
/// Returns `null` when the two lists can't be matched and it has to be
/// re-read: without a FIELD_ID there's nothing to match with, and with
/// repeated ids there'd be no telling which is which. Also when there were no
/// fields, because then the rows already read aren't aligned to any.
///
/// Matters starting at a few thousand records: without this, dragging a
/// column to a new place (or deleting it) would throw away the pages that
/// were being looked at and force the table to be fetched again.
List<int>? fieldsRemap(List<String> before, List<String> after) {
  if (before.isEmpty) return null;

  final position = <String, int>{};

  for (final (index, id) in before.indexed) {
    if (id.isEmpty) return null;
    if (position.containsKey(id)) return null;

    position[id] = index;
  }

  return [
    for (final id in after) id.isEmpty ? -1 : position[id] ?? -1
  ];
}

/// Which of the saved pages has to be dropped, or `null` if they still fit
/// the budget.
///
/// **The one farthest** from [around], the one just read, is dropped, and not
/// the oldest one: that's how a table is scrolled through —down, a bit back
/// up, down again— and what's around where you're standing is what's most
/// likely to be needed again. Dropping by age would throw away the page right
/// above every time one scrolls down.
///
/// It lives apart from the service because it's the cache's rule and has
/// nothing to do with the network: it's tested on its own.
int? pageToForget(
  Iterable<int> cached, {
  required int around,
  required int budget
}) {
  if (cached.length <= budget) return null;

  int? farthest;
  int distance = -1;

  for (final page in cached) {
    final other = (page - around).abs();
    if (other <= distance) continue;

    distance = other;
    farthest = page;
  }

  return farthest;
}

/// The bookkeeping of a table's chunked reading: how many records a page
/// holds, which pages were read, which are in flight, which failed, and
/// where the table ends.
///
/// It lives apart from the service because it's the rule of infinite scroll
/// and has nothing to do with the network: it's tested on its own.
class TablePaging {
  /// How many records a page holds. Not known ahead of time: the first one
  /// to arrive says so, and that's how any row is translated to its page.
  int _size = 0;

  /// Pages read, in flight, and failed.
  final Set<int> _read = {};
  final Set<int> _flight = {};
  final Set<int> _failed = {};

  /// Up to which row was read. Only matters when the structure doesn't say
  /// how many records there are: there the table grows as it's read.
  int _known = 0;

  /// `true` when a page came back short or empty: there are no more records
  /// below it.
  bool _end = false;

  int get size => _size;
  int get known => _known;
  bool get atEnd => _end;

  /// `true` while any chunk is in flight.
  bool get isReading => _flight.isNotEmpty;

  /// Which page has to be requested to have row [index], or `0` if there's
  /// nothing to request: because it was already read, because it's already
  /// in flight, because it failed and doesn't retry on its own, or because
  /// that row is past the end of the table.
  ///
  /// Requesting it marks it as in flight, so the same page doesn't go out
  /// twice even if it's requested by all fifty rows being painted. Whoever
  /// requests it commits to closing it with [read] or with [failed].
  int request(int index) {
    if (index < 0) return 0;

    // Past the end there's nothing to request: those rows are the ones being
    // written.
    if (_end && index >= _known) return 0;

    final page = pageOf(index);
    if (page <= 0) return 0;
    if (_read.contains(page)) return 0;
    if (_flight.contains(page) || _failed.contains(page)) return 0;

    _flight.add(page);
    return page;
  }

  /// Which page row [index] falls on. Returns `0` while it isn't known how
  /// many records a page holds, except for the first row, which is always on
  /// page 1: it's the one that reveals it.
  int pageOf(int index) {
    if (_size > 0) return index ~/ _size + 1;
    return index == 0 ? 1 : 0;
  }

  /// First row of page [page].
  int startOf(int page) => _size > 0 ? (page - 1) * _size : 0;

  /// Records that page [page] arrived with [rows] records, and returns the
  /// index of its first row.
  ///
  /// A short —or empty— page is the end of the table: there's nothing more
  /// to request below it.
  ///
  /// A short first page says nothing about the size: with [asked] (what the request sent)
  /// the size is that, so a row created behind a small table's last one still falls on
  /// page 1, which is where the backend puts it.
  int read(int page, int rows, {int? asked}) {
    _flight.remove(page);
    _failed.remove(page);
    _read.add(page);

    if (_size == 0 && rows > 0) _size = asked != null && rows < asked ? asked : rows;
    if (rows == 0 || rows < _size) _end = true;

    final start = startOf(page);
    _known = math.max(_known, start + rows);

    return start;
  }

  /// Records that page [page] couldn't be fetched.
  ///
  /// It doesn't retry on its own: the sheet requests the rows visible on
  /// every repaint and the error triggers one, so without this a failing page
  /// would be requested in a loop. It's retried when the user asks for it
  /// ([retry]).
  void failed(int page) {
    _flight.remove(page);
    _failed.add(page);
  }

  /// Forgets the failures so the missing pages get requested again.
  void retry() => _failed.clear();

  /// The table reached [rows] records here (one was just created): the rows up to it are
  /// read, not past the end.
  void grow(int rows) => _known = math.max(_known, rows);

  /// Forgets that page [page] was read, so it can be requested again.
  ///
  /// Used by the bounded cache when dropping a distant page: without this the
  /// page would stay marked as read and its rows, already deleted, would
  /// never come back. Doesn't touch [_size] or [_end]: how many records a
  /// page holds and where the table ends don't change because a chunk was
  /// forgotten.
  void forget(int page) {
    _read.remove(page);
    _failed.remove(page);
  }

  /// Forgets what was read, not how many records a page holds: rereading the
  /// table doesn't change the page size.
  void reset() {
    _read.clear();
    _flight.clear();
    _failed.clear();
    _known = 0;
    _end = false;
  }
}
