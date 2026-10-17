// SERVICES
import 'package:app/services/stock/movements/stock_movement_model.dart' show stockNum;

/// The dish or batch a supply moved for (`for`, `cocina-frontend.md` §10): [qty] units of
/// [productId], with what a batch lost.
typedef StockLedgerFor = ({String productId, num qty, num waste, num lost});

/// How a restock was bought, as the presentation was that day (`pack`): [count] of [name],
/// each holding [qty].
typedef StockLedgerPack = ({String id, String name, num qty, num count});

/// One line of a product's ledger (`POST /inventory/stock/movements`): what moved, why, who
/// moved it and what was left.
///
/// [qty] always comes positive; which way it went is the operation's and the reason's
/// ([sign]), the same table `models/inventory/reasons.js` decides the counters with.
class StockLedgerEntry {
  const StockLedgerEntry({
    required this.id,
    required this.operation,
    required this.reason,
    required this.qty,
    this.note = "",
    this.actorKind = "system",
    this.actorName,
    this.madeFor,
    this.pack,
    this.cost,
    this.available,
    this.date
  });

  final String id;

  /// `add` · `remove` · `return` · `reserve` · `unreserve` · `reservation` · `transfer` · `recipe`.
  final String operation;
  final String reason;
  final num qty;
  final String note;

  /// `user` with their name now (null: the account is gone), or what wrote it otherwise.
  final String actorKind;
  final String? actorName;

  final StockLedgerFor? madeFor;
  final StockLedgerPack? pack;

  /// What the whole purchase cost: a restock's, null on anything else.
  final double? cost;

  /// What was left to sell after it (`balance.available`).
  final num? available;
  final DateTime? date;

  /// +1 when units reached the shelf, -1 when they left it, 0 when they only changed counter
  /// (a hold, a return waiting to be checked) or never reached it (a batch's waste, a
  /// transfer's shortfall).
  int get sign => switch ((operation, reason)) {
    ("add", _) => 1,
    ("remove", "discard") => 0,
    ("remove", _) => -1,
    ("reservation", "commit") => -1,
    ("transfer", "transfer_out") => -1,
    ("transfer", "transfer_in" || "transfer_back") => 1,
    ("recipe", "production") => 1,
    ("recipe", "consumption" || "consumed" || "ingredient" || "spoiled") => -1,
    _ => 0
  };

  factory StockLedgerEntry.fromJson(Map<String, dynamic> data) {
    final actor = data["actor"] is Map ? data["actor"] as Map : const {};
    final made = data["for"] is Map ? data["for"] as Map : null;
    final pack = data["pack"] is Map ? data["pack"] as Map : null;
    final balance = data["balance"] is Map ? data["balance"] as Map : null;
    final cost = data["cost"];

    return StockLedgerEntry(
      id: (data["id"] ?? "").toString(),
      operation: (data["operation"] ?? "").toString(),
      reason: (data["reason"] ?? "").toString(),
      qty: (stockNum(data["qty"]) ?? 0).abs(),
      note: (data["note"] ?? "").toString().trim(),
      actorKind: (actor["kind"] ?? "system").toString(),
      actorName: actor["name"]?.toString(),
      madeFor: made == null ? null : (
        productId: (made["productId"] ?? "").toString(),
        qty: stockNum(made["qty"]) ?? 0,
        waste: stockNum(made["waste"]) ?? 0,
        lost: stockNum(made["lost"]) ?? 0
      ),
      pack: pack == null ? null : (
        id: (pack["id"] ?? "").toString(),
        name: (pack["name"] ?? "").toString(),
        qty: stockNum(pack["qty"]) ?? 0,
        count: stockNum(pack["count"]) ?? 0
      ),
      cost: cost is num ? cost.toDouble() : null,
      available: balance == null ? null : stockNum(balance["available"]),
      date: DateTime.tryParse((data["date"] ?? "").toString())
    );
  }
}

/// A page of the ledger, newest first, and how many lines it has in all.
class StockLedgerPage {
  const StockLedgerPage({this.entries = const [], this.total = 0});

  final List<StockLedgerEntry> entries;
  final int total;

  factory StockLedgerPage.fromJson(dynamic data) {
    if (data is! Map) return const StockLedgerPage();

    final raw = data["movements"] is List ? data["movements"] as List : const [];
    final entries = [
      for (final item in raw)
        if (item is Map) StockLedgerEntry.fromJson(Map<String, dynamic>.from(item))
    ];

    return StockLedgerPage(entries: entries, total: (stockNum(data["total"]) ?? entries.length).toInt());
  }
}
