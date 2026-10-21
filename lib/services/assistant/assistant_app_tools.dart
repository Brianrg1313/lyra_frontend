import 'package:flutter/foundation.dart';

// PACKAGES
import 'package:uuid/uuid.dart';

// SERVICES
import 'package:app/toolkit/toolkit.dart' show Navis;
import 'package:app/services/connection/connection_service.dart';
import './sources/assistant_cloud_source.dart';

/// One tool this app runs for the assistant: what it returns, or throws why
/// it could not.
typedef AssistantAppTool = Future<Object?> Function(Map<String, Object?> input);

/// The tools the panel's assistant asks **this app** to run
/// (`docs/guides/asistente-frontend.md` §7 in the backend): open a screen on
/// this device, read what it shows. The server owns their descriptions; the
/// app only declares, with each message, which it runs ([declared]).
///
/// App-wide, never the chat's: `open` leaves the home, which unmounts the chat
/// while the run goes on, and the next ask must still be answered. A singleton
/// that listens from [start] on, for the life of the app.
///
/// Every screen of the person gets each `assistant/tool`; only the one whose
/// [client] sent the message answers it. Cloud only.
class AssistantAppTools {
  AssistantAppTools._({AssistantAnswer? answer}) : _answer = answer ?? AssistantCloudSource.answerTool;

  static final AssistantAppTools instance = AssistantAppTools._();

  /// A fresh registry (tests), answering through [answer].
  @visibleForTesting
  factory AssistantAppTools.test({required AssistantAnswer answer}) => AssistantAppTools._(answer: answer);

  static const String toolEvent = "assistant/tool";

  final AssistantAnswer _answer;

  /// This screen, as the server tells it from the person's other ones.
  final String client = const Uuid().v4();

  final Map<String, AssistantAppTool> _tools = {};

  /// What sections left of themselves for `view`, by part (`deliveries`),
  /// with the company they were left in.
  final Map<String, (String?, Map<String, Object?>)> _glances = {};

  /// The paths this person may open now; set with `open` by the shell.
  List<String> Function()? _screens;

  /// The active company: a glance left in another one is not shown.
  String? Function() _business = () => null;

  bool _started = false;

  /// What a tool does once its answer is sent (`open`'s navigation).
  void Function()? _after;

  /// Listens to `assistant/tool` from now on; once.
  void start() {
    if (_started) return;
    _started = true;

    ConnectionService().on(toolEvent, receive);
  }

  /// Runs `open` with [navigate] over the paths [screens] says this person may
  /// open. The shell's: a service holds no navigation.
  void openWith({
    required void Function(String path) navigate,
    required List<String> Function() screens,
    required String? Function() business
  }) {
    _screens = screens;
    _business = business;
    _tools["open"] = (input) async {
      final path = input["PATH"];
      if (path is! String || !screens().contains(path)) throw "That screen cannot be opened";

      // Answered first, opened after: leaving the home unmounts the chat, and
      // the answer must not depend on what the new screen does
      _after = () => navigate(path);
      return {"opened": path};
    };
  }

  /// What a section leaves for `view` under [part]; null takes it out.
  void glance(String part, Map<String, Object?>? value) {
    value == null ? _glances.remove(part) : _glances[part] = (_business(), value);
  }

  /// `view`: the screen open and what the sections left in this company.
  Map<String, Object?> view() {
    final business = _business();

    return {
      "screen": Navis.currentKey.value,
      for (final MapEntry(:key, value: (left, glance)) in _glances.entries)
        if (left == business) key: glance
    };
  }

  /// The `APP` of a message: this screen and what it runs now.
  Map<String, Object?> declared() {
    final screens = _screens?.call() ?? const <String>[];

    return {
      "CLIENT": client,
      "TOOLS": ["view", if (_tools.containsKey("open") && screens.isNotEmpty) "open"],
      "SCREENS": screens
    };
  }

  /// A socket event (and the tests' seam).
  @visibleForTesting
  Future<void> receive(Object? data) async {
    if (data is! Map || data["client"] != client) return;

    final id = data["id"];
    final name = data["name"];
    if (id is! String || name is! String) return;

    final input = (data["input"] as Map?)?.cast<String, Object?>() ?? const <String, Object?>{};
    final tool = name == "view" ? (_) async => view() : _tools[name];

    Object? result;
    String? failure;

    try {
      if (tool == null) throw "This app does not run $name";
      result = await tool(input);
    } catch (error) {
      failure = error is String ? error : "$error";
    }

    try {
      await _answer(id, data: result, error: failure);
    } catch (error) {
      // The run fails the call on its own when no answer comes
      debugPrint("Assistant tool $name could not be answered: $error");
    }

    final after = _after;
    _after = null;
    after?.call();
  }
}

/// Answers one ask: [data], or [error] when it could not.
typedef AssistantAnswer = Future<void> Function(String id, {Object? data, String? error});
