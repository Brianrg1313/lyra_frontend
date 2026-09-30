import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/local_server/local_server_service.dart';
import 'package:app/services/local_server/node_commands.dart';

/// The app's side of the engine (`docs/plan-offline-lan.md` §3): every step is a `lyra_node`
/// command, secrets go on stdin, and the engine is started detached only when it isn't already
/// running. The executable itself is tested in `lyra_node/test/process_test.dart`.
void main() {
  test('a build that cannot be a master never runs the engine', () async {
    final node = _Node();
    final service = LocalServerService(commands: node, supported: false);

    expect(await service.refresh(), LocalServerStatus.unavailable);
    expect(await service.setUp(username: "a", password: "b", firstName: "c", lastName: "d"), isNull);
    expect(node.calls, isEmpty);
  });

  test('setup sends the owner on stdin and answers the recovery words once', () async {
    final node = _Node()..answers["setup"] = {"instanceId": "i1", "recovery": List.filled(24, "word")};
    final service = LocalServerService(commands: node, supported: true);

    final words = await service.setUp(
      username: "ada",
      password: "correct horse battery",
      firstName: "Ada",
      lastName: "L",
      passphrase: "a long passphrase",
    );

    expect(words, hasLength(24));
    expect(service.instanceId, "i1");
    expect(node.calls.single.command, ["setup"]);
    expect(node.calls.single.command.join(" "), isNot(contains("correct horse")));
    expect(jsonDecode(node.calls.single.input!), {
      "owner": {"username": "ada", "password": "correct horse battery", "firstName": "Ada", "lastName": "L"},
      "passphrase": "a long passphrase",
    });
  });

  test('a refusal keeps the engine\'s code', () async {
    final node = _Node()..answers["setup"] = {"error": "already_set_up"};
    final service = LocalServerService(commands: node, supported: true);

    expect(await service.setUp(username: "a", password: "b", firstName: "c", lastName: "d"), isNull);
    expect(service.status, LocalServerStatus.error);
    expect(service.error, "already_set_up");
  });

  test('start attaches to a running engine instead of starting a second one', () async {
    final node = _Node()..statuses.add("ready");
    final service = LocalServerService(commands: node, supported: true);

    expect(await service.start(), LocalServerStatus.ready);
    expect(node.spawned, isEmpty);
  });

  test('start spawns a stopped engine detached and waits until it is up', () async {
    final node = _Node()..statuses.addAll(["stopped", "stopped", "starting", "locked"]);
    final service = LocalServerService(commands: node, supported: true);

    expect(await service.start(passphrase: "a long passphrase"), LocalServerStatus.locked);
    expect(node.spawned, ["a long passphrase"]);
    expect(service.isRunning, isTrue);
  });

  test('an engine that cannot prove it is ours is left alone', () async {
    final node = _Node()..statuses.add("unverified");
    final service = LocalServerService(commands: node, supported: true);

    expect(await service.start(), LocalServerStatus.unverified);
    expect(node.spawned, isEmpty);
  });

  test('an unknown status is not trusted', () async {
    final node = _Node()..statuses.add("dancing");
    final service = LocalServerService(commands: node, supported: true);

    expect(await service.refresh(), LocalServerStatus.unverified);
  });
}

class _Node implements NodeCommands {
  final List<({List<String> command, String? input})> calls = [];
  final Map<String, Map<String, Object?>> answers = {};
  final List<String> statuses = [];
  final List<String?> spawned = [];

  @override
  Future<NodeAnswer> run(List<String> command, {String? input}) async {
    calls.add((command: command, input: input));

    if (command.first == "status") {
      final status = statuses.length > 1 ? statuses.removeAt(0) : statuses.single;
      return (exitCode: 0, json: <String, Object?>{"status": status});
    }

    final json = answers[command.first] ?? const {};

    return (exitCode: json.containsKey("error") ? 1 : 0, json: json);
  }

  @override
  Future<void> spawn({String? passphrase}) async => spawned.add(passphrase);
}
