import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/sales/sale_detail_model.dart';
import 'package:app/services/sales/sale_model.dart';

/// What the sale detail runs on, pinned where the panel cannot show it: the
/// payload is **one shape for three very different sales**, and every distinction
/// that matters in it is a null that a careless parse would turn into a zero, an
/// empty list or a delivery nobody made.
///
/// The three sales below are the three `Pipeline.detail` answers with — a
/// charged ticket, a cart a till still has open, and a purchase the assistant is
/// arranging over a channel — written as the backend writes them.
void main() {
  group('a charged ticket', () {
    final sale = SaleDetailModel.fromJson(_ticket);

    test('reads its document and its stage as two different facts', () {
      // The document knows it was charged; the stage knows the customer is
      // still waiting for the box. A panel that showed one for the other would
      // call a sale finished while it is on a shelf.
      expect(sale.status, "completed");
      expect(sale.stage, "shipping");
      expect(sale.label, "En camino");
      expect(sale.section, SaleSection.process);
      expect(sale.source, SaleSource.ticket);
    });

    test('owes nothing unless it was sold on credit', () {
      // Every other method is money that was there when the ticket was written,
      // so both figures are null and not zero: a "collected: 0" over a cash sale
      // reads as a payment that never came.
      expect(sale.payment.credit, isFalse);
      expect(sale.payment.collected, isNull);
      expect(sale.payment.outstanding, isNull);
      expect(sale.payment.isOwed, isFalse);
    });

    test('has no hold list at all, which is not an empty one', () {
      // A ticket holds its units on its own lines. `null` says there is no list
      // here; `[]` would say the shelf is keeping nothing, which is a different
      // sentence and the one a conversation answers.
      expect(sale.reservations, isNull);
      expect(sale.held, 0);
    });

    test('carries the handover and who said so', () {
      final handover = sale.handover;

      expect(handover, isNotNull);
      expect(handover!.mode, "delivery");
      expect(handover.stateName, "Despachado");
      expect(handover.by, "Ana");
      expect(handover.isDelivered, isFalse);
      // Somebody filled the form in: the difference between a driver who went
      // out and a reading the backend inferred.
      expect(handover.stored, isTrue);
    });

    test('breaks the tax down by rate', () {
      expect(sale.taxes.length, 2);
      expect(sale.taxes.first.rate, 0);
      expect(sale.taxes.last.rate, 16);
      expect(sale.taxes.last.amount, 16);
    });

    test('keeps a line that is not a product apart from one that is', () {
      final delivery = sale.items.last;

      // A line pointing at no catalog row is exactly what tells a delivery
      // charge from an item that came off the shelf.
      expect(delivery.productId, isEmpty);
      expect(sale.items.first.productId, "p1");
    });
  });

  group('a cart the till still has open', () {
    final sale = SaleDetailModel.fromJson(_invoice);

    test('is priced and still has nothing to hand over', () {
      // It has not been charged, so nothing has left the shelf for good and
      // there is no handover to be at a point of.
      expect(sale.source, SaleSource.invoice);
      expect(sale.isOpen, isTrue);
      expect(sale.total, 58);
      expect(sale.handover, isNull);
    });

    test('holds the units it is about to sell', () {
      // `held` equals the units while the invoice is open and is zero once it is
      // charged: those units are sold, not held.
      expect(sale.held, 4);
      expect(sale.units, 4);
    });
  });

  group('a purchase being arranged over a channel', () {
    final sale = SaleDetailModel.fromJson(_deal);

    test('is worth nothing said rather than nothing at all', () {
      // Nobody has priced it and nobody has rung it up. A `0` in either place
      // would claim the sale is worth nothing and that it is tax-free — two
      // statements nobody made.
      expect(sale.isDeal, isTrue);
      expect(sale.total, isNull);
      expect(sale.subtotal, isNull);
      expect(sale.tax, isNull);
      expect(sale.taxes, isEmpty);
      expect(sale.ticket, isEmpty);
      expect(sale.seller, isEmpty);
      expect(sale.handover, isNull);
    });

    test('is named by its conversation', () {
      // A chat is what a person opens, so it is what names the row.
      expect(sale.id, "c9");
      expect(sale.chat, "c9");
      expect(sale.contact, "584140000000");
    });

    test('answers an empty hold list, which a ticket does not', () {
      // The shelf is keeping nothing for this customer — said, not absent.
      expect(sale.reservations, isNotNull);
      expect(sale.reservations, isEmpty);
      expect(sale.held, 0);
    });

    test('sees the gap between what was promised and what is held', () {
      final promised = sale.items.first;
      final honest = sale.items.last;

      // The cart entry says these units are the customer's; the ledger holds
      // none. It is a hold that lapsed or was released, and it is the thing to
      // see before promising the last one to somebody else.
      expect(promised.state, "reserved");
      expect(promised.held, 0);
      expect(promised.isUnheld, isTrue);

      expect(honest.held, 2);
      expect(honest.isUnheld, isFalse);
    });

    test('keeps a line nobody could price out of the total', () {
      expect(sale.items.last.price, isNull);
      expect(sale.items.last.isPriced, isFalse);
    });
  });

  group('what is missing', () {
    test('a body that does not name the sale is not a detail', () {
      // It is a failed read and not a panel full of gaps.
      expect(SaleDetailModel.fromJson(const {}).isEmpty, isTrue);
      expect(const SaleDetailModel().isEmpty, isTrue);
    });

    test('an origin with nothing in it draws no rows', () {
      // A sale too old to carry the block answers with its channel alone, which
      // the panel already says one row up.
      final bare = SaleOriginModel.fromJson(const {
        "kind": "channel",
        "channel": "whatsapp",
        "terminal": null,
        "bot": null
      });

      expect(bare.isEmpty, isTrue);
    });
  });
}

/// A charged ticket on its way to the customer.
const Map<String, dynamic> _ticket = {
  "id": "s1",
  "source": "ticket",
  "ticket": "K7M4-2QX9",
  "status": "completed",
  "stage": "shipping",
  "label": "En camino",
  "section": "process",
  "level": "info",
  "attention": true,
  "since": "2026-09-08T14:00:00.000Z",
  "channel": "pos",
  "origin": {
    "kind": "terminal",
    "channel": "pos",
    "terminal": "Caja 1",
    "bot": null
  },
  "customer": {"name": "Luis", "contact": "584120000000"},
  "chat": null,
  "seller": {"kind": "user", "name": "Ana"},
  "currency": "USD",
  "units": 3,
  "subtotal": 100,
  "tax": 16,
  "taxes": [
    {"rate": 0, "base": 0, "amount": 0},
    {"rate": 16, "base": 100, "amount": 16}
  ],
  "total": 116,
  "payment": {
    "method": "cash",
    "name": "Efectivo",
    "reference": null,
    "credit": false,
    "collected": null,
    "outstanding": null
  },
  "fulfillment": {
    "mode": "delivery",
    "modeName": "Envio a domicilio",
    "state": "dispatched",
    "stateName": "Despachado",
    "at": "2026-09-08T15:00:00.000Z",
    "by": "Ana",
    "note": "TRK-9911",
    "stored": true
  },
  "held": 0,
  "reservations": null,
  "items": [
    {
      "lineId": "l1",
      "productId": "p1",
      "sku": "SKU-1",
      "name": "Teclado",
      "qty": 2,
      "price": 40,
      "subtotal": 80,
      "taxRate": 16,
      "tax": 12.8,
      "total": 92.8,
      "held": 0
    },
    {
      "lineId": "l2",
      "productId": null,
      "sku": null,
      "name": "Envio",
      "qty": 1,
      "price": 20,
      "subtotal": 20,
      "taxRate": 0,
      "tax": 0,
      "total": 20,
      "held": 0
    }
  ],
  "opened": "2026-09-08T13:40:00.000Z",
  "closed": "2026-09-08T14:00:00.000Z",
  "date": "2026-09-08T14:00:00.000Z",
  "updated": "2026-09-08T15:00:00.000Z"
};

/// A cart a till is still building.
const Map<String, dynamic> _invoice = {
  "id": "s2",
  "source": "invoice",
  "ticket": "A1B2-C3D4",
  "status": "open",
  "stage": "uncharged",
  "label": "Ticket abierto",
  "section": "process",
  "level": "warning",
  "attention": true,
  "since": "2026-09-09T09:00:00.000Z",
  "channel": "pos",
  "customer": {"name": null, "contact": null},
  "seller": {"kind": "user", "name": "Ana"},
  "currency": "USD",
  "units": 4,
  "subtotal": 50,
  "tax": 8,
  "taxes": [
    {"rate": 16, "base": 50, "amount": 8}
  ],
  "total": 58,
  "payment": {"method": null, "name": null, "reference": null, "credit": false},
  // Not charged: nothing has left the shelf for good, so there is no handover.
  "fulfillment": null,
  "held": 4,
  "reservations": null,
  "items": [
    {
      "productId": "p1",
      "sku": "SKU-1",
      "name": "Teclado",
      "qty": 4,
      "price": 12.5,
      "subtotal": 50,
      "taxRate": 16,
      "tax": 8,
      "total": 58,
      "held": 4
    }
  ],
  "opened": "2026-09-09T09:00:00.000Z",
  "closed": null,
  "date": null,
  "updated": "2026-09-09T09:20:00.000Z"
};

/// A purchase the assistant is in the middle of.
const Map<String, dynamic> _deal = {
  "id": "c9",
  "source": "chat",
  "ticket": null,
  "status": null,
  "stage": "reserving",
  "label": "Apartando",
  "section": "process",
  "level": "info",
  "attention": false,
  "since": "2026-09-09T08:00:00.000Z",
  "channel": "whatsapp",
  "origin": {
    "kind": "channel",
    "channel": "whatsapp",
    "terminal": null,
    "bot": null
  },
  "customer": {"name": "Marta", "contact": "584140000000"},
  "chat": "c9",
  "seller": null,
  "currency": null,
  "units": 3,
  "subtotal": null,
  "tax": null,
  "taxes": [],
  "total": null,
  "payment": {
    "method": "pago_movil",
    "name": "Pago Movil",
    "reference": null,
    "credit": false,
    "collected": null,
    "outstanding": null
  },
  "fulfillment": null,
  "held": 0,
  "reservations": [],
  "items": [
    {
      "productId": "p1",
      "table": "t1",
      "sku": "SKU-1",
      "name": "Teclado",
      "qty": 1,
      "price": 40,
      "list": 50,
      "subtotal": 40,
      "taxRate": null,
      "tax": null,
      "total": 40,
      "held": 0,
      "state": "reserved",
      "available": 3,
      "gone": false
    },
    {
      "productId": "p2",
      "table": "t1",
      "sku": null,
      "name": "Mouse",
      "qty": 2,
      "price": null,
      "subtotal": null,
      "total": null,
      "held": 2,
      "state": "reserved",
      "available": null,
      "gone": true
    }
  ],
  "opened": "2026-09-09T08:00:00.000Z",
  "closed": null,
  "date": "2026-09-09T08:00:00.000Z",
  "updated": "2026-09-09T08:30:00.000Z"
};
