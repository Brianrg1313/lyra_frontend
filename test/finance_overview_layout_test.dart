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
import 'package:app/services/money/money_summary_model.dart';
import 'package:app/screens/home/sections/finance/overview/_overview.dart';
import 'package:app/screens/home/sections/finance/overview/bot_block.dart';

/// The overview holds two reads over two windows, and **the bot's half is drawn
/// whatever the money half did**.
///
/// It is the rule the tab was restructured for: a company that answers
/// customers all month without recording a single payment is a company the
/// money read calls empty, and hiding Lyra's card behind that state would hide
/// the only figure it is being charged for. The same goes for a failed summary,
/// which is a failure of the other endpoint.
///
/// The services are seeded, never read: asking would be hitting the backend.
class _Money extends MoneyService {
  _Money(this._status);

  final MoneySummaryStatus _status;

  @override
  MoneySummaryStatus get status => _status;

  @override
  MoneySummary get summary => const MoneySummary(currency: "USD", isLoaded: true);

  @override
  Future<void> load({bool force = false}) async {}
}

MoneyBotSpend _spend() => MoneyBotSpend.fromResponse({
  "currency": "USD",
  "total": 1.5,
  "assistant": {
    "total": 1.1,
    "text": {"total": 0.9},
    "media": {"total": 0.15},
    "research": {"total": 0.05},
    "conversations": 12,
    "messages": 84
  },
  "tables": {"total": 0.25, "runs": 4},
  "vectors": {
    "total": 0.14,
    "catalog": {"total": 0.1},
    "queries": {"total": 0.04}
  },
  "other": {"total": 0}
});

Widget _app(MoneyService money, MoneyBotService bot) => MaterialApp(
  localizationsDelegates: const [
    S.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate
  ],
  supportedLocales: S.delegate.supportedLocales,
  home: MultiProvider(
    providers: [
      ChangeNotifierProvider<MoneyService>.value(value: money),
      ChangeNotifierProvider<MoneyBotService>.value(value: bot)
    ],
    child: Builder(builder: (context) {
      AppSize.instance(context);

      return const Scaffold(body: FinanceOverviewTab());
    })
  )
);

void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  testWidgets('the figures and what Lyra cost share one scroll', (tester) async {
    final bot = MoneyBotService()..seed(_spend());

    await tester.pumpWidget(_app(_Money(MoneySummaryStatus.ready), bot));
    await tester.pump();

    expect(find.byType(MoneyBotBlock), findsOneWidget);
    expect(tester.takeException(), isNull);

    bot.dispose();
  });

  testWidgets('a month with no money still shows what Lyra cost',
    (tester) async {
      final bot = MoneyBotService()..seed(_spend());

      await tester.pumpWidget(_app(_Money(MoneySummaryStatus.empty), bot));
      await tester.pump();

      expect(find.text(S.current.finance_summary_empty_title), findsOneWidget);
      expect(find.byType(MoneyBotBlock), findsOneWidget);

      bot.dispose();
    }
  );

  testWidgets("a summary that failed does not take Lyra's card with it",
    (tester) async {
      final bot = MoneyBotService()..seed(_spend());

      await tester.pumpWidget(_app(_Money(MoneySummaryStatus.error), bot));
      await tester.pump();

      expect(find.text(S.current.finance_summary_error_title), findsOneWidget);
      expect(find.byType(MoneyBotBlock), findsOneWidget);

      bot.dispose();
    }
  );
}
