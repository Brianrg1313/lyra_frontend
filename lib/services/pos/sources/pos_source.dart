// SERVICES
import 'package:app/services/pos/pos_invoice_model.dart';
import 'package:app/services/pos/pos_payment_method.dart';
import 'package:app/services/pos/pos_product_model.dart';

/// The counter: the day's summary, the catalogue, how a sale is paid and the
/// open ticket (`docs/offline/specs/pos.md`).
///
/// Throws the normalised error (`{message, action}`), or `UnreadableAnswer` for an
/// answer its model can't read. `no_primary_table` is the message of a company
/// with nothing to sell from yet.
abstract interface class PosSource {
  /// How many sales the person signed in completed today, and the categories
  /// of the catalogue, in the order they come.
  Future<({int mineSales, List<String> categories})> summary();

  /// Every payment method the server knows, valid or not: the service filters.
  Future<List<PosPaymentMethod>> methods();

  /// One page of the primary table's products, by cursor.
  Future<PosCatalogPage> catalog({
    required int size,
    String cursor = "",
    String search = "",
    String category = ""
  });

  /// The company's open tickets, as the server orders them; only the signed-in
  /// person's with [mine].
  Future<List<PosInvoice>> openInvoices({bool mine = false, required int size});

  /// Opens a ticket whose lines default to [tax] percent.
  Future<PosInvoice> open({required double tax});

  /// Writes one line change ([body]: the line's keys) on ticket [id]; answers
  /// the ticket as it ended up.
  Future<PosInvoice> writeLine(String id, Map<String, dynamic> body);

  /// Charges ticket [id]; answers the sealed sale.
  Future<PosInvoice> close(
    String id, {
    required String method,
    String reference = "",
    String note = ""
  });

  /// Cancels ticket [id], releasing its holds.
  Future<void> cancel(String id);
}
