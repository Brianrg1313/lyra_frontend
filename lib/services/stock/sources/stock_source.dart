// SERVICES
import 'package:app/services/stock/movements/stock_movement_model.dart';
import 'package:app/services/stock/summary/stock_summary_model.dart';

/// The stock ledger's summary and movements (`docs/offline/specs/stock.md`).
///
/// Throws the normalised error (`{message, action}`); `no_primary_table` is the
/// message of a company with no table to summarise.
abstract interface class StockSource {
  /// One page of [tableId]'s summary, or of the primary table's without one, in [sort]'s
  /// order when there is one.
  Future<StockSummaryPage> summary({
    required int page,
    required int size,
    String match = "",
    String tableId = "",
    StockSummarySort? sort
  });

  /// Writes [movement] on [productId]; answers the product's balance after it.
  Future<StockBalance> move(
    StockMovement movement, {
    required String tableId,
    required String productId
  });
}
