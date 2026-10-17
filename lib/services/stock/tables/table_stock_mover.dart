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

/// The sheet's stock cells move their product through the inventory's movement form: the
/// stock is the inventory engine's (`STOCK` is never written as a cell), so typing a figure
/// would skip why it changed. The balance the backend answers is written in the row
/// ([TableViewService.writeStock]), with no re-read.
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

      if (context.mounted) {
        FloatFlag.of(context).fromError(error is Map && error.isNotEmpty ? error : {"message": error.toString()});
      }

      return false;
    }
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
}
