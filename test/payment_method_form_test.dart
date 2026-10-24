import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/screens/modals/finance/payment_method_form/_payment_method_form.dart';
import 'package:app/services/money/money_currency_model.dart';
import 'package:app/services/money/money_method_model.dart';

/// The account form asks what the **rail** asks and nothing else.
///
/// This is the whole point of the requirement sheet
/// (`model:/money/requirements.js`): before it, every rail was offered the same
/// six boxes, so a Pago Movil demanded a holder and a tax id it has no use for
/// —the sending app resolves the name from the id— while a bank transfer could
/// be saved without the account number that is the only reason it exists.
///
/// What is pinned here is the reading of the sheet, not the sheet itself: which
/// fields a rail has is the backend's answer and changing it must not break a
/// test in this app.
final _pagoMovil = [
  MoneyMethodField.fromJson(const {
    "field": "institution",
    "type": "select",
    "label": "Bank",
    "hint": "Bank that receives the payment",
    "options": "banks",
    "required": true
  }),
  MoneyMethodField.fromJson(const {
    "field": "document",
    "type": "document",
    "label": "Cedula or RIF",
    "hint": "12345678",
    "options": "documents",
    "required": true
  }),
  MoneyMethodField.fromJson(const {
    "field": "account",
    "type": "phone",
    "label": "Phone number",
    // Deliberately unlike the fixture's own number: a placeholder equal to the
    // value makes every `widgetWithText` here match twice.
    "hint": "0424 1234567",
    "format": "0000 000 00 00",
    "required": true
  })
];

final _options = {
  "banks": [
    MoneyPaymentOption.fromJson(const {"code": "0134", "name": "Banesco"}),
    MoneyPaymentOption.fromJson(const {"code": "0105", "name": "Mercantil"})
  ],
  "documents": [
    MoneyPaymentOption.fromJson(const {"code": "V", "name": "Cedula"}),
    MoneyPaymentOption.fromJson(const {"code": "J", "name": "RIF"})
  ]
};

const _rails = [
  MoneyRail(code: "pago_movil", name: "Pago movil", method: "mobile"),
  MoneyRail(code: "cash", name: "Efectivo", method: "cash")
];

Widget _host(Widget modal, void Function(dynamic result) onClosed) => MaterialApp(
  localizationsDelegates: const [
    S.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate
  ],
  supportedLocales: S.delegate.supportedLocales,
  home: Builder(builder: (context) {
    AppSize.instance(context);

    return Scaffold(body: Builder(builder: (context) => TextButton(
      // Through a route and not inline: what the panel answers travels through
      // `Navigator.pop`, which is what its caller awaits.
      onPressed: () async => onClosed(await showDialog(
        context: context,
        builder: (context) => Dialog(child: SingleChildScrollView(child: modal))
      )),
      child: const Text("open")
    )));
  })
);

Future<void> _open(WidgetTester tester, Widget host) async {
  // Taller than the default 600: the form of a rail that asks for three things
  // plus the button does not fit in it, and a button below the fold cannot be
  // tapped.
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(host);
  await tester.tap(find.text("open"));
  await tester.pumpAndSettle();
}

/// The account a Pago Movil ends up being, as `GET /money/methods` answers it:
/// the bank as the code it is routed by, and the id joined to its type.
MoneyMethod _method() => MoneyMethod.fromJson(const {
  "id": "m1",
  "code": "pago_movil",
  "name": "Pago movil",
  "label": "Pago movil Banesco",
  "institution": "0134",
  "institutionName": "Banesco",
  "document": "V-30512345",
  "account": "04121234567"
});

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();

    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  testWidgets('a rail is asked exactly what its sheet says', (tester) async {
    await _open(tester, _host(
      PaymentMethodFormModal(
        rails: _rails,
        sheets: {"pago_movil": _pagoMovil},
        options: _options,
        method: _method()
      ),
      (_) {}
    ));

    expect(tester.takeException(), isNull);

    // The rail's own words for the columns, and not the table's.
    expect(find.text("Bank"), findsOneWidget);
    expect(find.text("Phone number"), findsOneWidget);

    // The two the form used to demand of every rail alike. A Pago Movil has no
    // holder, so there is no box for one.
    expect(find.text(S.current.finance_method_holder), findsNothing);
    expect(find.text(S.current.finance_method_institution), findsNothing);
  });

  testWidgets('an id is read back as the type somebody picked and the number', (
    tester
  ) async {
    await _open(tester, _host(
      PaymentMethodFormModal(
        rails: _rails,
        sheets: {"pago_movil": _pagoMovil},
        options: _options,
        method: _method()
      ),
      (_) {}
    ));

    // Stored joined (`V-30512345`), because that is how an id is dictated and
    // pasted; drawn split, because the type is a choice and the number is not.
    expect(find.widgetWithText(TextField, "30512345"), findsOneWidget);

    // Chosen as `V - Cedula` out of the list and kept as the letter alone: the
    // box is a third of a line wide, and `V` is what gets dictated in front of
    // the number anyway.
    expect(find.widgetWithText(TextField, "V"), findsOneWidget);

    // The bank is stored as the code it is routed by and drawn as the code and
    // the name together: a bank that renames must not turn this account into a
    // different bank, and both halves are what gets read out to a customer.
    expect(find.widgetWithText(TextField, "0134 - Banesco"), findsOneWidget);
  });

  testWidgets('a number with a shape is read in it', (tester) async {
    await _open(tester, _host(
      PaymentMethodFormModal(
        rails: _rails,
        sheets: {"pago_movil": _pagoMovil},
        options: _options,
        method: _method()
      ),
      (_) {}
    ));

    // Saved unspaced —from an import, or from before the rail had a mask— and
    // read in the shape the field keeps it in, so it does not change under the
    // first keystroke.
    expect(find.widgetWithText(TextField, "0412 123 45 67"), findsOneWidget);
  });

  testWidgets('what is typed into a shaped field is spaced as it is typed', (
    tester
  ) async {
    dynamic body;

    await _open(tester, _host(
      PaymentMethodFormModal(
        rails: _rails,
        sheets: {"pago_movil": _pagoMovil},
        options: _options,
        method: _method()
      ),
      (value) => body = value
    ));

    await tester.enterText(
      find.widgetWithText(TextField, "0412 123 45 67"),
      "04149876543"
    );
    await tester.pump();

    expect(find.widgetWithText(TextField, "0414 987 65 43"), findsOneWidget);

    await tester.tap(find.text(S.current.save));
    await tester.pumpAndSettle();

    // The spacing is part of the value: it is what the customer is shown and
    // what the backend stores (`Requirements.format`).
    expect(body["ACCOUNT"], "0414 987 65 43");
  });

  testWidgets('what can be left empty says so', (tester) async {
    await _open(tester, _host(
      PaymentMethodFormModal(
        rails: _rails,
        sheets: {"pago_movil": _pagoMovil},
        options: _options,
        method: _method()
      ),
      (_) {}
    ));

    final optional = S.current.finance_method_optional;

    expect(
      find.text("${S.current.finance_method_instructions} · $optional"),
      findsOneWidget
    );

    // What the rail requires carries no such word: on a form whose middle is
    // mostly required, marking the exception is what says anything at all.
    expect(find.text("Bank · $optional"), findsNothing);
  });

  testWidgets('what it hands back is the sheet, joined back together', (
    tester
  ) async {
    dynamic body;

    await _open(tester, _host(
      PaymentMethodFormModal(
        rails: _rails,
        sheets: {"pago_movil": _pagoMovil},
        options: _options,
        method: _method()
      ),
      (value) => body = value
    ));

    await tester.tap(find.text(S.current.save));
    await tester.pumpAndSettle();

    expect(body, isA<Map<String, dynamic>>());
    expect(body["ID"], "m1");
    expect(body["INSTITUTION"], "0134");
    expect(body["DOCUMENT"], "V-30512345");
    expect(body["ACCOUNT"], "0412 123 45 67");

    // The column this rail does not have is not sent at all: what a Pago Movil
    // is, is a bank, an id and a phone.
    expect(body.containsKey("HOLDER"), isFalse);
    // The rail is never in an edit: it would rewrite what the payments already
    // recorded say they came in through.
    expect(body.containsKey("CODE"), isFalse);
  });

  testWidgets('a rail with nothing to fill in says so and still saves', (
    tester
  ) async {
    dynamic body;

    await _open(tester, _host(
      PaymentMethodFormModal(
        rails: _rails,
        sheets: const {"cash": []},
        options: _options,
        method: MoneyMethod.fromJson(const {
          "id": "m2",
          "code": "cash",
          "name": "Efectivo",
          "label": "Caja"
        })
      ),
      (value) => body = value
    ));

    expect(find.text(S.current.finance_method_nothing), findsOneWidget);

    await tester.tap(find.text(S.current.save));
    await tester.pumpAndSettle();

    expect(body["ID"], "m2");
    expect(body["LABEL"], "Caja");
    // Nothing else: cash has no account, so there is no column to write.
    expect(body.containsKey("ACCOUNT"), isFalse);
  });

  group('currency and commission', () {
    const setup = MoneyCurrencies(
      main: "USD",
      exchanges: [MoneyExchange(currency: "VES", rate: 36.52)]
    );

    MoneyMethod zelle({Map<String, dynamic> extra = const {}}) =>
      MoneyMethod.fromJson({
        "id": "m3",
        "code": "zelle",
        "name": "Zelle",
        ...extra
      });

    const rails = [MoneyRail(code: "zelle", name: "Zelle", method: "transfer")];

    testWidgets('an edit hands back the currency and the commission', (
      tester
    ) async {
      dynamic body;

      await _open(tester, _host(
        PaymentMethodFormModal(
          rails: rails,
          sheets: const {"zelle": []},
          options: const {},
          currencies: setup,
          method: zelle(extra: const {
            "currency": "VES",
            "fee": {"type": "percent", "value": 3.5}
          })
        ),
        (value) => body = value
      ));

      expect(tester.takeException(), isNull);
      expect(find.widgetWithText(TextField, "3.5"), findsOneWidget);

      await tester.tap(find.text(S.current.save));
      await tester.pumpAndSettle();

      expect(body["CURRENCY"], "VES");
      expect(body["FEE_TYPE"], "percent");
      expect(body["FEE"], 3.5);
    });

    testWidgets('a percentage of a hundred or more is refused', (tester) async {
      dynamic body = "untouched";

      await _open(tester, _host(
        PaymentMethodFormModal(
          rails: rails,
          sheets: const {"zelle": []},
          options: const {},
          currencies: setup,
          method: zelle(extra: const {
            "fee": {"type": "percent", "value": 3.5}
          })
        ),
        (value) => body = value
      ));

      await tester.enterText(find.widgetWithText(TextField, "3.5"), "150");
      await tester.tap(find.text(S.current.save));
      await tester.pumpAndSettle();

      expect(body, "untouched");
      expect(find.text(S.current.finance_method_fee_error), findsOneWidget);
    });

    testWidgets('a rail that moves one currency is saved in it, and warned of '
      'when nothing can price it', (tester) async {
      dynamic body;

      await _open(tester, _host(
        PaymentMethodFormModal(
          rails: const [
            MoneyRail(code: "pago_movil", name: "Pago movil", currency: "VES")
          ],
          sheets: {"pago_movil": _pagoMovil},
          options: _options,
          // The company takes nothing but dollars yet.
          currencies: const MoneyCurrencies(main: "USD"),
          method: _method()
        ),
        (value) => body = value
      ));

      expect(
        find.text(S.current.finance_method_currency_missing("VES")),
        findsOneWidget
      );

      await tester.tap(find.text(S.current.save));
      await tester.pumpAndSettle();

      expect(body["CURRENCY"], "VES");
    });

    testWidgets('without a setup the currency is not asked nor sent', (
      tester
    ) async {
      dynamic body;

      await _open(tester, _host(
        PaymentMethodFormModal(
          rails: rails,
          sheets: const {"zelle": []},
          options: const {},
          method: zelle()
        ),
        (value) => body = value
      ));

      expect(find.text(S.current.finance_method_currency), findsNothing);

      await tester.tap(find.text(S.current.save));
      await tester.pumpAndSettle();

      expect(body.containsKey("CURRENCY"), isFalse);
      // No commission on an edit is still said: it is how one is taken off.
      expect(body["FEE_TYPE"], "none");
    });
  });

  group('paid on delivery', () {
    MoneyMethod cash({bool onDelivery = false}) => MoneyMethod.fromJson({
      "id": "m2",
      "code": "cash",
      "name": "Efectivo",
      "onDelivery": onDelivery
    });

    testWidgets('is not asked without a rider delivering', (tester) async {
      await _open(tester, _host(
        PaymentMethodFormModal(rails: _rails, sheets: const {"cash": []}, options: _options, method: cash()),
        (_) {}
      ));

      expect(find.text(S.current.finance_method_on_delivery_off), findsNothing);
    });

    testWidgets('turned on travels on the edit, untouched it does not', (tester) async {
      dynamic body;

      await _open(tester, _host(
        PaymentMethodFormModal(
          rails: _rails,
          sheets: const {"cash": []},
          options: _options,
          doorDelivery: true,
          method: cash()
        ),
        (value) => body = value
      ));

      await tester.tap(find.text(S.current.save));
      await tester.pumpAndSettle();
      expect(body.containsKey("ON_DELIVERY"), isFalse);

      await tester.tap(find.text("open"));
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.current.finance_method_on_delivery_off));
      await tester.pump();
      expect(find.text(S.current.finance_method_on_delivery_on), findsOneWidget);

      await tester.tap(find.text(S.current.save));
      await tester.pumpAndSettle();
      expect(body["ON_DELIVERY"], isTrue);
    });

    testWidgets('an account already marked keeps the box to take it off', (tester) async {
      dynamic body;

      await _open(tester, _host(
        PaymentMethodFormModal(rails: _rails, sheets: const {"cash": []}, options: _options, method: cash(onDelivery: true)),
        (value) => body = value
      ));

      await tester.tap(find.text(S.current.finance_method_on_delivery_on));
      await tester.pump();
      await tester.tap(find.text(S.current.save));
      await tester.pumpAndSettle();

      expect(body["ON_DELIVERY"], isFalse);
    });
  });
}
