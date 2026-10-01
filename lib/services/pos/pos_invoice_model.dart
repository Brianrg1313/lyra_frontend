/// One line of an invoice, as the backend answers it.
///
/// It is what is being charged and what the ledger is holding for it, which are
/// two numbers and not one: [quantity] is what the customer is buying and [held]
/// is what has actually been taken off the shelf for them. They are equal in
/// every normal case — a difference is a hold a crash left behind, which the
/// backend repairs when the ticket is charged.
///
/// [productId] is null on a charge that is not a product (a delivery, a repair):
/// those hold nothing, so [held] stays at zero on them.
class PosInvoiceLine {
  const PosInvoiceLine({
    required this.lineId,
    this.productId,
    this.name = "",
    this.sku = "",
    this.quantity = 0,
    this.held = 0,
    this.price = 0,
    this.taxRate = 0,
    this.total = 0,
    this.tracked = true
  });

  /// Identity of the line **within the invoice**, minted by the backend. It is
  /// what every edit addresses, because a product can be pointed at by its id
  /// and two charges written the same way cannot.
  final String lineId;

  /// The catalog record being sold, or null on a charge typed in by hand.
  final String? productId;

  /// What is written on the ticket, frozen when the line was created.
  final String name;

  final String sku;

  /// Units the customer is buying.
  final int quantity;

  /// Units the ledger is holding for this line. Zero on a charge that is not a
  /// product: there is no shelf to take anything off.
  final int held;

  /// Unit price agreed when the line was created. The backend keeps it from
  /// then on, so a ticket charges what the customer was quoted.
  final double price;

  /// Percentage this line is taxed at.
  final double taxRate;

  /// What the line comes to, tax included. Derived by the backend from the
  /// three above on every read.
  final double total;

  /// Whether the product's stock is counted, so [held] means something. A
  /// master answers false for a product whose table counts no stock (`pos.md`
  /// POS-6); the cloud counts every product and never sends it.
  final bool tracked;

  factory PosInvoiceLine.fromJson(Map<String, dynamic> data) => PosInvoiceLine(
    lineId: (data["lineId"] ?? "").toString(),
    // Null and not empty: it is what tells a delivery charge apart from
    // something that came off a shelf, everywhere else on this screen.
    productId: data["productId"]?.toString(),
    name: data["name"]?.toString() ?? "",
    sku: data["sku"]?.toString() ?? "",
    quantity: _int(data["qty"]),
    held: _int(data["held"]),
    price: _double(data["price"]),
    taxRate: _double(data["taxRate"]),
    total: _double(data["total"]),
    tracked: data["tracked"] != false
  );

  static int _int(dynamic raw) => switch (raw) {
    final num value => value.toInt(),
    final String text => int.tryParse(text) ?? 0,
    _ => 0
  };

  static double _double(dynamic raw) => switch (raw) {
    final num value => value.toDouble(),
    final String text => double.tryParse(text) ?? 0,
    _ => 0
  };
}

/// A ticket as the backend holds it: the open invoice being built at the
/// counter, and the finished sale it becomes when it is charged.
///
/// **They are the same document at two moments**, which is why they are one
/// model: same id, same code, same lines. [isOpen] is what tells them apart —
/// an open one still holds its units, a closed one has sold them.
///
/// The money is never sent up, only read back: the backend prices the lines and
/// refuses to take a total from the client at all (see the endpoint), so every
/// figure here is the one that was or will be charged.
class PosInvoice {
  const PosInvoice({
    this.id = "",
    this.ticket = "",
    this.isOpen = false,
    this.units = 0,
    this.subtotal = 0,
    this.tax = 0,
    this.total = 0,
    this.held = 0,
    this.paymentName = "",
    this.items = const []
  });

  /// Internal id. It is what every write addresses; the code is what people say.
  final String id;

  /// The ticket code (`K7M4-2QX9`). **It exists from the moment the invoice is
  /// opened** and never changes, so it can be read out and printed on a
  /// provisional slip long before anything is paid.
  final String ticket;

  /// Whether it is still being built. False on the ticket a checkout answers
  /// with, which is the same document already charged.
  final bool isOpen;

  final int units;
  final double subtotal;
  final double tax;
  final double total;

  /// Units the ledger is holding for the whole invoice. It equals [units] minus
  /// whatever is on lines that hold nothing (the typed-in charges).
  final int held;

  /// How it was paid, in the backend's own words (`Efectivo`, `Transferencia`).
  /// Empty while the invoice is open, because nothing has been paid yet.
  final String paymentName;

  final List<PosInvoiceLine> items;

  bool get isEmpty => items.isEmpty;

  factory PosInvoice.fromJson(dynamic data) {
    if (data is! Map) return const PosInvoice();

    final payment = data["payment"];
    final items = data["items"];

    return PosInvoice(
      id: (data["id"] ?? "").toString(),
      ticket: (data["ticket"] ?? "").toString(),
      // The backend says `open` on an invoice and `status` on both. The flag is
      // read first because a closed invoice does not carry it at all.
      isOpen: data["open"] == true,
      units: PosInvoiceLine._int(data["units"]),
      subtotal: PosInvoiceLine._double(data["subtotal"]),
      tax: PosInvoiceLine._double(data["tax"]),
      total: PosInvoiceLine._double(data["total"]),
      held: PosInvoiceLine._int(data["held"]),
      paymentName: payment is Map ? payment["name"]?.toString() ?? "" : "",
      items: items is List
        ? [
            for (final line in items)
              if (line is Map) PosInvoiceLine.fromJson(Map<String, dynamic>.from(line))
          ]
        : const []
    );
  }

  /// Whether the answer could be read at all. An invoice with no id is a
  /// response that was not understood, and it is discarded rather than drawn.
  bool get isValid => id.isNotEmpty;
}
