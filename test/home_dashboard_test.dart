import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

// PACKAGES
import 'package:genui/genui.dart' as genui;
import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/assistant/assistant_service.dart';
import 'package:app/services/assistant/assistant_turn.dart';
import 'package:app/services/assistant/sources/assistant_demo_source.dart';
import 'package:app/screens/home/sections/dashboard/_dashboard.dart';
import 'package:app/screens/home/sections/dashboard/assistant/assistant_turn_view.dart';
import 'package:app/screens/home/sections/dashboard/assistant/catalog/lyra_catalog.dart';

/// The home's chat runs on GenUI: **an answer keeps its text and its surfaces
/// in the order the model sent them**, every surface is drawn with the Lyra
/// catalog, and a control pressed on one comes back as the person's next turn.
///
/// The answers are `AssistantDemoSource`'s at no pace; nothing is asked of a
/// backend. The home itself must lay out at desktop width with both panels.
Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: const [
    S.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate
  ],
  supportedLocales: S.delegate.supportedLocales,
  home: Builder(builder: (context) {
    AppSize.instance(context);
    return Scaffold(body: child);
  })
);

AssistantService _service({void Function(String)? onNavigate}) => AssistantService(
  catalogs: [LyraCatalog.build()],
  source: AssistantDemoSource(pace: Duration.zero),
  onNavigate: onNavigate
);

/// Lets the stream, the adapter's parser and the controller settle.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

void main() {
  setUpAll(() async {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
    await S.load(const Locale("en"));
  });

  testWidgets("the home lays out the chat and the summary side by side", (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const DashboardSection()));
    await tester.pump();

    expect(find.text(S.current.assistant_welcome_title), findsOneWidget);
    expect(find.text(S.current.dashboard_summary_title), findsOneWidget);
    expect(find.text(S.current.dashboard_subscription_title), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("an answer interleaves its text and its surface", (tester) async {
    final service = _service();
    addTearDown(service.dispose);

    service.send(S.current.assistant_suggestion_sales_prompt);
    await _settle(tester);

    expect(service.busy, isFalse);
    expect(service.turns, hasLength(2));

    final answer = service.turns.last;
    expect(answer.state, AssistantTurnState.done);
    expect(answer.parts.map((part) => part.isSurface), [false, true, false]);
    expect(answer.text, contains("12%"));
    // The JSON is the surface's, never the text's.
    expect(answer.text, isNot(contains("createSurface")));
  });

  testWidgets("a surface is drawn with the catalog and its controls answer", (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final paths = <String>[];
    final service = _service(onNavigate: paths.add);
    addTearDown(service.dispose);

    service.send(S.current.assistant_suggestion_sales_prompt);
    await _settle(tester);

    await tester.pumpWidget(_app(ChangeNotifierProvider<AssistantService>.value(
      value: service,
      child: SingleChildScrollView(child: AssistantTurnView(turn: service.turns.last))
    )));
    await _settle(tester);

    expect(find.byType(genui.Surface), findsOneWidget);
    expect(find.text(S.current.assistant_demo_revenue), findsOneWidget);
    expect(find.text(S.current.assistant_demo_compare), findsOneWidget);

    // A navigate event leaves the chat as it is and opens the path.
    await tester.tap(find.text(S.current.assistant_demo_open_sales));
    await _settle(tester);
    expect(paths, ["/home/sales"]);
    expect(service.turns, hasLength(2));

    // Any other event is the person's turn, answered.
    await tester.tap(find.text(S.current.assistant_demo_compare));
    await _settle(tester);

    expect(service.turns, hasLength(4));
    expect(service.turns[2].action, "compare_week");
    expect(service.turns[2].text, S.current.assistant_demo_compare);
    expect(service.turns[3].state, AssistantTurnState.done);
  });

  testWidgets("stop cuts the answer and late chunks are dropped", (tester) async {
    final service = AssistantService(
      catalogs: [LyraCatalog.build()],
      source: AssistantDemoSource(pace: const Duration(milliseconds: 50))
    );
    addTearDown(service.dispose);

    service.send(S.current.assistant_suggestion_help_prompt);
    await tester.pump(const Duration(milliseconds: 120));

    expect(service.busy, isTrue);
    service.stop();

    final cut = service.turns.last.text;
    await tester.pump(const Duration(seconds: 5));

    expect(service.busy, isFalse);
    expect(service.turns.last.state, AssistantTurnState.stopped);
    expect(service.turns.last.text, cut);
  });
}
