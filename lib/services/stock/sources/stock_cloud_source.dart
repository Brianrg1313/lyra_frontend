// SERVICES
import 'package:app/services/stock/movements/stock_movement_model.dart';
import 'package:app/services/stock/sources/stock_source.dart';
import 'package:app/services/stock/summary/stock_summary_model.dart';
import 'package:app/toolkit/api.dart';

/// [StockSource] over the backend's REST api.
class StockCloudSource implements StockSource {
  const StockCloudSource();

  @override
  Future<StockSummaryPage> summary({required int page, required int size, String match = ""}) async =>
    StockSummaryPage.fromResponse(await api.post(
      path: "/inventory/stock/summary/",
      version: "v1",
      data: {
        "PAGE": page,
        "SIZE": size,
        if (match.isNotEmpty) "MATCH": match
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
}
