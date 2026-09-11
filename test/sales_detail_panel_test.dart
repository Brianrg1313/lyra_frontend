import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/sales/sale_detail_model.dart';
import 'package:app/services/sales/sales_catalog_service.dart';
import 'package:app/screens/modals/sales/sale_detail/detail_handover.dart';
import 'package:app/screens/modals/sales/sale_detail/detail_items.dart';
import 'package:app/screens/modals/sales/sale_detail/detail_money.dart';
import 'package:app/screens/modals/sales/sale_detail/detail_trace.dart';

/// **That the sale panel draws all three sales at all.**
///
/// One shape for a charged ticket, a cart a till still has open and a purchase
/// being arranged is what makes the panel worth having, and it is also what
/// makes it easy to break: half the fields of any one of them are null, and a
/// block written against the source it was tested on renders the other two with
/// a blank where a sentence should be — or throws in a layout somebody only
/// meets in production.
///
/// So the blocks are mounted in a real panel width with the three payloads, and
/// the checks are the sentences a missing figure has to be said with. The panel
/// itself is not mounted: it reads on its first frame, and **no test may hit
/// the network**.
void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  testWidgets('a charged ticket draws its money, its lines and its handover',
    (tester) async {
      final sale = SaleDetailModel.fromJson(_ticket);

      await _pump(tester, sale);

      // The stage and the handover are two different sentences, and the panel
      // says the second one as the backend worded it.
      expect(find.text("Despachado"), findsOneWidget);
      expect(find.text("Envio a domicilio"), findsOneWidget);
      // Recorded by somebody, so the caveat is not drawn.
      expect(
        find.text(S.current.sales_detail_handover_unstored),
        findsNothing
      );
      // A ticket holds nothing: there is no hold list, so no block for it.
      expect(find.byType(SaleDetailHolds), findsNothing);
      // The lines are a panel of their own now, so what the block owes is the
      // count and the way in — the product's name lives one panel over.
      expect(find.text(S.current.sales_detail_items_open), findsOneWidget);
      expect(find.text("Teclado"), findsNothing);
      expect(tester.takeException(), isNull);
    }
  );

  testWidgets('a cart nobody has charged says why nothing is handed over',
    (tester) async {
      await _pump(tester, SaleDetailModel.fromJson(_invoice));

      // Otherwise an empty handover block reads as a delivery somebody forgot.
      expect(
        find.text(S.current.sales_detail_handover_none),
        findsOneWidget
      );
      expect(
        find.text(S.current.sales_detail_handover_none_open),
        findsOneWidget
      );
      expect(tester.takeException(), isNull);
    }
  );

  testWidgets('a purchase nobody priced says so instead of showing a zero',
    (tester) async {
      await _pump(tester, SaleDetailModel.fromJson(_deal));

      // The total and the tax are the two figures a conversation does not have,
      // and `0,00` in either place is a claim nobody made.
      expect(
        find.text(S.current.sales_detail_unpriced),
        findsWidgets
      );
      expect(find.text(S.current.sales_detail_untaxed), findsOneWidget);
      // The shelf is keeping nothing for this customer — said, not absent.
      expect(find.byType(SaleDetailHolds), findsOneWidget);
      expect(
        find.text(S.current.sales_detail_holds_empty),
        findsOneWidget
      );
      // The units the customer was promised and the ones the ledger holds
      // disagree, which is the flag the panel exists to raise — counted on the
      // block, because a warning nobody meets until they open the list is the
      // one warning that had to stay out here.
      expect(
        find.text(S.current.sales_detail_items_unheld_count(1)),
        findsOneWidget
      );
      expect(tester.takeException(), isNull);
    }
  );
}

/// The blocks of the panel, in a box the width the panel opens at.
Future<void> _pump(WidgetTester tester, SaleDetailModel sale) async {
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: Builder(builder: (context) {
      AppSize.instance(context);

      // A `Column` in a scroll and not a `ListView`: the panel is read whole,
      // and a lazy list would leave the blocks below the fold unbuilt — which
      // is exactly where a block that cannot draw a null would be.
      return Scaffold(body: SizedBox(
        width: 460,
        child: SingleChildScrollView(child: Column(children: [
          SaleDetailMoney(sale: sale),
          SaleDetailItems(sale: sale),
          SaleDetailHandover(sale: sale),
          if (sale.reservations != null) SaleDetailHolds(sale: sale),
          SaleDetailTrace(sale: sale, catalog: SalesCatalogService())
        ]))
      ));
    })
  ));

  await tester.pump();
}

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
  "seller": {"kind": "user", "name": "Ana"},
  "currency": "USD",
  "units": 3,
  "subtotal": 100,
  "tax": 16,
  "taxes": [
    {"rate": 16, "base": 100, "amount": 16}
  ],
  "total": 116,
  "payment": {
    "method": "cash",
    "name": "Efectivo",
    "reference": null,
    "credit": false
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
    }
  ],
  "opened": "2026-09-08T13:40:00.000Z",
  "closed": "2026-09-08T14:00:00.000Z",
  "updated": "2026-09-08T15:00:00.000Z"
};

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
  "opened": "2026-09-09T09:00:00.000Z"
};

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
  "channel": "whatsapp",
  "customer": {"name": "Marta", "contact": "584140000000"},
  "chat": "c9",
  "seller": null,
  "currency": null,
  "units": 1,
  "subtotal": null,
  "tax": null,
  "taxes": [],
  "total": null,
  "payment": {
    "method": "pago_movil",
    "name": "Pago Movil",
    "reference": null,
    "credit": false
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
      "price": null,
      "subtotal": null,
      "total": null,
      "held": 0,
      "state": "reserved",
      "gone": false
    }
  ],
  "opened": "2026-09-09T08:00:00.000Z"
};
