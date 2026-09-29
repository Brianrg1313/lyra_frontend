import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/screens/modals/finance/exchange_currency_form/_exchange_currency_form.dart';
import 'package:app/services/catalog/currency_catalog_service.dart';
import 'package:app/services/money/money_currency_model.dart';

/// The exchange currency form asks for a figure only when the rate is the
/// company's own.
///
/// An official rate is the feed's: a box to type it into would let anybody
/// call their own figure official, so the body of an official rate carries no
/// `RATE` at all. A custom rate is the opposite — without a positive figure
/// there is nothing to charge with, and the panel does not close.
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
      onPressed: () async => onClosed(await showDialog(
        context: context,
        builder: (context) => Dialog(child: SingleChildScrollView(child: modal))
      )),
      child: const Text("open")
    )));
  })
);

Future<void> _open(WidgetTester tester, Widget host) async {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(host);
  await tester.tap(find.text("open"));
  await tester.pumpAndSettle();
}

const _custom = MoneyExchange(
  currency: "VES",
  mode: MoneyRateMode.custom,
  rate: 40.5,
  official: 36.52,
  custom: 40.5
);

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();

    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));

    CurrencyCatalogService().seed(const [
      {"code": "USD", "name": "US Dollar", "symbol": r"$"},
      {"code": "VES", "name": "Bolivar", "symbol": "Bs.", "space": true}
    ]);
  });

  testWidgets('a custom rate is handed back with its figure', (tester) async {
    dynamic body;

    await _open(tester, _host(
      const ExchangeCurrencyFormModal(main: "USD", exchange: _custom),
      (value) => body = value
    ));

    expect(tester.takeException(), isNull);
    expect(find.widgetWithText(TextField, "40.5"), findsOneWidget);

    // The figure is the business's own, and so is the responsibility for it.
    expect(find.text(S.current.finance_currency_custom_disclaimer), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, "40.5"), "41,25");
    await tester.tap(find.text(S.current.save));
    await tester.pumpAndSettle();

    // Typed with the comma a bolivar is written with, read as the same rate.
    expect(body, {"CURRENCY": "VES", "MODE": "custom", "RATE": 41.25});
  });

  testWidgets('a custom rate without a figure does not close', (tester) async {
    dynamic body = "untouched";

    await _open(tester, _host(
      const ExchangeCurrencyFormModal(main: "USD", exchange: _custom),
      (value) => body = value
    ));

    await tester.enterText(find.widgetWithText(TextField, "40.5"), "0");
    await tester.tap(find.text(S.current.save));
    await tester.pumpAndSettle();

    expect(body, "untouched");
    expect(find.text(S.current.finance_currency_rate_error), findsOneWidget);
  });

  testWidgets('an official rate asks for no figure and sends none', (
    tester
  ) async {
    dynamic body;

    await _open(tester, _host(
      const ExchangeCurrencyFormModal(
        main: "USD",
        exchange: MoneyExchange(currency: "VES", rate: 36.52, official: 36.52)
      ),
      (value) => body = value
    ));

    expect(find.text(S.current.finance_currency_rate("USD", "VES")), findsNothing);
    expect(find.text(S.current.finance_currency_custom_disclaimer), findsNothing);

    await tester.tap(find.text(S.current.save));
    await tester.pumpAndSettle();

    expect(body, {"CURRENCY": "VES", "MODE": "official"});
  });
}
