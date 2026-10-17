// SERVICES
import 'package:app/services/kitchen/presentation_model.dart';
import 'package:app/services/stock/movements/stock_ledger_model.dart';
import 'package:app/services/stock/movements/stock_movement_model.dart';
import 'package:app/services/stock/prices/branch_price_model.dart';
import 'package:app/services/stock/transfers/stock_transfer_model.dart';
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

  /// How [productId] is bought («Saco» = 25 kg, `cocina-frontend.md` §8), for a movement to
  /// count presentations. Empty when it has none; a master knows none.
  Future<List<Presentation>> presentations(String productId);

  /// A page of [productId]'s ledger at the header's branch, newest first
  /// (`cocina-frontend.md` §10). Cloud only (`inventory.history`): a master's ledger is not
  /// read back by any op.
  Future<StockLedgerPage> movements({required String productId, required int page, required int size});

  // Between branches (`sedes-frontend.md` §6). Cloud only: a master is one site (plan D6), so
  // its source refuses them.

  /// A page of the header's branch's transfers (`searchTransfersRequest`).
  Future<StockTransfersPage> transfers(Map<String, dynamic> request);

  /// Drafts (or drafts and sends) a transfer (`createTransferRequest`); answers it.
  Future<StockTransfer> createTransfer(Map<String, dynamic> request);

  /// Edits, sends or cancels one (`editTransferRequest`, `transferActionRequest`); answers it.
  Future<StockTransfer> updateTransfer(Map<String, dynamic> request);

  /// Counts one in at the header's branch (`receiveTransferRequest`); answers it.
  Future<StockTransfer> receiveTransfer(Map<String, dynamic> request);

  /// Every branch's own price of [products] (at most 500).
  Future<List<BranchPrice>> prices(List<String> products);

  /// Sets the header's branch's price (`setBranchPriceRequest`).
  Future<void> setPrice(Map<String, dynamic> request);

  /// The header's branch back on the catalog's price (`removeBranchPriceRequest`).
  Future<void> removePrice(Map<String, dynamic> request);
}
