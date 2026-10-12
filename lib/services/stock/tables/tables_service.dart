import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;

import 'package:app/services/connection/connection_service.dart';
import 'package:app/services/inventory/import_file.dart';
import 'package:app/services/inventory/picture_import_service.dart';
import 'package:app/services/inventory/table_request.dart';
import 'package:app/services/stock/tables/table_lite_model.dart';
import 'package:app/services/stock/tables/table_normalizing_model.dart';
import 'package:app/services/stock/tables/table_ready_model.dart';
import 'package:app/services/stock/sources/inventory_source.dart';
import 'package:app/toolkit/api.dart';
import 'package:app/toolkit/deployment.dart';
import 'package:app/toolkit/toolkit.dart' show S;

/// State of the table list load (`GET /inventory/products/builder/list/`).
enum TablesStatus { idle, loading, ready, empty, error }

/// How an import started ([TablesService.import]).
///
/// It's how it **started** and not how it finished because an import no
/// longer finishes inside the call: the table is created on the spot and the
/// rest —its columns' types, set by the backend, and its rows, uploaded
/// afterward— keeps going in the background (see [TableImportStage]). Whoever
/// triggered it no longer hears about that; the list does, showing what each
/// table is up to.
enum TableImportResult {
  /// The table was created. What's left keeps going on its own.
  started,

  /// The chosen file is neither a spreadsheet nor a CSV. Nothing was
  /// uploaded.
  unsupported,

  /// Nothing was created. The error was already shown.
  failed
}

/// What an import that keeps running after the table already exists is up to
/// ([TablesService.importStage]).
///
/// Both stages are real waits —the first a good half a minute, the second
/// however long the file takes to upload— and in both the table is in the
/// list and **half done**: that's why they're shown in its row, and why a
/// table carrying one of them doesn't open (see [TablesService.isBusy]).
///
/// A table is not only marked by the import that started here. The backend
/// announces the first stage on its own ([TableNormalizingModel]), so a
/// spreadsheet uploaded from another device or another tab shows up here in
/// the same state as the one uploaded from this one.
enum TableImportStage {
  /// The backend is typing the file's columns and its image column. Until it
  /// signals ([TableReadyModel]) the table has all its columns as `text`,
  /// the names the file wrote, and no rows.
  preparing,

  /// The columns are already typed: the file's rows are being uploaded.
  loading
}

/// How long to wait for the notice that an imported table became ready before
/// uploading its rows anyway.
///
/// It's not how long the backend takes to prepare it —that's about thirty
/// seconds— but the margin for the notice to arrive: it travels over socket,
/// and if the connection is down the event is lost and never arrives.
/// Without this cap the import would wait forever for a notice on a file
/// that's already chosen and a table that already exists.
const Duration _kReadyTimeout = Duration(minutes: 2);

/// State and behavior of the active business's product tables.
///
/// Concentrates the operations on tables: reading the list, which uses the
/// `inventory` section, creating a new table and, on one that already
/// exists, editing its header and deleting it.
///
/// The three writes bring the cache up to date without rereading the list,
/// but not in the same way: creation invalidates it (`idle`), because the new
/// table has to be fetched —the backend gave it its id, and if it came with a
/// template, its columns too—; editing and deletion fix the row in memory,
/// because what changed is already fully known on this side.
///
/// It's registered in the app's highest scope (`initialBuilder`) with
/// `ChangeNotifierProvider` because its state —the list cache— has to survive
/// navigation between the list and the creation screen.
///
/// The cache is per business: tables travel tied to the active business (the
/// `business_id` header set by [useBusiness]), so the list reloads on its own
/// when the business changes. That's why [load] takes the business's id
/// instead of figuring it out: it keeps the service decoupled from
/// `BusinessService`.
///
/// **And it also listens.** The import is the only thing here that doesn't
/// finish inside the call that triggers it: the table is created on the spot
/// and the backend keeps preparing it behind the scenes, so the service
/// follows that from the two notices that bracket it —`table/normalizing`
/// ([TableNormalizingModel]) and `table/ready` ([TableReadyModel])— to upload
/// its rows and to fix the list. That's also why the listening lives here and
/// not on the screen: the import survives leaving the section.
///
/// Listening to the first of the two is what makes the state honest for
/// **everyone** and not only for whoever uploaded the file: a table imported
/// from another device shows up here the moment it is created, marked as
/// still being built, and is not opened until it lands (see [isBusy]).
class TablesService extends ChangeNotifier {
  TablesService({InventorySource? source}) : _injected = source {
    // Registered before the connection even exists: the socket keeps
    // listeners and hooks them up once it opens, so there's no need to wait
    // for anything or re-register after a reconnect.
    //
    // Two events and not one because the wait has two ends: the backend says
    // it started preparing a table and, half a minute later, that it
    // finished. Only the second one used to be listened to —it was the one
    // that unblocked the upload— and that left every table imported from
    // somewhere else looking finished the whole time it was being built.
    _unlisten = [
      ConnectionService().on(TableNormalizingModel.event, _onNormalizing),
      ConnectionService().on(TableReadyModel.event, _onReady)
    ];
  }

  final InventorySource? _injected;

  InventorySource get _source => _injected ?? Sources.inventory;

  TablesStatus _status = TablesStatus.idle;
  List<TableLiteModel> _tables = const [];

  /// Business the current cache was loaded for. If it doesn't match the
  /// active one, [load] refreshes even if the cache is `ready`.
  String? _businessId;

  /// Unsubscribes from `table/normalizing` and `table/ready`, to release
  /// them when the service dies.
  List<void Function()> _unlisten = const [];

  /// What each import that's still running is up to, by table id. A table
  /// not here has nothing pending.
  final Map<String, TableImportStage> _importing = {};

  /// Imports waiting on the backend's notice, by table id. Completed when
  /// that table's event arrives, and given up on after a timeout
  /// ([_kReadyTimeout]) if it never does.
  final Map<String, Completer<TableReadyModel?>> _pending = {};

  /// Tables marked by the backend's notice that nobody here is following,
  /// with the timer that gives up on each one.
  ///
  /// An import started from here always ends —its upload finishes, well or
  /// badly, and clears the mark. One started somewhere else has no such
  /// ending on this side: the only thing that unmarks it is `table/ready`,
  /// which travels over the socket and is lost if the connection drops while
  /// the table is being prepared. Without this, that table would stay locked
  /// for the rest of the session over a notice that is never coming.
  final Map<String, Timer> _watching = {};

  /// `table/ready` notices nobody was waiting for yet, by table id.
  ///
  /// A master types an import's columns before it answers, so its notice can
  /// arrive between the answer and [_awaitReady]: kept here, the wait that
  /// starts next finds it instead of sitting out [_kReadyTimeout] for a notice
  /// that already came.
  final Map<String, TableReadyModel> _landed = {};

  TablesStatus get status => _status;
  List<TableLiteModel> get tables => List.unmodifiable(_tables);

  /// What table [tableId]'s import is up to, or `null` if it has none
  /// running. Every row in the list checks it to signal that this table is
  /// still being built.
  TableImportStage? importStage(String tableId) => _importing[tableId];

  /// Whether [tableId] is still being built, and therefore **cannot be
  /// opened**.
  ///
  /// A table is in the list from the moment it exists, which is long before
  /// it is finished: its columns are still `text` and named as the file
  /// named them, and its rows have not been uploaded. Opening it there shows
  /// a sheet that is missing most of what was imported, which reads as an
  /// import that failed rather than as one that is halfway — and the answer
  /// people give to that is importing the file again.
  ///
  /// So the row says what the table is up to and doesn't let you in until it
  /// lands. It's the same question [importStage] answers; it has its own
  /// name because whoever asks it isn't drawing the stage, it's deciding
  /// whether to navigate.
  bool isBusy(String tableId) => _importing.containsKey(tableId);

  /// Marks [tableId] as still being built, the way the backend's notice
  /// does.
  ///
  /// Nothing in the app writes a stage from outside: the two socket events
  /// and the import itself are what move it. It exists so the rule that
  /// hangs off it —a table being built does not open— can be pinned without
  /// a socket and without an upload.
  @visibleForTesting
  void seedImport(String tableId, TableImportStage stage) {
    _importing[tableId] = stage;
    notifyListeners();
  }

  /// Loads [businessId]'s tables.
  ///
  /// It's cached: once loaded, later visits to the section don't hit the
  /// backend again unless [force] is asked for, the active business changes,
  /// or a creation invalidates the cache leaving the state at `idle`.
  ///
  /// A business change always wins: it isn't stopped by an in-flight read
  /// (which belongs to the previous business) nor by a `ready` cache (same),
  /// and whatever had loaded is dropped on the spot so nobody gets to read the
  /// other business's tables while this one's are arriving.
  ///
  /// It also carries over half-done imports, which belong to the previous
  /// business: the socket is tied to a single business per connection, so
  /// changing business leaves whatever notice it was waiting for with no way
  /// to arrive, and uploading that table's rows would no longer be possible
  /// —the request travels with the active business, which isn't the table's
  /// owner—.
  Future<void> load(String businessId, {bool force = false}) async {
    final changed = _businessId != businessId;

    if (!changed) {
      if (_status == TablesStatus.loading) return;
      if (!force && _status == TablesStatus.ready) return;
    }

    if (changed) {
      _tables = const [];
      _abandon();
    }

    _businessId = businessId;
    _status = TablesStatus.loading;
    notifyListeners();

    final data = await _source.tables().then<List<TableLiteModel>?>((tables) => tables).catchError((error) {
      if (kDebugMode) print("loadTables failed: $error");
      return null;
    });

    // The business changed while the read was traveling: what arrived
    // belongs to the previous one. It's discarded entirely, error included,
    // because the read that counts is the one the change triggered and is
    // already on its way.
    if (_businessId != businessId) return;

    if (data == null) {
      _status = TablesStatus.error;
      notifyListeners();
      return;
    }

    _tables = data;
    _status = _tables.isEmpty ? TablesStatus.empty : TablesStatus.ready;

    notifyListeners();
  }

  /// Creates a table's structure against
  /// `POST /inventory/products/builder/structure/`.
  ///
  /// The owning business doesn't travel in [data]: it goes in the
  /// `business_id` header the apis set on their own (see `useBusiness` in
  /// `toolkit/api.dart`).
  ///
  /// Returns the created table's identifier. On error it shows the floating
  /// banner and rethrows, so the screen can turn off its loading state. On
  /// success it invalidates the list cache (`idle`) so the next read brings
  /// the new table.
  Future<String> create(BuildContext context, Map<String, dynamic> data) async {
    try {
      final id = await _source.createTable(data);

      // The just-created table isn't in the cache yet: it's marked stale so
      // the list requests it again once opened.
      _status = TablesStatus.idle;

      return id;
    } catch (error) {
      // The error is always logged, even when it's shown to the user: the
      // text that reaches the screen is often trimmed and this keeps the raw
      // one.
      if (kDebugMode) print("createTable failed: $error");

      if (context.mounted) _report(context, error);

      rethrow;
    }
  }

  /// Changes a table's title and description against
  /// `PUT /inventory/products/builder/structure/`.
  ///
  /// The cache isn't invalidated: what changed is the only thing the list
  /// shows of that table, so the row is rewritten in memory and the list
  /// repaints on its own. Requesting the whole set of tables again to change
  /// two texts already in hand would be one read too many —and one wait too
  /// many— per rename.
  ///
  /// Counts (columns and records) aren't touched: editing the header doesn't
  /// change them.
  ///
  /// Returns `true` if the change went well. On error it shows the floating
  /// banner and returns `false`, with the row as it was.
  Future<bool> edit(
    BuildContext context,
    TableLiteModel table, {
    required String title,
    required String description
  }) async {
    if (table.id.isEmpty) return false;

    try {
      await _source.editTable(editTableRequest(
        id: table.id,
        title: title,
        description: description
      ));
    } catch (error) {
      if (kDebugMode) print("editTable failed: $error");

      if (context.mounted) _report(context, error);

      return false;
    }

    // The table may have left the cache while the change was traveling (a
    // business change, a reload): then there's no row to rewrite and what's
    // read afterward already comes with the new title.
    final index = _tables.indexWhere((current) => current.id == table.id);

    if (index >= 0) {
      _tables = List<TableLiteModel>.from(_tables)
        ..[index] = _tables[index].withText(
          title: title.trim(),
          description: description.trim()
        );

      notifyListeners();
    }

    return true;
  }

  /// Fixes the title and/or description of a row in the list **without
  /// writing anything**.
  ///
  /// It's for changes someone else wrote: a table's settings screen edits
  /// against its own endpoint (`PUT /inventory/products/builder/details/`,
  /// see `TableDetailService.edit`) because it's a partial edit, and
  /// afterward notifies through here so the list doesn't keep showing the old
  /// name.
  ///
  /// It's the same thing [edit] does to the cache after saving, and that's
  /// why it invalidates nothing: what changed is the only thing the list
  /// shows of that table, and it's already fully known on this side.
  void applyText(String tableId, {String? title, String? description}) {
    if (tableId.isEmpty || (title == null && description == null)) return;

    final index = _tables.indexWhere((current) => current.id == tableId);

    // The table may not be in the cache: the business changed, or the list
    // was never actually read (entered via deep link). What's read
    // afterward already comes with the new text.
    if (index < 0) return;

    _tables = List<TableLiteModel>.from(_tables)
      ..[index] = _tables[index].withText(
        title: title?.trim(),
        description: description?.trim()
      );

    notifyListeners();
  }

  /// Deletes a table against `DELETE /inventory/products/builder/structure/`.
  ///
  /// It takes the table, its columns and everything loaded in it, so whoever
  /// calls it must have already confirmed: the service doesn't ask.
  ///
  /// As with editing, the cache is fixed on the spot —the row is removed—
  /// instead of invalidated: the table that was deleted is the only thing
  /// that changed, so it disappears from the list without it flickering into
  /// a loading state again. If it was the last one, the list goes to `empty`
  /// and shows its message.
  Future<bool> remove(BuildContext context, TableLiteModel table) async {
    if (table.id.isEmpty) return false;

    try {
      await _source.deleteTable(table.id);
    } catch (error) {
      if (kDebugMode) print("deleteTable failed: $error");

      if (context.mounted) _report(context, error);

      return false;
    }

    final remaining = _tables
      .where((current) => current.id != table.id)
      .toList();

    // Nothing to remove: the cache no longer was the one holding this table
    // (the business changed, or the list reloaded while the deletion was
    // traveling).
    if (remaining.length == _tables.length) return true;

    _tables = remaining;

    // State follows what's left: with no tables, the list has to show its
    // empty message and not a blank list.
    if (_status == TablesStatus.ready && _tables.isEmpty) {
      _status = TablesStatus.empty;
    }

    notifyListeners();

    return true;
  }

  /// Imports a table from a spreadsheet or a CSV.
  ///
  /// **They're two uploads of the same file, with a wait in between**,
  /// because that's how the backend splits it:
  ///
  /// 1. `POST /inventory/products/import/structure/<format>/` creates the
  ///    table with the columns from the header row and returns its id **on
  ///    the spot**. It doesn't save a single data row, and columns are all
  ///    born as `text`: what type each one has isn't told by the header,
  ///    the values have to be looked at and a model asked, and the backend
  ///    does that **behind the response**. When it's done it signals over
  ///    socket (`table/ready`, see [TableReadyModel]) and along the way sets
  ///    up the image column.
  /// 2. `POST /inventory/products/import/records/<format>/` uploads the file
  ///    again, now against that table, and loads everything under the
  ///    header. Columns are matched **by name**, so this pass doesn't depend
  ///    on what order the fields ended up in.
  ///
  /// **The second upload waits for the first one's notice**, and that isn't
  /// tidiness but the only way for the table to come out right: each row is
  /// saved —and indexed for semantic search— with the type the column has
  /// **at that moment**. Uploading them earlier would leave them all as text
  /// against columns that are going to be numbers, dates or prices, and with
  /// not a single embedding generated: the backend doesn't pass over them
  /// again (it normalizes with `reindex: false`, precisely because it counts
  /// on the rows not being there yet). If the notice never arrives —the
  /// realtime connection is down— it uploads anyway once [_kReadyTimeout]
  /// passes: a table with its types half set is better than an import that
  /// never finishes.
  ///
  /// That's why **the call returns as soon as the table exists** and the rest
  /// keeps going on its own: there's a good half a minute between the two
  /// uploads, and leaving the screen hanging on that would make whoever's
  /// importing wait for exactly what the backend decided not to make them
  /// wait for. What each one is up to is told by [importStage], which is what
  /// the list shows.
  ///
  /// The file travels whole both times: it's the price paid for the backend
  /// not keeping anything between one call and the other, and in exchange
  /// there are no half-uploaded files on the other side if the second one
  /// fails.
  ///
  /// [headerRow] is which of the file's rows carries the column names
  /// (1-based). It's always sent, even when it's the first one, so as not to
  /// depend on the backend's default.
  ///
  /// Which endpoint it uploads to is decided by the extension
  /// ([importFormatOf]); a file that's neither spreadsheet nor CSV isn't
  /// uploaded (`unsupported`), since there'd be neither of the two to send it
  /// to.
  ///
  /// Like creation, it invalidates the list cache as soon as the table
  /// exists —also if the rows fail afterward, because the empty table is
  /// already created and has to show up.
  Future<TableImportResult> import(
    BuildContext context,
    File file, {
    int headerRow = 1
  }) async {
    final format = importFormatOf(file.path);
    if (format == null) return TableImportResult.unsupported;

    // The two final notices are built **before** anything is uploaded, with
    // the only context known to still be mounted: the one left over belongs
    // to a screen that may be gone by then, and wouldn't even be usable to
    // translate them.
    final done = S.of(context).import_table_done;
    final failure = S.of(context).import_table_partial;

    final name = importTableName(file.path);
    final String tableId;

    try {
      tableId = await _source.importStructure(format, file, name: name, headerRow: headerRow);
    } catch (error) {
      if (kDebugMode) print("importTableStructure failed: $error");

      if (context.mounted) _report(context, error);

      return TableImportResult.failed;
    }

    // The table already exists even though its rows don't yet: the cache
    // expires here and not only at the end, so a failure in the second
    // upload still shows the created table instead of hiding it until the
    // next reload.
    _status = TablesStatus.idle;
    _importing[tableId] = TableImportStage.preparing;
    notifyListeners();

    // No `await` on purpose: what follows is the wait on the backend and the
    // second upload, and whoever imported doesn't have to stay watching
    // them.
    unawaited(_importRecords(
      tableId: tableId,
      file: file,
      format: format,
      headerRow: headerRow,
      done: done,
      failure: failure
    ));

    return TableImportResult.started;
  }

  /// The second half of the import, the one that runs on its own: waiting
  /// for the backend to finish preparing the table and only then uploading
  /// its rows.
  ///
  /// It notifies with the floating banner and returns nothing because by the
  /// time this finishes the screen that triggered it may no longer exist;
  /// that's also why the texts arrive already translated and the banner
  /// hangs off the navigator (`FloatFlag.of()` with no context).
  ///
  /// It gives up quietly if the import stopped being registered: that
  /// happens when the session closes or the business changes while it was
  /// waiting, and by then there's no table left to upload anything to.
  Future<void> _importRecords({
    required String tableId,
    required File file,
    required ImportFormat format,
    required int headerRow,
    required String done,
    required String failure
  }) async {
    await _awaitReady(tableId);

    if (_importing[tableId] != TableImportStage.preparing) return;

    _importing[tableId] = TableImportStage.loading;
    notifyListeners();

    bool ok = true;

    try {
      await _source.importRecords(format, file, tableId: tableId, headerRow: headerRow);
    } catch (error) {
      ok = false;

      if (kDebugMode) print("importTableRecords failed: $error");
    }

    if (_importing.remove(tableId) == null) return;

    if (ok) {
      FloatFlag.of().message(done);

      // The pictures the rows name by file are most often next to the spreadsheet.
      unawaited(PictureImportService().afterImport(tableId, file));
    } else {
      FloatFlag.of().error(message: failure);
    }

    await _reload();
  }

  /// Waits for [tableId]'s `table/ready`, or gives up once [_kReadyTimeout]
  /// passes.
  ///
  /// Returns `null` when it gave up: that's not a failure that needs
  /// reporting —the table is created and the backend either prepared it or
  /// not, but that no longer depends on this side— but the signal to keep
  /// going without the notice.
  Future<TableReadyModel?> _awaitReady(String tableId) {
    final landed = _landed.remove(tableId);
    if (landed != null) return Future.value(landed);

    final completer = Completer<TableReadyModel?>();
    _pending[tableId] = completer;

    return completer.future.timeout(_kReadyTimeout, onTimeout: () {
      _pending.remove(tableId);
      return null;
    });
  }

  /// The notice that the backend started preparing a table.
  ///
  /// It's what marks a table as still being built **without this side having
  /// imported it**: the spreadsheet went up from another device or another
  /// tab, and until now the only trace of that here was a table that looked
  /// finished and opened empty.
  ///
  /// An import running from here already marked it, and by now may be
  /// further along than this event says (uploading its rows): its stage is
  /// left alone, since going back to `preparing` would be undoing what this
  /// side knows first-hand.
  ///
  /// The table is almost never in the list yet —the event travels right
  /// behind the import that created it— so the list is fetched again, which
  /// is what makes it **show up while it's being prepared** instead of after.
  void _onNormalizing(dynamic data) {
    final report = TableNormalizingModel.fromEvent(data);
    if (report.isEmpty) return;

    if (_importing.containsKey(report.id)) {
      notifyListeners();
      return;
    }

    _importing[report.id] = TableImportStage.preparing;

    _watching.remove(report.id)?.cancel();
    _watching[report.id] = Timer(_kReadyTimeout, () => _giveUp(report.id));

    if (_tables.any((table) => table.id == report.id)) {
      notifyListeners();
      return;
    }

    _reload();
  }

  /// The notice that a table became ready.
  ///
  /// If it belongs to an import that started here, all it does is unblock the
  /// wait: [_importRecords] takes it from there —it's the one that clears the
  /// stage, once the rows are up— and reloads the list once.
  ///
  /// If not —another device imported it, or normalizing the table was
  /// requested from elsewhere— the wait ends here: whatever [_onNormalizing]
  /// marked is cleared, which is what opens the table again, and the list is
  /// fetched: that table just gained types, names and one more column.
  void _onReady(dynamic data) {
    final report = TableReadyModel.fromEvent(data);
    if (report.isEmpty) return;

    _watching.remove(report.id)?.cancel();

    final pending = _pending.remove(report.id);

    if (pending != null) {
      if (!pending.isCompleted) pending.complete(report);
      return;
    }

    _landed[report.id] = report;
    _importing.remove(report.id);

    _reload();
  }

  /// Gives up on a table whose `table/ready` never arrived.
  ///
  /// The mark is dropped and the list reread, which is the honest answer: the
  /// backend prepared that table or it did not, but from here there is no
  /// longer any way to tell, and a table nobody can open is worse than one
  /// that opens half done.
  void _giveUp(String tableId) {
    _watching.remove(tableId);

    if (_importing.remove(tableId) == null) return;

    _reload();
  }

  /// Reloads the list if rereading it makes sense.
  ///
  /// Only when one is already loaded: if it's stale (`idle`) or was never
  /// read, requesting it here would be a read for no one —the section
  /// requests it on its own when opened— and it's enough to just notify,
  /// which is what clears the row's "table is still being built" banner.
  Future<void> _reload() {
    final businessId = _businessId;

    if (businessId == null ||
        (_status != TablesStatus.ready && _status != TablesStatus.empty)) {
      notifyListeners();
      return Future.value();
    }

    return load(businessId, force: true);
  }

  /// Empties the cache. Called on sign-out, along with the rest of the
  /// session's services.
  ///
  /// It also carries away half-done imports, and that's what cuts them off:
  /// whichever one was waiting on the backend's notice sees it's no longer
  /// registered and gives up without uploading anything. Uploading the rows
  /// of a table from the session that just closed wouldn't reach anywhere.
  void clear() {
    _tables = const [];
    _status = TablesStatus.idle;
    _businessId = null;
    _abandon();
    notifyListeners();
  }

  @override
  void dispose() {
    for (final unlisten in _unlisten) {
      unlisten();
    }

    _unlisten = const [];
    _abandon();
    super.dispose();
  }

  /// Releases pending imports: unblocks the ones waiting (with `null`, which
  /// means "keep going without the notice") and clears what they were up to,
  /// which is what makes them give up.
  void _abandon() {
    _importing.clear();
    _landed.clear();

    for (final timer in _watching.values) {
      timer.cancel();
    }

    _watching.clear();

    for (final completer in _pending.values) {
      if (!completer.isCompleted) completer.complete(null);
    }

    _pending.clear();
  }

  /// Shows an error from an operation on tables.
  ///
  /// It never fails silently: if the error brings nothing showable, it still
  /// notifies. An `action` is a navigation instruction (an expired session,
  /// for example): it's rethrown as-is so whoever should handle it does, so
  /// this call may not return.
  ///
  /// Whoever calls it checks beforehand that the screen is still mounted:
  /// with the tree unmounted there's no one to notify, and deciding what to
  /// do in that case —rethrow, return a result— is each operation's own
  /// call.
  void _report(BuildContext context, Object error) {
    if (error is Map && error["action"] != null) throw error["action"];

    FloatFlag.of(context).fromError(
      error is Map && error.isNotEmpty ? error : {"message": error.toString()}
    );
  }
}
