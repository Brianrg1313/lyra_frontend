/// The `stock/changed` notice: a product's balance moved, and every screen
/// looking at that shelf is being told as it happens.
///
/// **It is emitted by the ledger and not by an endpoint**, which is why one
/// notice covers every way stock moves: a restock, a sale, a hold placed by an
/// open invoice at another till, a bot's reservation. Whoever listens does not
/// have to know which call caused it — only that these are the numbers now.
///
/// That is what keeps two tills from promising the same last unit: the moment a
/// product goes on somebody's ticket its units leave [available], and a counter
/// that only refreshed on reload would go on offering them. The backend refuses
/// the sale anyway (the hold is guarded), but a grid that says there are three
/// left when there are none is a customer being told something that is not true.
///
/// It carries the balance **after** the movement, so nothing has to be added up
/// here: the numbers are read and written down as they arrive.
class StockChangedModel {
  /// Name of the event on the socket. A contract handwritten on both sides, so
  /// it lives in one constant: a misspelled event does not fail, it just never
  /// arrives.
  static const String event = "stock/changed";

  const StockChangedModel({
    this.productId = "",
    this.table = "",
    this.onHand = 0,
    this.reserved = 0,
    this.available = 0
  });

  /// The product whose balance moved. Empty when the notice could not be read,
  /// which is the only way to discard it.
  final String productId;

  /// The table the product belongs to. It is what lets a screen ignore a
  /// movement on a catalog it is not showing.
  final String table;

  /// Units physically on the shelf, held ones included.
  final int onHand;

  /// Units promised to someone: an open ticket at any till, a reservation.
  final int reserved;

  /// **Units left to sell**, which is the number a counter draws. It is
  /// [onHand] minus [reserved], already computed by the ledger.
  final int available;

  factory StockChangedModel.fromEvent(dynamic data) {
    if (data is! Map) return const StockChangedModel();

    return StockChangedModel(
      productId: (data["productId"] ?? data["product_id"] ?? "").toString(),
      table: (data["table"] ?? data["table_id"] ?? "").toString(),
      onHand: _count(data["onHand"]),
      reserved: _count(data["reserved"]),
      available: _count(data["available"])
    );
  }

  /// Whether the notice names a product that can be updated.
  bool get isEmpty => productId.isEmpty;

  static int _count(dynamic value) => switch (value) {
    final num number => number.toInt(),
    final String text => int.tryParse(text) ?? 0,
    _ => 0
  };
}
