import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/pos/pos_invoice_model.dart';

/// Pins the contract of the open invoice: what `POST /pos/invoices/`,
/// `PUT /pos/invoices/items/` and `POST /pos/invoices/close/` answer with, which
/// is the same document at three moments.
///
/// It is worth pinning because none of it is visible from the widget and all of
/// it is money. Three things in particular:
///
/// - **`productId` is legitimately null.** A line that is a charge and not a
///   product (a delivery, a repair) has no catalog row, and reading that null as
///   the string "null" would make the counter treat it as a product it could ask
///   the shelf for.
/// - **`qty` and `held` are two numbers.** What the customer is buying and what
///   the ledger is holding for them are equal in every normal case and come
///   apart when a crash left a hold behind; a client that collapsed them would
///   hide exactly the case somebody has to see.
/// - **`open` is what says whether it is a ticket or a sale.** The closed
///   document carries no such flag, and drawing a charged ticket as one still
///   being built is a sale somebody would add products to.
dynamic _invoice({
  bool open = true,
  List<dynamic> items = const []
}) => {
  "id": "68e2b1c0f0a1b2c3d4e5f600",
  "ticket": "K7M4-2QX9",
  "status": open ? "open" : "completed",
  "channel": "pos",
  "currency": "USD",
  "units": 3,
  "subtotal": 30,
  "tax": 4.8,
  "taxes": const [{"rate": 16, "base": 30, "amount": 4.8}],
  "total": 34.8,
  "payment": open
    ? const {"method": null, "name": null, "reference": null}
    : const {"method": "transfer", "name": "Transferencia", "reference": "0099"},
  "customer": null,
  "note": null,
  "seller": const {"kind": "user", "name": "Ada"},
  "opened": "2026-08-31T10:00:00.000Z",
  "closed": open ? null : "2026-08-31T10:12:00.000Z",
  "items": items,
  if (open) "open": true,
  if (open) "held": 3
};

/// One line of a product, as the backend writes it.
dynamic _line({
  String lineId = "6c2f0a1e-1b3d-4a5f-9c7e-0d1a2b3c4d5e",
  String? productId = "68e2b1c0f0a1b2c3d4e5f601",
  String name = "Coffee",
  int qty = 3,
  int held = 3,
  num price = 10,
  num taxRate = 16
}) => {
  "lineId": lineId,
  "productId": productId,
  "sku": "CF-01",
  "name": name,
  "qty": qty,
  "held": held,
  "price": price,
  "subtotal": price * qty,
  "taxRate": taxRate,
  "tax": price * qty * taxRate / 100,
  "total": price * qty * (100 + taxRate) / 100
};

void main() {
  test('an open invoice decodes with its code, its lines and its money', () {
    final invoice = PosInvoice.fromJson(_invoice(items: [_line()]));

    expect(invoice.isValid, isTrue);
    expect(invoice.id, "68e2b1c0f0a1b2c3d4e5f600");
    // The code exists from the moment it opens and never changes: it is the
    // ticket's name long before anything is paid.
    expect(invoice.ticket, "K7M4-2QX9");
    expect(invoice.isOpen, isTrue);
    expect(invoice.units, 3);
    expect(invoice.subtotal, 30);
    expect(invoice.tax, closeTo(4.8, 0.0001));
    expect(invoice.total, closeTo(34.8, 0.0001));
    expect(invoice.held, 3);
    expect(invoice.items.single.name, "Coffee");
  });

  test('a line that is a charge and not a product carries no product id', () {
    final invoice = PosInvoice.fromJson(_invoice(items: [
      _line(productId: null, name: "Delivery", qty: 1, held: 0, price: 5)
    ]));

    final line = invoice.items.single;

    // Null and not "null": it is what tells a delivery apart from something
    // that came off a shelf, everywhere else on this screen.
    expect(line.productId, isNull);
    expect(line.name, "Delivery");
    // It holds nothing, because there is no shelf to take a delivery off.
    expect(line.held, 0);
  });

  test('what is bought and what is held are read as two numbers', () {
    final invoice = PosInvoice.fromJson(_invoice(items: [
      _line(qty: 5, held: 2)
    ]));

    final line = invoice.items.single;

    // A difference is a hold a crash left behind, which closing repairs. It is
    // kept visible rather than collapsed into one figure.
    expect(line.quantity, 5);
    expect(line.held, 2);
  });

  test('the charged ticket is the same document without the open flag', () {
    final invoice = PosInvoice.fromJson(_invoice(open: false, items: [_line()]));

    expect(invoice.isValid, isTrue);
    expect(invoice.ticket, "K7M4-2QX9");
    // Nothing to add products to any more: it was charged.
    expect(invoice.isOpen, isFalse);
    // How it was paid, in the backend's own words — it is not translated here.
    expect(invoice.paymentName, "Transferencia");
  });

  test('an answer that cannot be read is discarded and not drawn', () {
    // A response that is not an object, or one with no id, is a read that was
    // not understood. Drawing it would be a ticket of holes.
    expect(PosInvoice.fromJson("nope").isValid, isFalse);
    expect(PosInvoice.fromJson(const {"ticket": "K7M4-2QX9"}).isValid, isFalse);
  });
}
