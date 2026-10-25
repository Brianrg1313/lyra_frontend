import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/kitchen/kitchen_product_search.dart';
import 'package:app/services/stock/movements/stock_ledger_model.dart';
import 'package:app/services/stock/sources/inventory_source.dart';
import 'package:app/services/stock/sources/stock_source.dart';
import 'package:app/toolkit/backend/deployment.dart';

enum StockHistoryStatus { idle, loading, ready, empty, error }

/// One product's movements at the branch worked in, newest first, a page at a time
/// (`cocina-frontend.md` §10): the panel the stock summary's figure opens.
///
/// A supply spent on a dish names the dish (`for`), and the ledger only has its id: the dishes
/// are named from the catalog tables' first rows once, the first time a page brings one. One
/// not among them reads «a dish».
///
/// Owned by the panel that shows it. Cloud only (`inventory.history`).
class StockHistoryService extends ChangeNotifier {
  StockHistoryService({required this.productId, StockSource? stock, InventorySource? inventory})
    : _stock = stock,
      _inventory = inventory;

  final String productId;
  final StockSource? _stock;
  final InventorySource? _inventory;

  StockSource get _source => _stock ?? Sources.stock;

  static const int _size = 30;

  StockHistoryStatus _status = StockHistoryStatus.idle;
  List<StockLedgerEntry> _entries = const [];
  Map<String, String> _dishes = const {};
  int _page = 1;
  int _total = 0;
  bool _loadingMore = false;
  bool _moreFailed = false;
  bool _named = false;
  bool _disposed = false;

  StockHistoryStatus get status => _status;
  List<StockLedgerEntry> get entries => _entries;
  bool get hasMore => _entries.length < _total;
  bool get loadingMore => _loadingMore;
  bool get moreFailed => _moreFailed;

  /// The name of the dish a movement was for, or empty when it isn't known.
  String dish(String id) => _dishes[id] ?? "";

  Future<void> load() async {
    _status = StockHistoryStatus.loading;
    _notify();

    try {
      final page = await _source.movements(productId: productId, page: 1, size: _size);

      _page = 1;
      _total = page.total;
      _entries = page.entries;
      _status = _entries.isEmpty ? StockHistoryStatus.empty : StockHistoryStatus.ready;
    } catch (error) {
      if (kDebugMode) print("stock history failed: $error");
      _status = StockHistoryStatus.error;
    }

    _notify();
    await _name();
  }

  /// The next page; a failed one is retried by calling it again.
  Future<void> more() async {
    if (_loadingMore || !hasMore) return;

    _loadingMore = true;
    _moreFailed = false;
    _notify();

    try {
      final page = await _source.movements(productId: productId, page: _page + 1, size: _size);

      _page++;
      _total = page.total;
      _entries = [..._entries, ...page.entries];
    } catch (error) {
      if (kDebugMode) print("stock history page failed: $error");
      _moreFailed = true;
    }

    _loadingMore = false;
    _notify();
    await _name();
  }

  Future<void> _name() async {
    if (_named || !_entries.any((entry) => entry.madeFor != null)) return;
    _named = true;

    final search = KitchenProductSearch(inventory: _inventory, stock: _stock);

    try {
      final tables = await (_inventory ?? Sources.inventory).tables();
      _dishes = await search.namesIn({for (final table in tables) if (!table.supplies) table.id});
    } catch (error) {
      if (kDebugMode) print("stock history dishes failed: $error");
      return;
    } finally {
      search.dispose();
    }

    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
