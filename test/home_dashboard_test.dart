import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

// PACKAGES
import 'package:genui/genui.dart' as genui;
import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/assistant/assistant_line.dart';
import 'package:app/services/assistant/assistant_service.dart';
import 'package:app/services/assistant/assistant_turn.dart';
import 'package:app/services/assistant/sources/assistant_demo_source.dart';
import 'package:app/services/assistant/sources/assistant_source.dart';
import 'package:app/screens/home/sections/dashboard/_dashboard.dart';
import 'package:app/screens/home/sections/dashboard/assistant/_assistant.dart';
import 'package:app/screens/home/sections/dashboard/assistant/assistant_confirm.dart';
import 'package:app/screens/home/sections/dashboard/assistant/assistant_turn_view.dart';
import 'package:app/screens/home/sections/dashboard/assistant/catalog/lyra_catalog.dart';

/// The home's chat is the backend's panel assistant
/// (`docs/guides/asistente-frontend.md`): **the conversation is the
/// server's**, read whole and grown by the lines each message, button and
/// socket event brings, each line once. An answer's A2UI blocks become GenUI
/// surfaces in their place, drawn with the Lyra catalog; anything else in a
/// fence stays text. What waits for a yes is the person's to press.
///
/// Nothing reaches a backend: [AssistantDemoSource] at no pace, or [_Fake].
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

AssistantService _service({AssistantSource? source, void Function(String)? onNavigate}) => AssistantService(
  catalogs: [LyraCatalog.build()],
  source: source ?? AssistantDemoSource(pace: Duration.zero),
  onNavigate: onNavigate,
  live: false
);

/// Lets the source, the adapter's parser and the controller settle.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

/// A source the test answers by hand.
class _Fake implements AssistantSource {
  AssistantBatch thread = const AssistantBatch();
  Completer<AssistantBatch>? reply;
  Object? failure;
  int closed = 0;

  @override
  Future<AssistantBatch> read() async => thread;

  @override
  Future<AssistantBatch> send(String message) {
    if (failure case final error?) return Future.error(error);
    return (reply = Completer()).future;
  }

  @override
  Future<AssistantBatch> confirm(String id, {required bool yes}) async => const AssistantBatch();

  @override
  Future<void> close() async => closed++;
}

Map<String, Object?> _line(String id, String role, String text, {List<Map<String, Object?>>? calls, String? outcome}) => {
  "id": id,
  "role": role,
  "text": text,
  "date": "2026-10-21T15:00:00.000Z",
  "calls": ?calls,
  "outcome": ?outcome
};

String _a2ui(String surface) => "```json\n${jsonEncode([
  {"version": "v0.9", "createSurface": {"surfaceId": surface, "catalogId": LyraCatalog.id}},
  {"version": "v0.9", "updateComponents": {"surfaceId": surface, "components": [
    {"id": "root", "component": "Text", "text": "Drawn"}
  ]}}
])}\n```";

void main() {
  setUpAll(() async {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
    await S.load(const Locale("en"));
  });

  tearDown(() => AssistantPanel.sourceOverride = null);

  testWidgets("the home lays out the chat and the summary side by side", (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    AssistantPanel.sourceOverride = AssistantDemoSource(pace: Duration.zero);

    await tester.pumpWidget(_app(const DashboardSection()));
    await _settle(tester);

    expect(find.text(S.current.assistant_welcome_title), findsOneWidget);
    expect(find.text(S.current.dashboard_summary_title), findsOneWidget);
    expect(find.text(S.current.dashboard_subscription_title), findsOneWidget);
    expect(tester.takeException(), isNull);

    // A suggestion is sent as typed: the greeting gives way to the thread.
    await tester.tap(find.text(S.current.assistant_suggestion_sales_title));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text(S.current.assistant_suggestion_sales_prompt), findsOneWidget);
    expect(find.text(S.current.assistant_welcome_title), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets("the conversation is read whole: text, surfaces and events in order", (tester) async {
    final fake = _Fake()..thread = AssistantBatch.fromJson({
      "id": "t1",
      "messages": [
        _line("1", "person", "How did we do?"),
        _line("2", "assistant", "Here it is.\n${_a2ui("s1")}\nAnything else?", calls: [
          {"operation": "sales.list", "status": "done", "effect": "read"}
        ]),
        _line("3", "assistant", "A JSON example stays text:\n```json\n{\"name\": \"x\"}\n```"),
        _line("4", "event", "Retire the answer", outcome: "done")
      ],
      "pending": [
        {"id": "p1", "operation": "knowledge.delete", "summary": "Retire it", "expires": "2999-01-01T00:00:00.000Z"}
      ]
    });
    final service = _service(source: fake);
    addTearDown(service.dispose);

    await service.load();

    expect(service.status, AssistantStatus.ready);
    expect(service.turns.map((turn) => turn.role), [AssistantRole.user, AssistantRole.assistant, AssistantRole.assistant, AssistantRole.event]);
    expect(service.turns[1].parts.map((part) => part.isSurface), [false, true, false]);
    expect(service.turns[1].text, isNot(contains("createSurface")));
    expect(service.turns[1].calls.single.operation, "sales.list");
    expect(service.turns[2].parts.single.isSurface, isFalse);
    expect(service.turns[2].text, contains("\"name\""));
    expect(service.turns[3].outcome, "done");
    expect(service.pending.single.summary, "Retire it");
  });

  testWidgets("a surface is drawn with the catalog and its controls answer", (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final paths = <String>[];
    final service = _service(onNavigate: paths.add);
    addTearDown(service.dispose);

    await service.send(S.current.assistant_suggestion_sales_prompt);

    await tester.pumpWidget(_app(ChangeNotifierProvider<AssistantService>.value(
      value: service,
      child: SingleChildScrollView(child: AssistantTurnView(turn: service.turns.last))
    )));
    await _settle(tester);

    expect(find.byType(genui.Surface), findsOneWidget);
    expect(find.text(S.current.assistant_demo_revenue), findsOneWidget);

    // A navigate event leaves the chat as it is and opens the path.
    await tester.tap(find.text(S.current.assistant_demo_open_sales));
    await _settle(tester);
    expect(paths, ["/home/sales"]);
    expect(service.turns, hasLength(2));

    // Any other event is the person's message, answered.
    await tester.tap(find.text(S.current.assistant_demo_compare));
    await _settle(tester);

    expect(service.turns, hasLength(4));
    expect(service.turns[2].action, "compare_week");
    expect(service.turns[2].text, S.current.assistant_demo_compare);
    expect(service.turns[3].state, AssistantTurnState.done);
  });

  testWidgets("the POST and the socket carry the same lines: each shows once", (tester) async {
    final fake = _Fake();
    final service = _service(source: fake);
    addTearDown(service.dispose);

    final sent = service.send("Hi");

    // The person's line shows at once, the thinking mark after it.
    expect(service.busy, isTrue);
    expect(service.turns.map((turn) => turn.state), [AssistantTurnState.done, AssistantTurnState.waiting]);

    final answer = {
      "thread": "t1",
      "messages": [_line("1", "person", "Hi"), _line("2", "assistant", "Hello")],
      "pending": <Object>[]
    };

    service.receive(AssistantService.workingEvent, {"thread": "t1", "working": true});
    service.receive(AssistantService.messageEvent, answer);
    service.receive(AssistantService.workingEvent, {"thread": "t1", "working": false});
    fake.reply!.complete(AssistantBatch.fromJson(answer));
    await sent;

    expect(service.busy, isFalse);
    expect(service.turns.map((turn) => turn.text), ["Hi", "Hello"]);
    expect(service.turns.first.id, "1");

    // Another screen of the person is answering: this one waits too.
    service.receive(AssistantService.workingEvent, {"thread": "t1", "working": true});
    expect(service.busy, isTrue);
    expect(service.turns.last.isWaiting, isTrue);
  });

  testWidgets("a refused message says why; an answer after a new chat is dropped", (tester) async {
    final fake = _Fake()..failure = {"message": "assistant_busy"};
    final service = _service(source: fake);
    addTearDown(service.dispose);

    await service.send("Hi");

    expect(service.turns.last.state, AssistantTurnState.failed);
    expect(service.turns.last.reason, "assistant_busy");

    fake.failure = null;
    final sent = service.send("Again");
    await service.clear();

    fake.reply!.complete(AssistantBatch.fromJson({
      "thread": "t1",
      "messages": [_line("9", "assistant", "Late")]
    }));
    await sent;

    expect(fake.closed, 1);
    expect(service.isEmpty, isTrue);
  });

  testWidgets("a pending is the person's: yes runs it and the event says so", (tester) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final service = _service();
    addTearDown(service.dispose);

    await service.send(S.current.assistant_demo_order);
    expect(service.pending.single.summary, S.current.assistant_demo_order_summary);

    await tester.pumpWidget(_app(ChangeNotifierProvider<AssistantService>.value(
      value: service,
      child: AssistantConfirm(pending: service.pending.single)
    )));

    expect(find.text(S.current.assistant_demo_order_summary), findsOneWidget);

    await tester.tap(find.text(S.current.assistant_confirm_yes));
    await _settle(tester);

    expect(service.pending, isEmpty);
    expect(service.turns.last.isEvent, isTrue);
    expect(service.turns.last.outcome, "done");

    // Unmounted, the card's expiry timer stops.
    await tester.pumpWidget(const SizedBox());
  });
}
