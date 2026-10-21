import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';
import 'package:app/services/assistant/assistant_app_tools.dart';
import 'package:app/services/assistant/assistant_line.dart';
import 'package:app/services/assistant/assistant_service.dart';
import 'package:app/services/assistant/sources/assistant_source.dart';
import 'package:app/screens/home/sections/dashboard/assistant/catalog/lyra_catalog.dart';

/// The panel's assistant asks **this app** to run tools
/// (`docs/guides/asistente-frontend.md` §7 in the backend): every screen of
/// the person gets `assistant/tool`, and only the one whose client sent the
/// message answers, once, with what the tool returned or why it could not.
/// `open` opens only what this person may open, answered before it navigates
/// (leaving the home unmounts the chat); `view` says the screen and what the
/// sections left in this company. Each message declares what the app runs.
///
/// Nothing reaches a backend: answers are recorded by hand.
class _Answer {
  final String id;
  final Object? data;
  final String? error;

  const _Answer(this.id, this.data, this.error);
}

class _Source implements AssistantSource {
  Map<String, Object?>? app;

  @override
  Future<AssistantBatch> read() async => const AssistantBatch();

  @override
  Future<AssistantBatch> send(String message, {Map<String, Object?>? app}) async {
    this.app = app;
    return const AssistantBatch();
  }

  @override
  Future<AssistantBatch> confirm(String id, {required bool yes}) async => const AssistantBatch();

  @override
  Future<void> close() async {}
}

void main() {
  late List<_Answer> answers;
  late List<String> opened;
  late AssistantAppTools tools;
  String? business;

  setUp(() {
    answers = [];
    opened = [];
    business = "b1";
    tools = AssistantAppTools.test(answer: (id, {data, error}) async => answers.add(_Answer(id, data, error)))
      ..openWith(
        navigate: opened.add,
        screens: () => ["/home", "/home/deliveries"],
        business: () => business
      );
  });

  Map<String, Object?> ask(String name, [Map<String, Object?> input = const {}, String? client]) => {
    "thread": "t1",
    "id": "a${answers.length}",
    "client": client ?? tools.client,
    "name": name,
    "input": input
  };

  test("a message declares this screen, what it runs and where it may go", () {
    expect(tools.declared(), {
      "CLIENT": tools.client,
      "TOOLS": ["view", "open"],
      "SCREENS": ["/home", "/home/deliveries"]
    });

    final bare = AssistantAppTools.test(answer: (id, {data, error}) async {});
    expect(bare.declared()["TOOLS"], ["view"], reason: "no shell, nothing to open with");
  });

  test("only the screen that sent the message answers", () async {
    await tools.receive(ask("view", const {}, "another-screen"));
    expect(answers, isEmpty);

    await tools.receive(ask("view"));
    expect(answers.single.error, isNull);
  });

  test("open answers first and navigates after, only to a screen offered", () async {
    final order = <String>[];
    final ordered = AssistantAppTools.test(answer: (id, {data, error}) async {
      await Future<void>.delayed(Duration.zero);
      order.add("answered");
    })..openWith(navigate: (path) => order.add("opened $path"), screens: () => ["/home/deliveries"], business: () => null);

    await ordered.receive({"id": "a0", "client": ordered.client, "name": "open", "input": {"PATH": "/home/deliveries"}});
    expect(order, ["answered", "opened /home/deliveries"]);

    await tools.receive(ask("open", {"PATH": "/home/deliveries"}));
    expect(answers.single.data, {"opened": "/home/deliveries"});
    expect(opened, ["/home/deliveries"]);

    await tools.receive(ask("open", {"PATH": "/home/finance"}));
    expect(answers.last.error, isNotNull);
    expect(opened, ["/home/deliveries"]);
  });

  test("view says the screen and what a section left, in this company only", () async {
    tools.glance("deliveries", {"tapped": {"latitude": 10.5, "longitude": -66.9}});

    await tools.receive(ask("view"));
    final view = answers.single.data as Map;
    expect(view["screen"], Navis.currentKey.value);
    expect(view["deliveries"], {"tapped": {"latitude": 10.5, "longitude": -66.9}});

    business = "b2";
    await tools.receive(ask("view"));
    expect((answers.last.data as Map).containsKey("deliveries"), isFalse);

    business = "b1";
    tools.glance("deliveries", null);
    await tools.receive(ask("view"));
    expect((answers.last.data as Map).containsKey("deliveries"), isFalse);
  });

  test("a tool this app does not run is answered with why", () async {
    await tools.receive(ask("shell", {"COMMAND": "dir"}));

    expect(answers.single.data, isNull);
    expect(answers.single.error, contains("shell"));
  });

  test("the chat sends what the app runs with each message", () async {
    final source = _Source();
    final service = AssistantService(catalogs: [LyraCatalog.build()], source: source, tools: tools, live: false);
    addTearDown(service.dispose);

    await service.send("Show me the new area");

    expect(source.app, tools.declared());
  });
}
