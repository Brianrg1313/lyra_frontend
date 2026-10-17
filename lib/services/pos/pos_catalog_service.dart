import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/connection/connection_service.dart';
import 'package:app/services/pos/pos_product_model.dart';
import 'package:app/services/stock/movements/stock_changed_model.dart';
import 'package:app/services/pos/sources/pos_source.dart';
import 'package:app/toolkit/deployment.dart';

/// Status of the catalog read (`POST /pos/catalog/`).
///
/// [missing] is not an error: the company has no main table, so there is no
/// catalog to sell from yet. It is told apart from [empty] —a catalog with no
/// products, or a filter that matched none— because what has to be shown is
/// different: [missing] is fixed in the inventory section, not by retrying.
enum PosCatalogStatus { idle, loading, ready, empty, missing, error }

/// The products the register sells: the grid of the central panel.
///
/// **The table is not chosen.** A company sells one catalog, so the backend
/// answers for the table it marked as primary and says which one it was
/// ([table]). That is why this service asks for no id: the counter opens and
/// the catalog is there.
///
/// **It pages by cursor and not by page number** (see the endpoint). The grid
/// loads as it is scrolled, so what comes back is the id of the last product of
/// the page and whether there is another one behind it: a page number would
/// make every scroll cost more than the last, and would repeat one product
/// —and drop another— the moment somebody imports a row with the counter open.
/// For the same reason there is no total: what the scroll needs is whether to
/// keep asking, which is [hasMore].
///
/// **The two filters are the panel's two controls.** [search] is the box over
/// the grid and [filter] the category strip above it; they AND together on the
/// backend, which is what a search inside a chosen category is, and either of
/// them goes back to the first page because what was read belongs to a list
/// that no longer exists.
///
/// The endpoint's third way in —`CODE`, the scanner gun's exact lookup— is
/// deliberately not wired here: it is an equality an index serves, and handing
/// the search box to it would answer nothing for half a name. It belongs to the
/// scanner input, which the counter does not have yet.
///
/// **And it listens.** What is left of a product changes without this screen
/// doing anything: another till puts it on a ticket, a bot reserves it, the
/// office restocks it. The ledger announces every one of those
/// ([StockChangedModel]) and the grid writes down the balance as it arrives, so
/// a shop with two registers does not go on offering units that are already
/// promised to somebody standing at the other one. The tile is not disabled by
/// it —a sold-out product can still be ordered— but the number under it is true.
///
/// It is ephemeral: the POS page owns it and it is discarded when leaving it.
class PosCatalogService extends ChangeNotifier {
  PosCatalogService({PosSource? source}) : _injected = source {
    // Registered before the connection is even open: the socket notes its
    // listeners down and hooks them up when it connects, and they survive a
    // reconnection.
    _unlisten = ConnectionService().on(StockChangedModel.event, _onStock);
  }

  final PosSource? _injected;

  PosSource get _source => _injected ?? Sources.pos;

  /// How many products are read at a time. The backend caps the page at 100 and
  /// defaults to 40; the grid draws small tiles and several rows of them fit on
  /// a counter screen, so a short page would be spent before the scroll starts.
  static const int _pageSize = 40;

  /// What the backend answers when the company has no main table. It is not a
  /// failure to retry: nothing has been imported yet.
  /// The cloud sends it as the `message`, a master as the `code`.
  static const String _noTable = "no_primary_table";

  PosCatalogStatus _status = PosCatalogStatus.idle;

  String _table = "";
  final List<PosProduct> _products = [];

  /// Where the next page starts, empty when there is nothing left to load.
  String _cursor = "";

  /// Whether the backend said there is another page behind the last one.
  bool _more = false;

  /// `true` while a read is in flight, so two pages do not overlap.
  bool _reading = false;

  /// `true` when the last page did not arrive. The grid keeps what it had
  /// —which is what there is— and offers to retry at the end, instead of
  /// requesting the same page again on every frame.
  bool _moreFailed = false;

  /// Which read the answer being waited on belongs to. It changes with every
  /// search, every category and every reread, and whatever comes back with
  /// another generation is dropped: those are the products of a filter nobody
  /// is looking at anymore.
  int _generation = 0;

  /// What is written in the search box, already normalized.
  String _query = "";

  /// Category picked in the strip, empty for the whole catalog.
  String _category = "";

  /// Unsubscribes from `stock/changed`, to release it when the page is left.
  void Function()? _unlisten;

  @override
  void dispose() {
    _unlisten?.call();
    _unlisten = null;

    super.dispose();
  }

  PosCatalogStatus get status => _status;

  /// The catalog the backend read. Empty until the first page arrives.
  String get table => _table;

  List<PosProduct> get products => _products;

  /// What is being searched, for the empty state to say whether nothing matched
  /// or there is nothing at all.
  bool get isSearching => _query.isNotEmpty;

  /// Whether a category is filtering the grid.
  bool get isFiltering => _category.isNotEmpty;

  /// The category the grid is showing, or null for the whole catalog.
  ///
  /// It lives here and not in the panel that draws the strip because it is
  /// half of what was read: with two owners, a chip could stay marked over a
  /// grid that is no longer filtered by it. The strip reads which one to mark
  /// from here and writes it with [filter].
  String? get category => _category.isEmpty ? null : _category;

  /// Whether there is anything left to load. It is the backend's answer and not
  /// a comparison against a total: this endpoint counts nothing.
  bool get hasMore => _more && _cursor.isNotEmpty;

  /// Whether the last page did not arrive, which is what makes the end of the
  /// grid offer to retry instead of asking on its own.
  bool get moreFailed => _moreFailed;

  /// Reads the first page. Without [force] it does not ask again once something
  /// has been read: the panel can be rebuilt more than once.
  Future<void> load({bool force = false}) {
    if (!force && _status != PosCatalogStatus.idle) return Future.value();

    return _read(reset: true);
  }

  /// Rereads from the first page, keeping the filters. It is what a change of
  /// catalog would run.
  Future<void> refresh() => _read(reset: true);

  /// Retries after an error. The failed read left nothing to keep.
  Future<void> retry() => _read(reset: true);

  /// Asks for the next page. The grid calls it while drawing the end of the
  /// current one, so it can be called too often: with nothing to bring it does
  /// nothing.
  ///
  /// With the last page failed it also does nothing —the grid is still drawing
  /// and would ask again every frame. That brake is lifted by hand, with
  /// [retryMore].
  Future<void> more() {
    if (_reading || _moreFailed || !hasMore) return Future.value();

    return _read();
  }

  /// Asks again for the page that did not arrive. It is what the button at the
  /// end of the grid does, and the only thing that lifts the brake.
  Future<void> retryMore() {
    if (_reading || !hasMore) return Future.value();

    _moreFailed = false;

    return _read();
  }

  /// Searches [value] over the product names and the codes at once.
  ///
  /// It goes back to the first page: the cursor that was held is a position in
  /// the unfiltered catalog and means nothing in this one.
  Future<void> search(String value) {
    final query = value.trim();
    if (query == _query) return Future.value();

    _query = query;

    return _read(reset: true);
  }

  /// Leaves the grid showing one category, or the whole catalog with null.
  ///
  /// The strip owns which one is marked —it is where whoever is attending is
  /// looking— and this is where that choice becomes the read: filtering the
  /// products already loaded would search the page that came down and not the
  /// catalog, which on anything past forty products is a different answer.
  Future<void> filter(String? category) {
    final label = category?.trim() ?? "";
    if (label == _category) return Future.value();

    _category = label;

    return _read(reset: true);
  }

  /// A page of the catalog.
  ///
  /// With [reset] it is a new read —the first one, a search, a category, a
  /// retry— and what was read is thrown away; without it it is the next page
  /// and the products are added behind the ones already there.
  ///
  /// A page waits for the previous one, but **a new read does not**: somebody
  /// picks a category while a page is coming down often enough, and making it
  /// wait would leave the grid showing what is no longer being asked for. The
  /// one in flight is not cancelled —it cannot be— but is dropped when it
  /// arrives, because the generation it noted is no longer the running one.
  Future<void> _read({bool reset = false}) async {
    if (_reading && !reset) return;

    _reading = true;
    _moreFailed = false;

    // The cursor is read before the reset empties it: a next page carries the
    // one the last answer left, and a new read carries none because it starts
    // at the top of the filter.
    final cursor = reset ? "" : _cursor;

    if (reset) {
      _generation++;
      _products.clear();
      _cursor = "";
      _more = false;
      _status = PosCatalogStatus.loading;
      notifyListeners();
    }

    final generation = _generation;

    final PosCatalogPage page;

    try {
      page = await _source.catalog(
        size: _pageSize,
        cursor: cursor,
        search: _query,
        category: _category
      );
    } catch (error) {
      if (kDebugMode) print("loadPosCatalog failed: $error");

      // What came back belongs to a filter nobody is looking at, so there is
      // nowhere to note it, not even the failure. The lock is not released
      // either: it is no longer this read's, it belongs to the one that
      // replaced it and is still in flight.
      if (generation != _generation) return;

      _reading = false;

      // Without a main table there is no catalog, and that is not something to
      // retry from the counter: it is fixed by importing one. An answer that is
      // not an object ([UnreadableAnswer]) was not understood: drawing it would
      // be a grid of holes, so it is the failure it is and not an empty catalog.
      if (error is Map && (error["message"] == _noTable || error["code"] == _noTable)) {
        _status = PosCatalogStatus.missing;
      } else {
        _nothing();
      }

      notifyListeners();
      return;
    }

    if (generation != _generation) return;

    _reading = false;

    if (page.table.isNotEmpty) _table = page.table;

    _products.addAll(page.products);

    // The backend only sends a cursor while there is another page, so these two
    // agree by construction; both are kept because `more` is the answer and the
    // cursor is where to continue, and a page saying `more` without one is an
    // end and not a loop asking for the same thing forever.
    _cursor = page.cursor;
    _more = page.more;

    _status = _products.isEmpty
      ? PosCatalogStatus.empty
      : PosCatalogStatus.ready;

    notifyListeners();
  }

  /// A product's balance moved somewhere in the company, and the grid writes
  /// down what the ledger says it is now.
  ///
  /// It only touches what is already loaded: a product on a page nobody has
  /// scrolled to yet will be read with the right number when it arrives, and a
  /// notice about a catalog this counter is not selling from is not this grid's.
  ///
  /// Nothing is re-read from the backend. The notice carries the balance after
  /// the movement, so asking for the page again would be a request per tap of
  /// every till in the shop to learn what already arrived.
  void _onStock(dynamic data) {
    final notice = StockChangedModel.fromEvent(data);

    if (notice.isEmpty) return;
    if (_table.isNotEmpty && notice.table.isNotEmpty && notice.table != _table) return;

    final index = _products.indexWhere((product) => product.id == notice.productId);

    if (index == -1) return;

    final product = _products[index];

    // A dish made to order has no shelf: only what its supplies allow moved.
    final reserved = notice.composite ? product.reserved : notice.reserved;

    if (product.stock == notice.available && product.reserved == reserved) {
      return;
    }

    _products[index] = product.withBalance(
      stock: notice.available,
      reserved: reserved
    );

    notifyListeners();
  }

  /// What is left when a read brought nothing: the one that failed and the one
  /// that came back unreadable, which are the same thing said twice.
  void _nothing() {
    if (_products.isEmpty) {
      _status = PosCatalogStatus.error;
      return;
    }

    // A page that did not arrive does not invalidate the ones that did: it is
    // announced at the end of the grid and retried from there.
    _moreFailed = true;
  }
}
