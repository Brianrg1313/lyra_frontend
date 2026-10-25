import 'dart:async';

import 'package:flutter/foundation.dart';

// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart' show Grant;

// SERVICES
import 'package:app/services/business/branch_service.dart';
import 'package:app/services/connection/connection_service.dart';
import 'package:app/services/permissions/sources/permissions_source.dart';
import 'package:app/services/stock/prices/branch_price_model.dart';
import 'package:app/services/stock/sources/stock_source.dart';
import 'package:app/toolkit/backend/deployment.dart';

enum BranchPricesStatus { idle, loading, ready, error }

/// One product's own prices at the company's branches (`sedes-frontend.md` §6), owned by its
/// panel. Every branch's are read; only the branch worked in is written (the header's: `PUT`
/// and `DELETE` act on it), by someone with `products.price` there.
///
/// `price/changed` for this product (any branch) reads them again.
class BranchPricesService extends ChangeNotifier {
  BranchPricesService({required this.productId, this.tableId = "", StockSource? source, PermissionsSource? permissions})
    : _injected = source, _injectedPermissions = permissions;

  final String productId;
  final String tableId;

  final StockSource? _injected;
  final PermissionsSource? _injectedPermissions;

  StockSource get _source => _injected ?? Sources.stock;
  PermissionsSource get _permissions => _injectedPermissions ?? Sources.permissions;

  static const String changedEvent = "price/changed";

  BranchPricesStatus _status = BranchPricesStatus.idle;
  BranchPricesStatus get status => _status;

  List<BranchPrice> _prices = const [];

  Grant _grant = Grant.none();

  /// Whether the person may set the price of the branch worked in.
  bool get canPrice => _grant.can("products.price");

  bool _writing = false;
  bool get writing => _writing;

  void Function()? _off;
  bool _disposed = false;

  /// [branch]'s own price, or null when it sells at the catalog's.
  BranchPrice? of(String branch) {
    for (final price in _prices) {
      if (price.branchId == branch) return price;
    }
    return null;
  }

  /// The branch worked in's own price.
  BranchPrice? get here {
    final branch = BranchService().activeId;
    return branch == null ? null : of(branch);
  }

  Future<void> load() async {
    _off ??= ConnectionService().on(changedEvent, _onChanged);

    _status = BranchPricesStatus.loading;
    _notify();

    try {
      final (prices, grant) = await (_source.prices([productId]), _readGrant()).wait;
      _prices = [for (final price in prices) if (price.productId == productId) price];
      _grant = grant;
      _status = BranchPricesStatus.ready;
    } catch (error) {
      if (kDebugMode) print("branch prices failed: $error");
      _status = BranchPricesStatus.error;
    }

    _notify();
  }

  /// Sets the branch worked in's price and/or offer (`setBranchPriceRequest`). Throws the
  /// refusal; the list is read again either way it lands.
  Future<void> set({double? price, double? discount, bool clearDiscount = false}) => _write(() => _source.setPrice(
    setBranchPriceRequest(productId: productId, tableId: tableId, price: price, discount: discount, clearDiscount: clearDiscount)
  ));

  /// The branch worked in back on the catalog's price. Throws the refusal.
  Future<void> remove() => _write(() => _source.removePrice(removeBranchPriceRequest(productId)));

  Future<void> _write(Future<void> Function() call) async {
    if (_writing) return;

    _writing = true;
    _notify();

    try {
      await call();
      _prices = [for (final price in await _source.prices([productId])) if (price.productId == productId) price];
    } finally {
      _writing = false;
      _notify();
    }
  }

  Future<Grant> _readGrant() async {
    try {
      return await _permissions.mine();
    } catch (_) {
      return Grant.none();
    }
  }

  void _onChanged(dynamic data) {
    if (data is! Map || data["product_id"]?.toString() != productId || _writing) return;

    unawaited(load());
  }

  /// Seeds the prices, for tests.
  @visibleForTesting
  void seed(List<BranchPrice> prices, {Grant? grant}) {
    _prices = prices;
    if (grant != null) _grant = grant;
    _status = BranchPricesStatus.ready;
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
