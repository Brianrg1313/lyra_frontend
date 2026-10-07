import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

// SERVICES
import 'package:app/services/stock/movements/stock_movement_model.dart';
import 'package:app/services/stock/summary/stock_summary_model.dart';
import 'package:app/services/stock/sources/stock_source.dart';
import 'package:app/toolkit/api.dart';
import 'package:app/toolkit/deployment.dart';

/// Status of the stock summary read (`POST /inventory/stock/summary/`).
///
/// [missing] is not an error: the company does not have any table yet, so
/// there is no inventory to summarize. It is distinguished from [empty] —which
/// is a table without products— and from [error] because what should be shown
/// is different: with [missing] the summary is simply not drawn, which is what
/// the section offers instead: the templates to create the first one.
enum StockSummaryStatus { idle, loading, ready, empty, missing, error }

/// The company's stock summary: what there is, how it looks and how much is
/// left.
///
/// **One table per service.** The inventory section shows the table picked in its header
/// and creates one service for it ([tableId]); without one the backend answers for the
/// company's primary table. Either way it says which one it read ([table]).
///
/// It is not another way of listing a table, and that is why it is not
/// `TableViewService`: the sheet shows all the columns the company ever
/// imported, in the order they came in the file, and knows nothing about stock;
/// this shows the handful that is read at a glance, in the order the company
/// arranged them, and with the inventory numbers next to each row.
///
/// **The rows accumulate.** There are no pages or buttons: the first page is read when
/// opening the section and the next one is requested when the list is about to
/// run out of rows ([more]). How many there are in total is said by the
/// response ([total]), which is what allows knowing when to stop asking.
///
/// **The header search also searches here** ([search]): what is written travels
/// as `MATCH` and the products that mention it in any of their columns come
/// back, counted and paginated just like the whole summary. Filtering in memory
/// would mean searching the rows that were read and not the table, which is
/// another response —and almost always incomplete— as soon as the table goes
/// past a few pages.
///
/// **A column's title orders it** ([sortBy]), and through the backend as well (`SORT`,
/// `stock.md` ST-35): sorting the rows read would be ordering the first pages, not the
/// table. The order outlives a search and a reread; it is dropped by a third click on its
/// title, or when its column leaves the summary or the backend refuses it.
///
/// It is ephemeral: owned by the inventory section and discarded when leaving
/// it. The shell remounts the section when changing company, so there is
/// nothing to invalidate on its own account.
class StockSummaryService extends ChangeNotifier {
  StockSummaryService({StockSource? source, this.tableId = ""}) : _injected = source;

  final StockSource? _injected;

  /// The table summarized; empty asks for the company's primary one.
  final String tableId;

  StockSource get _source => _injected ?? Sources.stock;

  /// How many rows are read at a time. The backend accepts up to 200, but this
  /// is a summary: what matters is that the first page arrives fast, and scrolling down requests the following ones.
  static const int _pageSize = 30;

  /// How many pages at most are requested together again when the columns
  /// change ([syncColumns]). Six by thirty is a hundred and eighty rows: as
  /// close to the backend's cap (200) as one can be without splitting the
  /// reread into two requests.
  static const int _maxSyncPages = 6;

  /// What the backend answers when the company has no table. It is not a
  /// missing table: it is that nothing has been imported yet.
  /// The cloud sends it as the `message`, a master as the `code`.
  static const String _noTable = "no_primary_table";

  StockSummaryStatus _status = StockSummaryStatus.idle;

  String _table = "";
  List<StockSummaryColumn> _columns = const [];
  final List<StockSummaryRow> _rows = [];

  int _total = 0;

  /// Last page that came in. Zero while none has come in.
  int _page = 0;

  /// `true` while there is a read in flight, so two do not overlap.
  bool _reading = false;

  /// `true` when the last batch did not arrive. The list keeps showing what it
  /// had —which is what there is— and offers to retry at the end, instead of
  /// waiting forever for a page that is not coming.
  bool _moreFailed = false;

  /// With which search the read being waited on was made. It changes with each
  /// search and with each reread, and whatever comes back with another
  /// generation is discarded: those are the rows of a search nobody is looking
  /// at anymore.
  int _generation = 0;

  /// What was written in the search box, already normalized.
  String _query = "";

  StockSummarySort? _sort;

  /// What the backend refuses a sort with: the cloud's `message`, a master's `code`.
  static const Set<String> _refusedSort = {"invalid_search", "invalid_field"};

  StockSummaryStatus get status => _status;

  /// The table the backend summarized. Empty while no response has arrived. It
  /// is what allows opening it from a summary row.
  String get table => _table;

  List<StockSummaryColumn> get columns => _columns;
  List<StockSummaryRow> get rows => _rows;

  /// How many products there are (or how many match, if searching), not how
  /// many were read.
  int get total => _total;

  bool get isSearching => _query.isNotEmpty;

  /// The order the rows come in, or null for the backend's own.
  StockSummarySort? get sort => _sort;

  /// Whether there is anything left to read. Decided by the total and not by
  /// the last page: a full page does not mean there is another one behind it.
  bool get hasMore => _rows.length < _total;

  /// Whether the last batch did not arrive. It is what makes the end of the
  /// list offer to retry instead of keeping asking on its own.
  bool get moreFailed => _moreFailed;

  /// Reads the summary. Without [force] it does not request it again if it is
  /// already read: the shell can mount the section more than once.
  ///
  /// [query] is what would have been written in the search box when opening the
  /// section. The header empties it when changing screen, so it normally comes
  /// empty; it is received anyway so as not to read the whole summary when it
  /// is not.
  Future<void> load({bool force = false, String query = ""}) {
    if (!force && _status != StockSummaryStatus.idle) return Future.value();

    _query = query.trim();

    return _read(1, reset: true);
  }

  /// Reads again from the first page. It is what runs after creating or
  /// importing a table: the company may have gone from having none to having
  /// the primary one.
  Future<void> refresh() => _read(1, reset: true);

  /// Retries after an error. The failed one left nothing to keep.
  Future<void> retry() => _read(1, reset: true);

  /// Asks for the next batch. The list calls it when it is about to run out of
  /// rows, so it can be called too much: with nothing to bring, it does
  /// nothing.
  ///
  /// With the last batch failed it also does nothing: the list keeps drawing
  /// and would request it again every frame. That is exited manually, with
  /// [retryMore].
  Future<void> more() {
    if (_reading || _moreFailed || !hasMore) return Future.value();

    return _read(_page + 1);
  }

  /// Asks again for the batch that did not arrive. It is what the button at the
  /// end of the list does, and the only thing that lifts the brake the failure
  /// put on.
  Future<void> retryMore() {
    if (_reading || !hasMore) return Future.value();

    _moreFailed = false;

    return _read(_page + 1);
  }

  /// Searches [value] in all the summary columns at once.
  ///
  /// It goes back to the first page: what was read belongs to the previous
  /// search and its positions are those of a list that no longer exists.
  Future<void> search(String value) {
    final query = value.trim();
    if (query == _query) return Future.value();

    _query = query;

    return _read(1, reset: true);
  }

  /// Orders the summary by the column [key]: from its largest value down, then from its
  /// smallest up, then back to the backend's own order (`StockSummarySort.after`).
  ///
  /// Back to the first page, like [search]: the rows read are in the old order.
  Future<void> sortBy(String key) {
    final column = _columns.where((column) => column.key == key).firstOrNull;
    if (column == null || !column.sortable) return Future.value();

    _sort = StockSummarySort.after(_sort, key);

    return _read(1, reset: true);
  }

  /// Rereads the summary because the columns of [tableId] changed, without
  /// emptying the list.
  ///
  /// A table's settings sheet calls it when someone turns a column's summary on
  /// or off —or changes its type— with the panel open on top of this section:
  /// the summary stayed in view beside it, so it has to say what was just
  /// chosen and not what it said when opened.
  ///
  /// **The rows have to be reread and not only the columns.** The response
  /// brings the values of the summary columns and nothing else, so a newly
  /// turned-on column would be drawn empty in all the rows that were already
  /// there.
  ///
  /// It does nothing if the table that was touched is not the one being
  /// summarized, nor if the summary has not been drawn yet: what is
  /// about to come already brings the new columns.
  Future<void> syncColumns(String tableId) {
    if (tableId.isEmpty || tableId != _table) return Future.value();

    final drawn = _status == StockSummaryStatus.ready ||
      _status == StockSummaryStatus.empty;

    if (!drawn) return Future.value();

    return _read(1, reset: true, quiet: true);
  }

  /// Writes an inventory movement on a product of the summary and leaves the
  /// row saying what ended up.
  ///
  /// It lives here and not in its own service because the two halves of the
  /// work belong to this list: the table written against is the one the backend
  /// summarized ([table], which nobody chose and is only known on this side),
  /// and what comes back —the product's whole balance— is exactly what the
  /// row's `stock` and `reserved` columns were showing.
  ///
  /// That is why the page is not reread either: the backend answers `available`
  /// and `reserved` already computed, so the row is corrected in place. Rereading
  /// would be asking for thirty rows to change two numbers of one, and on top
  /// of that with the list jumping to whatever position that page had.
  ///
  /// Returns `false` if the movement did not go in; the reason was already
  /// shown in the floating flag, which is where the backend explains that there
  /// was not that much to take out.
  Future<bool> move(
    BuildContext context, {
    required String productId,
    required StockMovement movement
  }) async {
    if (_table.isEmpty || productId.isEmpty) return false;

    final StockBalance balance;

    try {
      balance = await _source.move(movement, tableId: _table, productId: productId);
    } catch (error) {
      if (kDebugMode) print("stockMovement failed: $error");

      if (context.mounted) {
        FloatFlag.of(context).fromError(
          error is Map && error.isNotEmpty
            ? error
            : {"message": error.toString()}
        );
      }

      return false;
    }

    _applyBalance(productId, balance);

    return true;
  }

  /// Leaves the two inventory numbers of a row as they ended up.
  ///
  /// The row may not be there: between the movement going out and coming back
  /// something else could have been searched, or the company changed. Then
  /// there is nothing to correct and what is read later already comes with the
  /// new balance.
  void _applyBalance(String productId, StockBalance balance) {
    final index = _rows.indexWhere((row) => row.id == productId);
    if (index < 0) return;

    _rows[index] = _rows[index].withBalance(
      stock: balance.available,
      reserved: balance.reserved
    );

    notifyListeners();
  }

  /// A batch of the summary.
  ///
  /// With [reset] it is a new read —the first one, a search, a retry— and what
  /// was read is thrown away; without it it is the next page and the rows are
  /// added behind the ones already there.
  ///
  /// With [quiet] it is a new read that **does not empty the list**: what there
  /// is stays in view while the response travels and is changed only when it
  /// arrives. It is what runs when the columns changed with the summary in view
  /// ([syncColumns]), where emptying it would be answering a cell with a
  /// spinner and the list jumping to the beginning. For the same reason all the
  /// rows that were read are requested again at once and not the first page:
  /// rereading thirty would leave the list without the rest.
  ///
  /// A batch waits for the previous one to finish, but **a new read does not**:
  /// one searches while a page comes down quite often, and making it wait would
  /// leave the list showing what is no longer being searched. The one that was
  /// in flight is not cancelled —it cannot be— but is discarded when it
  /// arrives: the generation it noted is no longer the running one.
  Future<void> _read(int page, {bool reset = false, bool quiet = false}) async {
    if (_reading && !reset) return;

    _reading = true;
    _moreFailed = false;

    // How many rows are requested. One page, unless what changed were the
    // columns: there, all the ones that were in view are requested again,
    // which is what leaves the list just as it was. It is computed before
    // touching anything because it comes from the pages that already came in.
    final size = quiet
      ? _pageSize * _page.clamp(1, _maxSyncPages)
      : _pageSize;

    if (reset) {
      _generation++;

      // Emptying and showing the wait belongs to a new read in view; the one
      // running underneath does not touch anything until it arrives (see the
      // note above about [quiet]). It does not return the page count to zero
      // either: if that reread does not arrive, the rows that are there remain
      // what they are and the next batch still has to be the next one.
      if (!quiet) {
        _rows.clear();
        _page = 0;
        _status = StockSummaryStatus.loading;
        notifyListeners();
      }
    }

    final generation = _generation;

    final StockSummaryPage result;

    try {
      result = await _source.summary(
        page: page,
        size: size,
        match: _query,
        tableId: tableId,
        sort: _sort
      );
    } catch (error) {
      if (kDebugMode) print("loadStockSummary failed: $error");

      // What came back belongs to a previous search: there is nowhere to note
      // it, not even the failure. The lock is not released either, which is no
      // longer its own: the read that replaced it holds it and is still in
      // flight.
      if (generation != _generation) return;

      _reading = false;

      // A sort the backend no longer takes (its column stopped being one it can order
      // by) would fail every retry the same way: it is dropped and the summary read in
      // its own order, which is what there is to show.
      if (_sort != null && error is Map && (_refusedSort.contains(error["message"]) || _refusedSort.contains(error["code"]))) {
        _sort = null;
        return _read(1, reset: true, quiet: quiet);
      }

      // Without tables there is nothing to summarize, and that is not an error
      // to retry: the section is already offering to create the first one.
      if (error is Map && (error["message"] == _noTable || error["code"] == _noTable)) {
        _columns = const [];
        _total = 0;
        _status = StockSummaryStatus.missing;
      } else {
        _nothing(quiet: quiet);
      }

      notifyListeners();
      return;
    }

    if (generation != _generation) return;

    _reading = false;

    // A response without columns is not an empty summary but a read that was
    // not understood: drawing it would be a list of holes.
    if (result.isEmpty) {
      _nothing(quiet: quiet);
      notifyListeners();
      return;
    }

    _table = result.table;
    _columns = result.columns;
    _total = result.total;

    // The column it was ordered by left the summary (turned off in the table's
    // settings): the rows still come in its order, but no title would say so, so
    // they are read again in the backend's own.
    final sort = _sort;
    if (sort != null && !_columns.any((column) => column.key == sort.key && column.sortable)) {
      _sort = null;
      return _read(1, reset: true, quiet: quiet);
    }

    // The reread underneath brought in a single request the pages that were
    // already there, so the count stays at those and the next batch still is
    // the one that follows.
    _page = quiet ? size ~/ _pageSize : page;

    // A new read replaces what was there. The one in view already emptied it
    // at the start; the one running underneath changes it only here, which was
    // precisely the point.
    if (reset) _rows.clear();

    _rows.addAll(result.rows);

    // A batch that comes back empty is the end, whatever the total says:
    // between it being counted and the page being requested, someone could
    // have deleted rows. Without this the list would keep requesting the next
    // page forever, because whoever decides whether something remains is
    // precisely that total.
    if (result.rows.isEmpty) _total = _rows.length;

    _status = _rows.isEmpty
      ? StockSummaryStatus.empty
      : StockSummaryStatus.ready;

    notifyListeners();
  }

  /// What remains when a read left nothing: the one that failed and the one
  /// that came back without columns, which are the same thing said in two ways.
  ///
  /// An underlying reread that does not come out **does not break anything**:
  /// the list stays with the rows and columns it had a moment ago, which are
  /// still true except for the cell that was just touched. Nothing is warned
  /// —it is not broken, it is old— and what is read later already comes with
  /// the new.
  void _nothing({required bool quiet}) {
    if (quiet) return;

    if (_rows.isEmpty) {
      _status = StockSummaryStatus.error;
      return;
    }

    // A batch that did not arrive does not invalidate what was already being
    // read: it is warned at the end of the list and from there it is retried.
    _moreFailed = true;
  }
}
