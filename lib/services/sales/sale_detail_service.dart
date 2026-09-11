import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/sales/sale_detail_model.dart';
import 'package:app/toolkit/api.dart';

enum SaleDetailStatus {
  idle,
  loading,
  ready,

  /// The sale is not there any more, which on this screen is its own answer and
  /// not a failure — see [SaleDetailService.missing].
  missing,

  error
}

/// **One sale, opened** (`GET /sales/detail/:ID`).
///
/// It is the row of the board with everything the list leaves out: the lines
/// with their prices and their tax, the totals, how it was paid and what is
/// still owed, where it was rung up or arranged, how far the handover got, and
/// the units the shelf is holding for it.
///
/// **One reference opens all three sources.** The endpoint takes the ticket
/// code, the id the list handed the row, or the chat a purchase is being
/// arranged in, and resolves them to the same sale — a conversation that has
/// since been rung up answers as its ticket. So this asks with
/// [SaleDetailModel.id] and never with a reference it picked by first working
/// out what kind of row it is holding: a client that had to know which of the
/// three it had before it could open it is a client that reimplements the
/// backend's pipeline.
///
/// **It is ephemeral and it caches nothing.** One is created per opened panel
/// and discarded with it: a sale is a measurement of collections that keep
/// moving —the invoice's status, the conversation's cart, the ledger's holds—
/// so a detail kept between two openings is a drawing of a sale as it was.
class SaleDetailService extends ChangeNotifier {
  SaleDetailStatus _status = SaleDetailStatus.idle;

  SaleDetailModel _sale = const SaleDetailModel();

  String _reference = "";

  /// `true` once the panel was closed. The read is awaited by nobody, so it can
  /// land after the panel it was for is gone, and notifying a disposed notifier
  /// is an assert in debug.
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;

    super.dispose();
  }

  SaleDetailStatus get status => _status;

  SaleDetailModel get sale => _sale;

  /// Whether the sale is no longer one.
  ///
  /// The backend answers 404 both for a reference that names nothing and for a
  /// **conversation that stopped being a sale** — the units went back on the
  /// shelf, the customer only ever asked a question — and from this side they
  /// are the same news: the row the board still has cannot be opened because
  /// there is nothing behind it any more. It is said apart from a read that
  /// failed, which is worth retrying and this is not.
  bool get missing => _status == SaleDetailStatus.missing;

  /// The code the backend declined with (`sale_not_found`, `no_inventory_access`).
  /// It is kept for the log and never drawn: the panel writes its own copy.
  String _reason = "";

  String get reason => _reason;

  /// Reads the sale [reference] names. Anything that identifies it to a person
  /// works — see the class doc.
  Future<void> load(String reference) async {
    if (reference.isEmpty) {
      _status = SaleDetailStatus.error;
      _notify();

      return;
    }

    if (_status == SaleDetailStatus.loading && _reference == reference) return;

    _reference = reference;
    _status = SaleDetailStatus.loading;
    _sale = const SaleDetailModel();
    _reason = "";

    _notify();

    dynamic data;

    try {
      // No trailing slash: the reference is a path segment (`params: ["ID"]`),
      // and an extra one would leave it empty on the other side.
      data = await api.get(path: "/sales/detail/$reference", version: "v1");
    } catch (error) {
      if (kDebugMode) print("loadSaleDetail failed: $error");

      // Another sale was asked for while this one was travelling: what arrived
      // belongs to a panel nobody is looking at.
      if (_reference != reference) return;

      _reason = error is Map ? (error["message"] ?? "").toString() : "";
      _status = _reason == _gone
        ? SaleDetailStatus.missing
        : SaleDetailStatus.error;

      _notify();

      return;
    }

    if (_reference != reference) return;

    final sale = data is Map
      ? SaleDetailModel.fromJson(saleFields(data))
      : const SaleDetailModel();

    // A response that does not even name the sale is a failed read, not a panel
    // full of gaps.
    if (sale.isEmpty) {
      _status = SaleDetailStatus.error;
      _notify();

      return;
    }

    _sale = sale;
    _status = SaleDetailStatus.ready;

    _notify();
  }

  /// Reads the same sale again, which is what the panel's retry does.
  Future<void> retry() {
    final reference = _reference;

    _status = SaleDetailStatus.idle;

    return load(reference);
  }

  /// Puts a sale on the table without a read, for the widget tests.
  @visibleForTesting
  void seed(SaleDetailModel sale) {
    _sale = sale;
    _status = sale.isEmpty ? SaleDetailStatus.error : SaleDetailStatus.ready;
  }

  /// The one decline this screen reads rather than reports: both a reference
  /// that names nothing and a conversation that is no longer a sale
  /// (`Pipeline.detail`, reasons `not_found` and `not_sale`) arrive as it.
  static const String _gone = "sale_not_found";

  void _notify() {
    if (_disposed) return;

    notifyListeners();
  }
}
