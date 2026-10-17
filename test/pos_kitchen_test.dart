import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/catalog/currency_model.dart';
import 'package:app/services/kitchen/modifier_model.dart';
import 'package:app/services/pos/pos_cart_line.dart';
import 'package:app/services/pos/pos_invoice_model.dart';
import 'package:app/services/pos/pos_invoice_service.dart';
import 'package:app/services/pos/pos_product_model.dart';
import 'package:app/services/pos/sources/pos_source.dart';
import 'package:app/screens/modals/pos/pos_modifiers/_pos_modifiers.dart';
import 'package:app/screens/pos/desktop/ticket_line.dart';

/// Selling a dish at the till (`cocina-frontend.md` §5–6): a line reads what it goes without
/// and what was chosen on it, a product rung up with modifiers sends them, a short negotiable
/// side keeps the refused write to send again with `WITHOUT` (or forget it), and the picker
/// doesn't let a group be confirmed outside its `min`–`max` nor pick an option with none left.
void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFffffff));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  const burger = PosProduct(id: "burger", name: "Burger", price: 8, stock: 5, reserved: 0);

  test("a line reads what it goes without and what was chosen on it", () {
    final line = PosInvoiceLine.fromJson({
      "lineId": "l", "productId": "burger", "qty": 1, "held": 1, "price": 9,
      "without": ["r-fries"], "omitted": [{"id": "r-fries", "name": "Fries"}],
      "modifiers": [{"group": "g", "option": "o", "name": "Cheese", "price": 1}]
    });

    expect(line.without, ["r-fries"]);
    expect(line.omitted.single.name, "Fries");
    expect(line.modifiers.single.price, 1);
    expect(PosInvoiceLine.fromJson({"lineId": "x", "qty": 1}).modifiers, isEmpty);
  });

  test("a product rung up with modifiers sends them, every unit of the line", () async {
    final source = _Source();
    final ticket = PosInvoiceService(source: source);
    addTearDown(ticket.dispose);

    await ticket.add(burger, modifiers: const [(group: "g", option: "o")]);

    expect(source.bodies.single["MODIFIERS"], [{"GROUP": "g", "OPTION": "o"}]);
    expect(ticket.carries("burger"), isTrue);

    await ticket.add(burger);
    expect(source.bodies.last.containsKey("MODIFIERS"), isFalse);
  });

  test("a short side keeps the refused write; taking it without sends it again with WITHOUT", () async {
    final source = _Source(refuse: {"message": "negotiable_short", "action": "confirm_without"});
    final ticket = PosInvoiceService(source: source);
    addTearDown(ticket.dispose);

    expect(await ticket.add(burger), isFalse);
    expect(ticket.short!.productId, "burger");

    source.refuse = null;
    expect(await ticket.confirmWithout(["r-fries"]), isTrue);
    expect(source.bodies.last["WITHOUT"], ["r-fries"]);
    expect(source.bodies.last["ADD"], 1);
    expect(ticket.short, isNull);

    source.refuse = {"message": "negotiable_short", "action": "confirm_without"};
    await ticket.add(burger);
    ticket.dropShort();
    expect(ticket.short, isNull);
    expect(ticket.error, isNull);
  });

  test("a refusal for modifiers asks for them; another one isn't a short side", () async {
    final source = _Source(refuse: {"message": "invalid_modifiers", "action": null});
    final ticket = PosInvoiceService(source: source);
    addTearDown(ticket.dispose);

    await ticket.add(burger);

    expect(ticket.asksModifiers, isTrue);
    expect(ticket.short, isNull);
  });

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

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
        return Scaffold(body: Center(child: child));
      })
    ));
    await tester.pumpAndSettle();
  }

  testWidgets("the picker waits for a required group and greys out what is left of none", (tester) async {
    await pump(tester, const PosModifiersModal(currency: _currency, groups: [
      ModifierGroup(id: "d", name: "Doneness", min: 1, max: 1, options: [
        ModifierOption(id: "m", name: "Medium"),
        ModifierOption(id: "w", name: "Well done")
      ]),
      ModifierGroup(id: "x", name: "Extras", options: [
        ModifierOption(id: "c", name: "Cheese", price: 1, available: 0)
      ])
    ]));

    expect(tester.takeException(), isNull);
    expect(find.text("Choose one"), findsOneWidget);

    bool ignoring() => tester.widget<IgnorePointer>(find.ancestor(
      of: find.text("Add to the ticket"),
      matching: find.byType(IgnorePointer)
    ).first).ignoring;

    expect(ignoring(), isTrue);

    await tester.tap(find.text("Medium"));
    await tester.pump();
    expect(ignoring(), isFalse);

    final cheese = tester.widget<FeedbackButton>(find.ancestor(of: find.text("Cheese"), matching: find.byType(FeedbackButton)));
    expect(cheese.action, isNull);
  });

  testWidgets("a ticket line says what was chosen and what the dish goes without", (tester) async {
    final ticket = PosInvoiceService(source: _Source());
    addTearDown(ticket.dispose);

    await pump(tester, SizedBox(width: 320, child: PosTicketLine(
      cart: ticket,
      currency: _currency,
      line: const PosCartLine(
        key: "l", label: "Burger", price: 9, quantity: 1, productId: "burger", held: 1,
        omitted: ["fries"],
        modifiers: [(group: "g", option: "o", name: "Cheese", price: 1), (group: "d", option: "m", name: "Medium", price: 0)]
      )
    )));

    expect(tester.takeException(), isNull);
    expect(find.textContaining("+ Cheese"), findsOneWidget);
    expect(find.textContaining("Medium · without fries"), findsOneWidget);
  });
}

const _currency = CurrencyModel(code: "USD", name: "Dollar", symbol: "\$");

/// A ticket source that opens one invoice, notes every line body and answers a line with the
/// product on it, or refuses with [refuse].
class _Source implements PosSource {
  _Source({this.refuse});

  Map<String, dynamic>? refuse;
  final bodies = <Map<String, dynamic>>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<PosInvoice> open({required double tax}) async => const PosInvoice(id: "i", ticket: "T", isOpen: true);

  @override
  Future<List<PosInvoice>> openInvoices({bool mine = false, required int size}) async =>
    const [PosInvoice(id: "i", ticket: "T", isOpen: true)];

  @override
  Future<PosInvoice> writeLine(String id, Map<String, dynamic> body) async {
    bodies.add(body);

    final refused = refuse;
    if (refused != null) throw refused;

    return const PosInvoice(id: "i", ticket: "T", isOpen: true, items: [
      PosInvoiceLine(lineId: "l", productId: "burger", name: "Burger", quantity: 1, held: 1, price: 8)
    ]);
  }
}
