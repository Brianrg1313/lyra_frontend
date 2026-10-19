import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/kitchen/presentation_model.dart';
import 'package:app/services/stock/movements/stock_mover.dart';
import 'package:app/services/stock/movements/stock_movement_model.dart';
import 'package:app/services/stock/sources/stock_source.dart';
import 'package:app/services/stock/tables/table_view_service.dart';
import 'package:app/toolkit/deployment.dart';

/// The sheet's stock cells move their product through the inventory: the − and + through the
/// movement form, a typed figure as a correction ([correct]). The stock is the inventory
/// engine's, so `STOCK` is never written as a cell. The balance the backend answers is
/// written in the row ([TableViewService.writeStock]), with no re-read.
class TableStockMover implements StockMover {
  TableStockMover({required this.table, required this.tableId, required this.supplies, StockSource? source})
    : _injected = source;

  final TableViewService table;
  final String tableId;

  @override
  final bool supplies;

  final StockSource? _injected;

  StockSource get _source => _injected ?? Sources.stock;

  @override
  Future<bool> move(BuildContext context, {required String productId, required StockMovement movement}) async {
    if (tableId.isEmpty || productId.isEmpty) return false;

    try {
      final balance = await _source.move(movement, tableId: tableId, productId: productId);
      table.writeStock(productId, balance.available);
      return true;
    } catch (error) {
      if (kDebugMode) print("sheet stockMovement failed: $error");

      if (context.mounted) _flag(context, error);

      return false;
    }
  }

  /// Leaves [productId] at [target] at the header's branch: the difference against its
  /// balance there goes in as a correction (`add` or `remove`, reason `correction`), which is
  /// what typing a figure over the shelf's is — a count, not a purchase or a loss.
  ///
  /// The difference is taken from the branch's balance, read first: the cell shows the
  /// company's total, and a movement moves one branch. Where none is read (a master is one
  /// site, a product with no stock yet) it is taken from [shown], the cell's figure. Nothing
  /// to correct writes nothing. `false` when it did not go in; the reason was already shown.
  Future<bool> correct(BuildContext context, {required String productId, required num target, required num shown}) async {
    if (tableId.isEmpty || productId.isEmpty) return false;

    final num current;

    try {
      current = (await _source.balance(tableId: tableId, productId: productId))?.available ?? shown;
    } catch (error) {
      if (kDebugMode) print("sheet stock balance failed: $error");
      if (context.mounted) _flag(context, error);
      return false;
    }

    // In millionths, a supply's precision (`cocina-frontend.md` §1): 1.3 − 1.2 is no 0.1000…01.
    final difference = (target * 1000000).round() - (current * 1000000).round();

    if (difference == 0) {
      table.writeStock(productId, current);
      return true;
    }

    // ignore: use_build_context_synchronously — [move] reaches the context only to flag a failure, and checks it is mounted first.
    return move(context, productId: productId, movement: StockMovement(
      operation: difference > 0 ? StockOperation.add : StockOperation.remove,
      quantity: stockNum(difference.abs() / 1000000) ?? 0,
      reason: difference > 0 ? StockReason.addCorrection : StockReason.removeCorrection
    ));
  }

  @override
  Future<List<Presentation>> presentations(String productId) async {
    try {
      return await _source.presentations(productId);
    } catch (error) {
      if (kDebugMode) print("presentations failed: $error");
      return const [];
    }
  }

  void _flag(BuildContext context, Object error) =>
    FloatFlag.of(context).fromError(error is Map && error.isNotEmpty ? error : {"message": error.toString()});
}
