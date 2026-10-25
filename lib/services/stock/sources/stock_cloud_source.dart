// SERVICES
import 'package:app/services/kitchen/presentation_model.dart';
import 'package:app/services/stock/movements/stock_ledger_model.dart';
import 'package:app/services/stock/movements/stock_movement_model.dart';
import 'package:app/services/stock/prices/branch_price_model.dart';
import 'package:app/services/stock/transfers/stock_transfer_model.dart';
import 'package:app/toolkit/backend/deployment.dart' show UnreadableAnswer;
import 'package:app/services/stock/sources/stock_source.dart';
import 'package:app/services/stock/summary/stock_summary_model.dart';
import 'package:app/toolkit/backend/api.dart';

/// [StockSource] over the backend's REST api.
class StockCloudSource implements StockSource {
  const StockCloudSource();

  @override
  Future<StockSummaryPage> summary({
    required int page,
    required int size,
    String match = "",
    String tableId = "",
    StockSummarySort? sort
  }) async =>
    StockSummaryPage.fromResponse(await api.post(
      path: "/inventory/stock/summary/",
      version: "v1",
      data: {
        "PAGE": page,
        "SIZE": size,
        if (match.isNotEmpty) "MATCH": match,
        if (tableId.isNotEmpty) "TABLE_ID": tableId,
        if (sort != null) "SORT": {"FIELD": sort.key, "DIR": sort.descending ? "desc" : "asc"}
      }
    ));

  /// One endpoint per operation (`StockOperation.path`).
  @override
  Future<StockBalance> move(
    StockMovement movement, {
    required String tableId,
    required String productId
  }) async => StockBalance.fromResponse(await api.post(
    path: movement.operation.path,
    version: "v1",
    data: movement.request(tableId: tableId, productId: productId)
  ));

  @override
  Future<StockBalance?> balance({required String tableId, required String productId}) async {
    final data = await api.post(
      path: "/inventory/stock/balance",
      version: "v1",
      data: {"TABLE_ID": tableId, "PRODUCT_ID": productId}
    );

    return data is Map ? StockBalance.fromResponse(data) : null;
  }

  @override
  Future<List<Presentation>> presentations(String productId) async =>
    Presentation.listFrom(await api.get(path: "/inventory/presentations/$productId", version: "v1"));

  @override
  Future<StockLedgerPage> movements({required String productId, required int page, required int size}) async =>
    StockLedgerPage.fromJson(await api.post(
      path: "/inventory/stock/movements",
      version: "v1",
      data: {"PRODUCT_ID": productId, "PAGE": page, "SIZE": size}
    ));

  @override
  Future<StockTransfersPage> transfers(Map<String, dynamic> request) async =>
    StockTransfersPage.fromJson(await api.post(path: "/inventory/stock/transfers/search", version: "v1", data: request));

  @override
  Future<StockTransfer> createTransfer(Map<String, dynamic> request) async =>
    _transfer(await api.post(path: "/inventory/stock/transfers", version: "v1", data: request));

  @override
  Future<StockTransfer> updateTransfer(Map<String, dynamic> request) async =>
    _transfer(await api.put(path: "/inventory/stock/transfers", version: "v1", data: request));

  @override
  Future<StockTransfer> receiveTransfer(Map<String, dynamic> request) async =>
    _transfer(await api.post(path: "/inventory/stock/transfers/receive", version: "v1", data: request));

  @override
  Future<List<BranchPrice>> prices(List<String> products) async => products.isEmpty
    ? const []
    : BranchPrice.listFrom(await api.post(path: "/inventory/products/prices", version: "v1", data: {"PRODUCTS": products}));

  @override
  Future<void> setPrice(Map<String, dynamic> request) =>
    api.put(path: "/inventory/products/prices", version: "v1", data: request);

  @override
  Future<void> removePrice(Map<String, dynamic> request) =>
    api.delete(path: "/inventory/products/prices", version: "v1", data: request);

  static StockTransfer _transfer(dynamic answer) =>
    StockTransfer.read(answer) ?? (throw const UnreadableAnswer("inventory/stock/transfers"));
}
