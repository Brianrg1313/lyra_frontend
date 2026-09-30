// SERVICES
import 'package:app/services/sales/sale_channel_model.dart';
import 'package:app/services/sales/sale_detail_model.dart';
import 'package:app/services/sales/sale_model.dart';
import 'package:app/services/sales/sale_stage_model.dart';

/// The sales board, one sale opened, and the vocabularies the screen is built
/// from (`docs/offline/specs/sales.md`).
///
/// Throws the normalised error (`{message, action}`). A model that reads a broken
/// answer as not loaded (`SalesPage.isLoaded`, `SaleDetailModel.isEmpty`) is
/// answered as is: its service already tells that apart.
abstract interface class SalesSource {
  /// One page of [section], filtered by [stage] and [channel] (empty = any),
  /// and to the signed-in person's with [mine].
  Future<SalesPage> page({
    required SaleSection section,
    String stage = "",
    String channel = "",
    bool mine = false,
    required int page,
    required int size
  });

  /// Records a handover step ([request]: a `sale_fulfillment_request.dart` body);
  /// answers the sale as it now reads, when the answer carries it.
  Future<SaleModel?> fulfil(Map<String, dynamic> request);

  /// Approves the payment of the sale arranged in conversation [chat]. Cloud only.
  Future<void> approve(String chat);

  /// One sale by any of its references: ticket code, row id or chat.
  Future<SaleDetailModel> detail(String reference);

  Future<SaleStagesCatalog> stages();

  /// Where a sale can come in through.
  Future<List<SaleChannel>> channels();
}
