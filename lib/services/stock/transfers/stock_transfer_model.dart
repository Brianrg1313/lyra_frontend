// SERVICES
import 'package:app/services/catalog/catalog_table.dart';

/// Where a transfer stands (`sedes-frontend.md` §6): `draft` → `sent` → `received`, or
/// `cancelled`.
enum StockTransferStatus {
  /// Written by the sender; moves nothing, and only the sender sees it.
  draft,

  /// The units left the sender and are in no balance: in transit, sold nowhere.
  sent,

  /// The receiver counted them in; what did not arrive was written off.
  received,

  /// A draft dropped, or a shipment called back before it was received (back on the sender's
  /// shelf).
  cancelled;

  static StockTransferStatus? from(dynamic code) =>
    values.asNameMap()[code?.toString().trim().toLowerCase()];
}

/// What a missing unit is written off as when a shipment is received short.
enum StockShortage {
  damage,
  loss,
  theft;

  static StockShortage? from(dynamic code) =>
    values.asNameMap()[code?.toString().trim().toLowerCase()];
}

/// Merchandise moving from one branch of the company to another, as
/// `POST /inventory/stock/transfers/search` and every transfer write answer it.
///
/// The catalog is the company's, so the products are the same ids on both sides: what moves
/// is stock, from one branch's ledger to the other's. The sender drafts, edits, sends and
/// cancels; the receiver receives.
class StockTransfer {
  const StockTransfer({
    required this.id,
    required this.from,
    required this.to,
    required this.status,
    this.tableId = "",
    this.lines = const [],
    this.units = 0,
    this.received,
    this.note = "",
    this.settled = true,
    this.createdAt,
    this.sentAt,
    this.receivedAt,
    this.cancelledAt
  });

  final String id;

  /// The sending and receiving branches' ids.
  final String from;
  final String to;

  final StockTransferStatus status;

  /// The product table its lines are rows of.
  final String tableId;

  final List<StockTransferLine> lines;

  /// Units shipped, every line.
  final int units;

  /// Units counted in, once received; null before.
  final int? received;

  final String note;

  /// False while a write stopped half-way (some lines moved): the backend finishes or undoes it.
  final bool settled;

  final DateTime? createdAt;
  final DateTime? sentAt;
  final DateTime? receivedAt;
  final DateTime? cancelledAt;

  /// When it last moved: what the list says beside it.
  DateTime? get movedAt => switch (status) {
    StockTransferStatus.draft => createdAt,
    StockTransferStatus.sent => sentAt ?? createdAt,
    StockTransferStatus.received => receivedAt ?? sentAt,
    StockTransferStatus.cancelled => cancelledAt ?? createdAt
  };

  /// Whether [branch] sent it (else it is coming to [branch]).
  bool sentBy(String? branch) => from == branch;

  /// The transfer in an answer, or null when it can't be one (no id, no branches, a status this
  /// app doesn't know).
  static StockTransfer? read(dynamic data) {
    if (data is! Map) return null;

    final id = _text(data["id"]);
    final status = StockTransferStatus.from(data["status"]);
    final from = _text(data["from"]);
    final to = _text(data["to"]);

    if (id.isEmpty || status == null || from.isEmpty || to.isEmpty) return null;

    final lines = data["lines"];

    return StockTransfer(
      id: id,
      from: from,
      to: to,
      status: status,
      tableId: _text(data["tableId"]),
      lines: lines is List
        ? [for (final line in lines) ?StockTransferLine.from(line)]
        : const [],
      units: _int(data["units"]) ?? 0,
      received: _int(data["received"]),
      note: _text(data["note"]),
      settled: data["settled"] != false,
      createdAt: _date(data["createdAt"]),
      sentAt: _date(data["sentAt"]),
      receivedAt: _date(data["receivedAt"]),
      cancelledAt: _date(data["cancelledAt"])
    );
  }
}

/// One product of a transfer.
class StockTransferLine {
  const StockTransferLine({
    required this.productId,
    required this.quantity,
    this.sku = "",
    this.received,
    this.shortage
  });

  final String productId;

  /// The product's SKU when the table has one: what a line is read by without its name.
  final String sku;

  /// Units shipped.
  final int quantity;

  /// Units counted in; null until received.
  final int? received;

  /// What the units that didn't arrive were written off as.
  final StockShortage? shortage;

  static StockTransferLine? from(dynamic data) {
    if (data is! Map) return null;

    final product = _text(data["productId"]);
    if (product.isEmpty) return null;

    return StockTransferLine(
      productId: product,
      sku: _text(data["sku"]),
      quantity: _int(data["qty"]) ?? 0,
      received: _int(data["received"]),
      shortage: StockShortage.from(data["shortage"])
    );
  }
}

/// One page of transfers, newest first.
class StockTransfersPage {
  const StockTransfersPage({
    this.total = 0,
    this.page = 1,
    this.size = 50,
    this.transfers = const []
  });

  final int total;
  final int page;
  final int size;
  final List<StockTransfer> transfers;

  factory StockTransfersPage.fromJson(dynamic data) {
    if (data is! Map) return const StockTransfersPage();

    return StockTransfersPage(
      total: _int(data["total"]) ?? 0,
      page: _int(data["page"]) ?? 1,
      size: _int(data["size"]) ?? 50,
      transfers: [
        for (final row in data["transfers"] is List ? data["transfers"] as List : catalogRows(data["transfers"]))
          ?StockTransfer.read(row)
      ]
    );
  }
}

String _text(dynamic value) => value?.toString().trim() ?? "";

int? _int(dynamic value) => switch (value) {
  final num number => number.toInt(),
  final String text => int.tryParse(text.trim()),
  _ => null
};

DateTime? _date(dynamic value) =>
  value == null ? null : DateTime.tryParse(value.toString())?.toLocal();
