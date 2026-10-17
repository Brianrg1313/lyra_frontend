// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart';

// SERVICES
import 'package:app/services/kitchen/presentation_model.dart';
import 'package:app/services/lan/lan_service.dart';
import 'package:app/services/stock/movements/stock_movement_model.dart';
import 'package:app/services/stock/prices/branch_price_model.dart';
import 'package:app/services/stock/movements/stock_ledger_model.dart';
import 'package:app/services/stock/transfers/stock_transfer_model.dart';
import 'package:app/services/stock/sources/stock_source.dart';
import 'package:app/services/stock/summary/stock_summary_model.dart';
import 'package:app/toolkit/deployment.dart';

/// [StockSource] over the master (`docs/offline/specs/stock.md`): the cloud's five endpoints
/// are one `stock.move` with its `operation`.
class StockLanSource implements StockSource {
  const StockLanSource(this._lan);

  final LanService _lan;

  /// [StockOperation] → `stock.move`'s `operation` (`StockOperations`).
  static String operationOf(StockOperation operation) => switch (operation) {
    StockOperation.add => StockOperations.add,
    StockOperation.remove => StockOperations.remove,
    StockOperation.reserve => StockOperations.reserve,
    StockOperation.unreserve => StockOperations.unreserve,
    StockOperation.receiveReturn => StockOperations.receiveReturn
  };

  @override
  Future<StockSummaryPage> summary({
    required int page,
    required int size,
    String match = "",
    String tableId = "",
    StockSummarySort? sort
  }) async {
    final answer = await _lan.call(Ops.stockSummary, args: {
      "page": page,
      "size": size,
      if (match.isNotEmpty) "match": match,
      if (tableId.isNotEmpty) "tableId": tableId,
      if (sort != null) "sort": {"field": sort.key, "dir": sort.descending ? "desc" : "asc"}
    });
    if (answer is! Map) throw const UnreadableAnswer("stock.summary");

    return StockSummaryPage.fromResponse(answer);
  }

  @override
  Future<StockBalance> move(
    StockMovement movement, {
    required String tableId,
    required String productId
  }) async {
    final note = movement.note.trim();

    return StockBalance.fromResponse(await _lan.call(Ops.stockMove, args: {
      "operation": operationOf(movement.operation),
      "tableId": tableId,
      "productId": productId,
      "quantity": movement.quantity,
      if (movement.reason != null) "reason": movement.reason!.key,
      if (note.isNotEmpty) "note": note
    }));
  }

  @override
  Future<List<Presentation>> presentations(String productId) async => const [];

  @override
  Future<StockLedgerPage> movements({required String productId, required int page, required int size}) =>
    throw UnsupportedError("reading the ledger is cloud only");

  // A master is one site (plan D6): there is no other branch to send to or price for.

  @override
  Future<StockTransfersPage> transfers(Map<String, dynamic> request) => throw UnsupportedError("stock transfers are cloud only");

  @override
  Future<StockTransfer> createTransfer(Map<String, dynamic> request) => throw UnsupportedError("stock transfers are cloud only");

  @override
  Future<StockTransfer> updateTransfer(Map<String, dynamic> request) => throw UnsupportedError("stock transfers are cloud only");

  @override
  Future<StockTransfer> receiveTransfer(Map<String, dynamic> request) => throw UnsupportedError("stock transfers are cloud only");

  @override
  Future<List<BranchPrice>> prices(List<String> products) => throw UnsupportedError("branch prices are cloud only");

  @override
  Future<void> setPrice(Map<String, dynamic> request) => throw UnsupportedError("branch prices are cloud only");

  @override
  Future<void> removePrice(Map<String, dynamic> request) => throw UnsupportedError("branch prices are cloud only");
}
