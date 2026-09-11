import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/pos/pos_cart_line.dart';
import 'package:app/services/pos/pos_invoice_model.dart';
import 'package:app/services/pos/pos_invoice_service.dart';

/// The rules the counter's ticket runs on ([PosInvoiceService]).
///
/// **The ticket is an invoice on the backend now**, so what a tap does cannot be
/// pinned here: it opens a document and holds units, and no test may hit the
/// network. What is pinned instead is everything that happens on this side of
/// that round trip — how the answer becomes what is drawn, and what the panel
/// adds up out of it — which is the half that decides the figure somebody reads
/// out across a counter.
///
/// The seam is [PosInvoiceService.seed]: the invoice as the backend answered it,
/// handed over without asking for it.
PosInvoiceLine _line({
  String lineId = "line-1",
  String? productId = "product-1",
  String name = "Coffee",
  int quantity = 1,
  double price = 10,
  double taxRate = 0
}) => PosInvoiceLine(
  lineId: lineId,
  productId: productId,
  name: name,
  quantity: quantity,
  held: productId == null ? 0 : quantity,
  price: price,
  taxRate: taxRate
);

PosInvoice _invoice(List<PosInvoiceLine> items) => PosInvoice(
  id: "invoice-1",
  ticket: "K7M4-2QX9",
  isOpen: true,
  items: items
);

void main() {
  test('a fresh counter has no ticket and no code', () {
    final cart = PosInvoiceService();

    // Nothing has been rung up, so no invoice was opened and nothing is held
    // anywhere: the code is minted with the first product, not with the screen.
    expect(cart.status, PosInvoiceStatus.idle);
    expect(cart.isEmpty, isTrue);
    expect(cart.ticket, isEmpty);
  });

  test('the invoice that comes back is what the ticket draws', () {
    final cart = PosInvoiceService();

    cart.seed(_invoice([
      _line(lineId: "line-1", name: "Coffee", quantity: 2),
      _line(lineId: "line-2", productId: "product-2", name: "Tea")
    ]));

    // Each line is drawn under the backend's own id: it is what the +/− buttons
    // address, and it is the only thing two charges written the same way have
    // to tell them apart.
    expect(cart.lines.map((line) => line.key), ["line-1", "line-2"]);
    expect(cart.ticket, "K7M4-2QX9");
    // Units and not lines: three of one product is three products to whoever is
    // bagging them.
    expect(cart.units, 3);
  });

  test('the rate is read back off the lines, because the ticket does not carry one', () {
    final cart = PosInvoiceService();

    // Nothing in the business profile or in `/pos/` carries a rate, so a
    // counter that was never told one charges none.
    expect(cart.taxRate, 0);

    cart.seed(_invoice([_line(quantity: 2, price: 100, taxRate: 16)]));

    // The response has no field for the invoice's own rate — every line carries
    // the one it was created with, so the first line's is the ticket's.
    expect(cart.taxRate, 16);
    expect(cart.subtotal, 200);
    expect(cart.tax, closeTo(32, 0.0001));
    expect(cart.total, closeTo(232, 0.0001));
  });

  test('a line that is a charge and not a product is drawn as one', () {
    final cart = PosInvoiceService();

    cart.seed(_invoice([
      _line(lineId: "line-1", name: "Coffee"),
      _line(lineId: "line-2", productId: null, name: "Delivery", price: 5)
    ]));

    final delivery = cart.lines.last;

    expect(delivery.isConcept, isTrue);
    // It came back from the backend, so it has an id and can be edited: only a
    // charge that has not been answered for yet is held back.
    expect(delivery.isPending, isFalse);
    expect(cart.subtotal, 15);
  });

  test('a line drawn before the backend answers is pending', () {
    // A product is editable regardless —it is addressed by its product, and the
    // register asks for "one more of this"— so this is what keeps a typed-in
    // charge from being stepped before it has an id to be pointed at.
    const drafted = PosCartLine(
      key: "${PosCartLine.draft}1",
      label: "Delivery",
      price: 5,
      quantity: 1
    );

    expect(drafted.isPending, isTrue);
    expect(drafted.isConcept, isTrue);

    const answered = PosCartLine(
      key: "line-2",
      label: "Delivery",
      price: 5,
      quantity: 1
    );

    expect(answered.isPending, isFalse);
  });

  test('two charges written the same way are two lines', () {
    final cart = PosInvoiceService();

    cart.seed(_invoice([
      _line(lineId: "line-1", productId: null, name: "Delivery", price: 5),
      _line(lineId: "line-2", productId: null, name: "Delivery", price: 8)
    ]));

    // Collapsing them would lose one of the two prices: they are two things
    // that happened, not one thing counted twice.
    expect(cart.lines.length, 2);
    expect(cart.subtotal, 13);
    expect(cart.lines.every((line) => line.isConcept), isTrue);
  });

  test('a rate outside 0-100 is clamped and not taken', () async {
    final cart = PosInvoiceService();

    // With no lines there is nothing to rewrite, so this is the whole call: the
    // last guard before a total nobody can explain.
    await cart.setTax(-5);
    expect(cart.taxRate, 0);

    await cart.setTax(4000);
    expect(cart.taxRate, PosInvoiceService.maxTax);
  });

  test('discarding a counter that never opened a ticket asks nobody', () async {
    final cart = PosInvoiceService();

    await cart.setTax(16);

    // Nothing is holding anything, so there is no invoice to cancel: it is a
    // local clear and it travels to no one.
    expect(await cart.discard(), isTrue);
    expect(cart.isEmpty, isTrue);
    expect(cart.status, PosInvoiceStatus.idle);
    // The rate is how this till charges, not something about the sale that was
    // just thrown away.
    expect(cart.taxRate, 16);
  });
}
