import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/pos/pos_cart_line.dart';
import 'package:app/services/pos/pos_invoice_event.dart';
import 'package:app/services/pos/pos_invoice_model.dart';
import 'package:app/services/pos/pos_invoice_service.dart';
import 'package:app/services/stock/movements/stock_changed_model.dart';

/// **What the counter is told about its own ticket from outside.**
///
/// A ticket is a document, so it can be charged at another register, cancelled
/// from the stock screen, or have the units it was holding given back — and none
/// of that shows up in the invoice this till is drawing. Left unheard, the
/// register finds out when the customer is already paying.
///
/// The seam is [PosInvoiceService.receive]: the event as the socket would have
/// delivered it, handed over without a connection.
PosInvoiceLine _line({
  String lineId = "line-1",
  String? productId = "product-1",
  String name = "Coffee",
  int quantity = 1,
  int? held,
  double price = 10
}) => PosInvoiceLine(
  lineId: lineId,
  productId: productId,
  name: name,
  quantity: quantity,
  held: held ?? (productId == null ? 0 : quantity),
  price: price
);

PosInvoice _invoice(List<PosInvoiceLine> items, {int units = 0, double total = 0}) =>
  PosInvoice(
    id: "invoice-1",
    ticket: "K7M4-2QX9",
    isOpen: true,
    units: units,
    total: total,
    items: items
  );

/// One `stock/changed` notice, which carries the **whole company's** balance for
/// a product after the movement.
Map<String, dynamic> _stock({
  String product = "product-1",
  int reserved = 0,
  int available = 0
}) => {
  "productId": product,
  "table": "table-1",
  "onHand": reserved + available,
  "reserved": reserved,
  "available": available
};

void main() {
  test('a notice says which invoice moved and how much of it there is', () {
    final event = PosInvoiceEvent.fromEvent({
      "id": "invoice-1",
      "ticket": "K7M4-2QX9",
      "units": 3,
      "total": 232.0
    });

    expect(event.isEmpty, isFalse);
    expect(event.id, "invoice-1");
    expect(event.units, 3);
    expect(event.total, 232);

    // Anything that does not name an invoice is discarded rather than acted on:
    // every terminal in the company receives these.
    expect(PosInvoiceEvent.fromEvent(null).isEmpty, isTrue);
    expect(PosInvoiceEvent.fromEvent({"ticket": "K7M4-2QX9"}).isEmpty, isTrue);
  });

  test('a shelf holding less than this ticket alone claims un-holds its lines', () {
    final cart = PosInvoiceService();

    cart.seed(_invoice([_line(quantity: 2)]));

    expect(cart.lines.single.isHeld, isTrue);
    expect(cart.isShort, isFalse);

    // The units were released from the stock screen: the ledger moved and the
    // invoice did not, so re-reading the document would say nothing. What
    // proves it is arithmetic — the company reserves one of these and this
    // ticket alone says it is holding two.
    cart.receive(StockChangedModel.event, _stock(reserved: 1, available: 5));

    expect(cart.lines.single.held, 1);
    expect(cart.lines.single.isHeld, isFalse);
    expect(cart.isShort, isTrue);
    expect(cart.notice, PosTicketNotice.released);
    expect(cart.noticeLabel, "Coffee");

    // What is being charged does not change: the customer asked for two and the
    // backend takes the units again when the ticket is closed, or refuses
    // saying they are gone.
    expect(cart.lines.single.quantity, 2);
    expect(cart.units, 2);
  });

  test('a balance that still covers this ticket changes nothing', () {
    final cart = PosInvoiceService();

    cart.seed(_invoice([_line(quantity: 2)]));

    // Another till released its own hold on the same product: the company's
    // counter fell, and it is still above what this ticket claims.
    cart.receive(StockChangedModel.event, _stock(reserved: 2, available: 4));
    // And a movement on a product that is not on this ticket at all.
    cart.receive(StockChangedModel.event, _stock(product: "product-9"));

    expect(cart.isShort, isFalse);
    expect(cart.notice, isNull);
  });

  test('a charge with no product cannot lose a hold it never had', () {
    final cart = PosInvoiceService();

    cart.seed(_invoice([_line(lineId: "line-2", productId: null, name: "Delivery")]));

    // There is no shelf to take a delivery off, so nothing about the ledger can
    // make it stop being held.
    cart.receive(StockChangedModel.event, _stock(reserved: 0));

    expect(cart.lines.single.isHeld, isTrue);
    expect(cart.isShort, isFalse);
    expect(cart.notice, isNull);
  });

  test('a ticket cancelled somewhere else leaves this counter clean', () {
    final cart = PosInvoiceService();

    cart.seed(_invoice([_line()]));

    cart.receive(PosInvoiceEvent.cancelled, {"id": "invoice-1", "ticket": "K7M4-2QX9"});

    // It is not this counter's to write on any more: going on would be lines
    // travelling to a document that is closed.
    expect(cart.isEmpty, isTrue);
    expect(cart.ticket, isEmpty);
    expect(cart.status, PosInvoiceStatus.idle);
    expect(cart.notice, PosTicketNotice.cancelled);
  });

  test('a ticket charged somewhere else says so, once', () {
    final cart = PosInvoiceService();

    cart.seed(_invoice([_line()]));

    cart.receive(PosInvoiceEvent.closed, {"id": "invoice-1", "ticket": "K7M4-2QX9"});

    expect(cart.notice, PosTicketNotice.charged);

    // The panel says it and clears it: the notice arrives on its own, and a
    // counter rebuilds on every tap.
    cart.clearNotice();

    expect(cart.notice, isNull);
    expect(cart.noticeLabel, isEmpty);
  });

  test('somebody else\'s ticket is somebody else\'s', () {
    final cart = PosInvoiceService();

    cart.seed(_invoice([_line()]));

    // Every terminal in the company receives every invoice notice.
    cart.receive(PosInvoiceEvent.cancelled, {"id": "invoice-7"});
    cart.receive(PosInvoiceEvent.closed, {"id": "invoice-7"});

    expect(cart.isEmpty, isFalse);
    expect(cart.notice, isNull);
  });

  test('a line drawn a tap ahead is drawn as held', () {
    // The write that holds it is already travelling, so the line is drawn the
    // way it is being asked for; the answer is what corrects both numbers.
    const drawn = PosCartLine(
      key: "${PosCartLine.draft}product-1",
      label: "Coffee",
      price: 10,
      quantity: 1,
      productId: "product-1",
      held: 1
    );

    expect(drawn.isHeld, isTrue);
    expect(drawn.withQuantity(2).held, 2);
  });
}
