import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/connection/connection_service.dart';
import 'package:app/services/kitchen/kitchen_product_model.dart';
import 'package:app/services/kitchen/presentation_model.dart';
import 'package:app/services/kitchen/recipe_availability_model.dart';
import 'package:app/services/kitchen/recipe_measure.dart';
import 'package:app/services/stock/movements/stock_changed_model.dart';
import 'package:app/services/stock/movements/stock_mover.dart';
import 'package:app/services/stock/movements/stock_movement_model.dart';
import 'package:app/services/stock/sources/inventory_source.dart';
import 'package:app/services/stock/sources/stock_source.dart';
import 'package:app/services/stock/tables/table_lite_model.dart';
import 'package:app/toolkit/deployment.dart';

/// Status of the recipes tab's list.
enum KitchenProductsStatus { idle, loading, ready, empty, error }

/// The supplies of one table, with what the branch can make of each one made by the batch (a
/// sauce): the production line's tab.
///
/// **Only `supplies` tables** (`cocina-frontend.md` §2.1): what is sold lives in the inventory
/// section, which opens a dish's recipe from its own rows; the two sections never list the
/// same table.
///
/// The backend lists no recipes (`cocina-frontend.md` §3 reads one by product), so the list is
/// the table's stock summary and each page asks `POST /inventory/recipes/availability` for its
/// ids: a product with a recipe answers (how many can be made, what runs out first, its 86), one
/// without is skipped. That makes the availability the mark of «has a recipe».
///
/// Owned by the supply chain section (a business or branch switch remounts it). Live: a
/// `stock/changed` with `composite: true` rewrites a dish's [availability] (a supply was spent,
/// a recipe edited, a dish paused); any other one, a supply's stock.
///
/// Its rows' − and + move a supply through it ([StockMover]): the balance answered is written
/// in the row, before the notice arrives.
class KitchenProductsService extends ChangeNotifier implements StockMover {
  KitchenProductsService({InventorySource? inventory, StockSource? stock, RecipeMeasure? measure, bool listen = true})
    : _inventory = inventory,
      _stock = stock,
      _measureOf = measure ?? measureRecipes {
    if (listen) _off = ConnectionService().on(StockChangedModel.event, _onStock);
  }

  final InventorySource? _inventory;
  final StockSource? _stock;
  final RecipeMeasure _measureOf;
  void Function()? _off;

  InventorySource get _tables => _inventory ?? Sources.inventory;
  StockSource get _summary => _stock ?? Sources.stock;

  static const int _size = 50;

  KitchenProductsStatus _status = KitchenProductsStatus.idle;
  List<TableLiteModel> _tableList = const [];
  TableLiteModel? _table;
  List<KitchenProduct> _products = const [];
  Map<String, RecipeAvailability> _availability = const {};
  String _query = "";
  int _page = 1;
  int _total = 0;
  bool _loadingMore = false;
  int _ticket = 0;
  bool _disposed = false;

  KitchenProductsStatus get status => _status;
  List<TableLiteModel> get tables => _tableList;
  TableLiteModel? get table => _table;
  List<KitchenProduct> get products => _products;
  String get query => _query;
  int get total => _total;
  bool get hasMore => _products.length < _total;
  bool get loadingMore => _loadingMore;

  /// What [productId]'s recipe makes now; `null` when it has none.
  RecipeAvailability? availabilityOf(String productId) => _availability[productId];

  /// Reads the supplies tables and opens [tableId] when it is one of them (else the open one,
  /// else the first). None is [KitchenProductsStatus.empty] with no [table]: the tab offers to
  /// create one.
  Future<void> load({String? tableId}) async {
    _status = KitchenProductsStatus.loading;
    _notify();

    try {
      _tableList = [
        for (final table in await _tables.tables())
          if (table.supplies) table
      ];
    } catch (error) {
      if (kDebugMode) print("kitchen tables failed: $error");

      _status = KitchenProductsStatus.error;
      _notify();
      return;
    }

    if (_tableList.isEmpty) {
      _table = null;
      _products = const [];
      _status = KitchenProductsStatus.empty;
      _notify();
      return;
    }

    final wanted = tableId ?? _table?.id;
    _table = _tableList.where((table) => table.id == wanted).firstOrNull ?? _tableList.first;

    await _read();
  }

  /// Shows [table]'s products.
  Future<void> open(TableLiteModel table) async {
    if (table.id == _table?.id) return;

    _table = table;
    _query = "";
    await _read();
  }

  /// Products of the open table matching [text] (the summary's `MATCH`).
  Future<void> search(String text) async {
    if (text.trim() == _query) return;

    _query = text.trim();
    await _read();
  }

  /// Reads the first page again: after a recipe changed, so its mark and figure are the
  /// backend's.
  Future<void> reload() => _read(quiet: true);

  Future<void> _read({bool quiet = false}) async {
    final table = _table;
    if (table == null) return;

    final ticket = ++_ticket;

    if (!quiet) {
      _status = KitchenProductsStatus.loading;
      _notify();
    }

    try {
      final page = await _summary.summary(page: 1, size: _size, match: _query, tableId: table.id);
      final products = KitchenProduct.fromSummary(page, supplies: table.supplies);
      final availability = await _measure(products);

      if (ticket != _ticket) return;

      _products = products;
      _availability = availability;
      _page = 1;
      _total = page.total;
      _status = products.isEmpty ? KitchenProductsStatus.empty : KitchenProductsStatus.ready;
    } catch (error) {
      if (kDebugMode) print("kitchen products failed: $error");
      if (ticket != _ticket) return;

      if (!quiet) _status = KitchenProductsStatus.error;
    }

    _notify();
  }

  /// The next page of the open table.
  Future<void> more() async {
    final table = _table;
    if (table == null || _loadingMore || !hasMore) return;

    final ticket = _ticket;
    _loadingMore = true;
    _notify();

    try {
      final page = await _summary.summary(page: _page + 1, size: _size, match: _query, tableId: table.id);
      final products = KitchenProduct.fromSummary(page, supplies: table.supplies);
      final availability = await _measure(products);

      if (ticket == _ticket) {
        _products = [..._products, ...products];
        _availability = {..._availability, ...availability};
        _page = page.page;
        _total = page.total;
      }
    } catch (error) {
      if (kDebugMode) print("kitchen products more failed: $error");
    }

    _loadingMore = false;
    _notify();
  }

  /// Measures [productIds] again (a recipe saved, deleted or paused from its panel).
  Future<void> remeasure(List<String> productIds) async {
    try {
      final fresh = await _measureOf(productIds);

      _availability = {
        for (final entry in _availability.entries)
          if (!productIds.contains(entry.key)) entry.key: entry.value,
        ...fresh
      };
      _notify();
    } catch (error) {
      if (kDebugMode) print("kitchen remeasure failed: $error");
    }
  }

  /// The availability of [products], up to the backend's 200 ids per call. A failure reads as
  /// no recipes, so the list still shows; the panel reads its own.
  Future<Map<String, RecipeAvailability>> _measure(List<KitchenProduct> products) async {
    try {
      return await _measureOf([for (final product in products) product.id]);
    } catch (error) {
      if (kDebugMode) print("kitchen availability failed: $error");
      return const {};
    }
  }

  void _onStock(dynamic data) => receive(StockChangedModel.fromEvent(data));

  /// Applies a `stock/changed` notice.
  @visibleForTesting
  void receive(StockChangedModel notice) {
    if (notice.isEmpty) return;

    if (notice.composite) {
      final current = _availability[notice.productId];
      if (current == null) return;

      _availability = {..._availability, notice.productId: current.withAvailable(notice.exact)};
      _notify();
      return;
    }

    _writeStock(notice.productId, notice.exact);
  }

  /// Writes [productId]'s stock in its row, and a batch's shelf with it (its own stock).
  void _writeStock(String productId, double stock) {
    final index = _products.indexWhere((product) => product.id == productId);
    if (index < 0) return;

    final product = _products[index];
    _products = List.of(_products)..[index] = KitchenProduct(
      id: product.id,
      tableId: product.tableId,
      name: product.name,
      unit: product.unit,
      stock: stock,
      supplies: product.supplies,
      made: product.made
    );

    final batch = _availability[productId];
    if (batch != null) {
      _availability = {..._availability, productId: batch.withAvailable(stock)};
    }

    _notify();
  }

  /// This tab lists supplies only.
  @override
  bool get supplies => true;

  @override
  Future<bool> move(BuildContext context, {required String productId, required StockMovement movement}) async {
    final table = _table?.id ?? "";
    if (table.isEmpty || productId.isEmpty) return false;

    try {
      final balance = await _summary.move(movement, tableId: table, productId: productId);
      _writeStock(productId, balance.available * 1.0);
      return true;
    } catch (error) {
      if (kDebugMode) print("kitchen stockMovement failed: $error");

      if (context.mounted) {
        FloatFlag.of(context).fromError(error is Map && error.isNotEmpty ? error : {"message": error.toString()});
      }

      return false;
    }
  }

  @override
  Future<List<Presentation>> presentations(String productId) async {
    try {
      return await _summary.presentations(productId);
    } catch (error) {
      if (kDebugMode) print("presentations failed: $error");
      return const [];
    }
  }

  /// Seeds the list, for tests.
  @visibleForTesting
  void seed({
    List<TableLiteModel> tables = const [],
    List<KitchenProduct> products = const [],
    Map<String, RecipeAvailability> availability = const {}
  }) {
    _tableList = tables;
    _table = tables.firstOrNull;
    _products = products;
    _availability = availability;
    _total = products.length;
    _status = products.isEmpty ? KitchenProductsStatus.empty : KitchenProductsStatus.ready;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _off?.call();
    super.dispose();
  }
}
