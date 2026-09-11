import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

// PACKAGES
import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/money/money_bot_model.dart';
import 'package:app/services/money/money_bot_service.dart';
import 'package:app/services/money/money_service.dart';
import 'package:app/screens/home/sections/finance/overview/bot_block.dart';

/// Lyra's card in the money overview: that it draws the total and the areas it
/// is made of, and that it fits where the section actually puts it.
///
/// The width matters here and is not a detail of the design: the block lives in
/// the body of a section that shares the window with the side bar, its header
/// carries a second range picker beside the title, and each area line carries a
/// name, its split and a figure. Any of the three is a row that overflows on a
/// narrow window, which is exactly the kind of break nobody sees until somebody
/// opens the app on half a screen.
///
/// The service is seeded, never read: asking for it would be hitting the
/// backend.
Widget _app(MoneyBotService service, {double width = 900}) => MaterialApp(
  localizationsDelegates: const [
    S.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate
  ],
  supportedLocales: S.delegate.supportedLocales,
  home: ChangeNotifierProvider<MoneyBotService>.value(
    value: service,
    child: Builder(builder: (context) {
      AppSize.instance(context);

      return Scaffold(
        body: SizedBox(
          width: width,
          child: const SingleChildScrollView(child: MoneyBotBlock())
        )
      );
    })
  )
);

MoneyBotSpend _spend() => MoneyBotSpend.fromResponse({
  "from": "2026-08-08T00:00:00.000Z",
  "to": "2026-09-07T12:00:00.000Z",
  "currency": "USD",
  "total": 1.5,
  "assistant": {
    "total": 1.1,
    "text": {"total": 0.9, "requests": 40},
    "media": {"total": 0.15, "requests": 3},
    "research": {"total": 0.05, "requests": 1},
    "conversations": 12,
    "messages": 84
  },
  "tables": {"total": 0.25, "runs": 4},
  "vectors": {
    "total": 0.14,
    "catalog": {"total": 0.1, "requests": 20},
    "queries": {"total": 0.04, "requests": 10}
  },
  "other": {"total": 0}
});

void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  testWidgets('draws the total and the areas it is made of', (tester) async {
    final service = MoneyBotService()..seed(_spend());

    await tester.pumpWidget(_app(service));
    await tester.pump();

    expect(find.text(S.current.finance_bot_title), findsOneWidget);
    expect(find.text(S.current.finance_bot_answers), findsOneWidget);
    expect(find.text(S.current.finance_bot_tables), findsOneWidget);
    expect(find.text(S.current.finance_bot_vectors), findsOneWidget);

    // Unattributed spend is only a line when there is any: a nought beside
    // three real figures reads as a fourth area of the product.
    expect(find.text(S.current.finance_bot_other), findsNothing);

    service.dispose();
  });

  testWidgets('only the totals are written as money', (tester) async {
    // The card is read for a price, so the prices on it are the four the client
    // is charged —the total and one per area— written bold in the plain text
    // colour. What each area is made of is named and never priced: eight
    // figures on one sheet is nobody finding the one they came for.
    final service = MoneyBotService()..seed(_spend());

    await tester.pumpWidget(_app(service));
    await tester.pump();

    // The catalog is not loaded in a test, so an amount is written with the
    // currency code (`USD 1.50`). The hint names the currency too, which is why
    // the figure and not the word is what is counted.
    final money = RegExp(r"USD\s\d");
    final written = tester
      .widgetList<Text>(find.byType(Text))
      .where((text) => money.hasMatch(text.data ?? ""))
      .toList();

    expect(written.length, 4);

    for (final text in written) {
      expect(text.style?.fontWeight, FontWeight.bold);
    }

    // The split of the answering line is there, and it carries no money.
    expect(
      find.textContaining(S.current.finance_bot_media),
      findsOneWidget
    );

    service.dispose();
  });

  testWidgets('a window with no spend keeps the figure', (tester) async {
    // A measured zero is an answer —the backend refuses rather than claiming
    // nothing was spent— so it is said in a sentence and the total stays.
    final service = MoneyBotService()
      ..seed(MoneyBotSpend.fromResponse({"currency": "USD", "total": 0}));

    await tester.pumpWidget(_app(service));
    await tester.pump();

    expect(find.text(S.current.finance_bot_empty), findsOneWidget);
    expect(find.text(S.current.finance_bot_answers), findsNothing);

    service.dispose();
  });

  testWidgets('it fits the body of the section on a narrow window',
    (tester) async {
      final service = MoneyBotService()..seed(_spend());

      // The body of the section with the side bar open, on a laptop: the
      // narrowest the block is drawn at before the layout goes to one column.
      await tester.pumpWidget(_app(service, width: 420));
      await tester.pump();

      expect(tester.takeException(), isNull);

      service.dispose();
    }
  );

  testWidgets('the window is its own and opens on the month', (tester) async {
    final service = MoneyBotService()..seed(_spend());

    await tester.pumpWidget(_app(service));
    await tester.pump();

    // Not today, unlike the money above it: what was spent on models since
    // midnight is cents, and the question this card answers is about a month.
    expect(service.range, MoneyRange.month);
    expect(find.text(S.current.finance_range_month), findsOneWidget);

    service.dispose();
  });
}
