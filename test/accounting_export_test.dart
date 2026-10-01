import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/button.dart';
import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/screens/modals/finance/accounting_export/_accounting_export.dart';
import 'package:app/services/money/money_export_request.dart';

/// The accounting export panel (`money.md` M-60) hands back whole calendar
/// days, the datasets in the file's order, and the format; it never closes
/// with nothing to export.
Widget _host(void Function(dynamic result) onClosed) => MaterialApp(
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
        builder: (context) => const Dialog(child: SingleChildScrollView(child: AccountingExportModal()))
      )),
      child: const Text("open")
    )));
  })
);

Future<void> _open(WidgetTester tester, void Function(dynamic result) onClosed) async {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_host(onClosed));
  await tester.tap(find.text("open"));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();

    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  testWidgets('last month, everything but the receivables, as a workbook by default', (tester) async {
    dynamic picked;
    await _open(tester, (value) => picked = value);

    expect(tester.takeException(), isNull);
    expect(find.text(S.current.finance_export_last_month), findsOneWidget);

    await tester.tap(find.widgetWithText(Button, S.current.finance_export));
    await tester.pumpAndSettle();

    final now = DateTime.now();
    final last = MoneyExportPeriod.month(now.year, now.month - 1);
    final result = picked as ({Map<String, dynamic> request, String name, MoneyExportFormat format});

    expect(result.request, {
      "from": MoneyExportPeriod.day(last.from),
      "to": MoneyExportPeriod.day(last.to),
      "datasets": ["sales", "sale_lines", "payments", "stock_movements"],
      "format": "xlsx"
    });
    expect(result.name, endsWith(".xlsx"));
  });

  testWidgets('with no dataset picked it says so and stays open', (tester) async {
    dynamic picked = "untouched";
    await _open(tester, (value) => picked = value);

    for (final title in [
      S.current.finance_export_sales,
      S.current.finance_export_sale_lines,
      S.current.finance_export_payments,
      S.current.finance_export_stock_movements
    ]) {
      await tester.tap(find.text(title));
      await tester.pump();
    }

    await tester.tap(find.widgetWithText(Button, S.current.finance_export));
    await tester.pumpAndSettle();

    expect(find.text(S.current.finance_export_datasets_empty), findsOneWidget);
    expect(picked, "untouched");
  });
}
