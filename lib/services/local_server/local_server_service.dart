// PACKAGES
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

// SERVICES
import './node_commands.dart';

/// What the engine on this computer is doing, as `lyra_node status` reports it.
enum LocalServerStatus {
  /// Not read yet.
  idle,

  /// This build can't be a master: web, Android, iOS, or no `lyra_node` next to the app
  /// (plan §3: `DeploymentRole.master` is desktop only).
  unavailable,

  /// This computer isn't a master yet.
  notSetUp,

  stopped,
  starting,

  /// Passphrase mode, waiting for it (plan §6.2).
  locked,

  ready,
  stopping,

  /// Something holds the engine's lock but can't prove it's our engine. The app never talks
  /// to it.
  unverified,

  /// The last command failed; [LocalServerService.error] says how.
  error,
}

/// The master's engine, `lyra_node`, seen from the app on that computer (plan §3, §4): set it
/// up, start it or attach to the one already running, stop it, read its status.
///
/// **The engine is a separate process.** Starting it detaches it, so closing the app leaves it
/// running for the other devices; nothing ever starts it except this service, when the app
/// opens on the master (plan D4). The app never opens the engine's files: every step is a
/// `lyra_node` command, and the engine proves it is ours with a state file signed by a key
/// only it reads from the OS vault.
///
/// Not provided app-wide yet: the boot flow and the setup screens use it from phase 3
/// (`docs/plan-offline-lan.md` §7.4).
class LocalServerService extends ChangeNotifier {
  LocalServerService({NodeCommands? commands, bool? supported})
    : _supported = supported ?? _desktopWithEngine,
      _commands = commands ?? ProcessNodeCommands();

  final bool _supported;
  final NodeCommands _commands;

  static bool get _desktopWithEngine =>
    !kIsWeb &&
    (Platform.isWindows || Platform.isMacOS || Platform.isLinux) &&
    ProcessNodeCommands.locate() != null;

  LocalServerStatus _status = LocalServerStatus.idle;
  LocalServerStatus get status => _status;

  String? _instanceId;
  String? get instanceId => _instanceId;

  String? _version;
  String? get version => _version;

  /// The LAN port once the engine listens (phase 3).
  int? _port;
  int? get port => _port;

  /// The engine's refusal code of the last failed command (`already_set_up`,
  /// `key_wrongPassphrase`, `weak_password`…), or null.
  String? _error;
  String? get error => _error;

  bool get isRunning => const {
    LocalServerStatus.starting,
    LocalServerStatus.locked,
    LocalServerStatus.ready,
  }.contains(_status);

  /// Reads the engine's status.
  Future<LocalServerStatus> refresh() async {
    if (!_supported) return _set(LocalServerStatus.unavailable);

    final answer = await _run(["status"]);
    if (answer == null) return _status;

    final json = answer.json;

    _instanceId = json["instanceId"] as String? ?? _instanceId;
    _version = json["version"] as String?;
    _port = json["port"] as int?;

    return _set(_statusOf(json["status"]));
  }

  /// Makes this computer a master with its first owner (plan §7.4, `session.md` S-6).
  /// [passphrase] chooses passphrase mode. Answers the 24 recovery words, **shown once**: the
  /// engine keeps no copy. Null when it was refused ([error]).
  Future<List<String>?> setUp({
    required String username,
    required String password,
    required String firstName,
    required String lastName,
    String? email,
    String? passphrase,
  }) async {
    if (!_supported) {
      _set(LocalServerStatus.unavailable);
      return null;
    }

    final answer = await _run(["setup"], input: jsonEncode({
      "owner": {
        "username": username,
        "password": password,
        "firstName": firstName,
        "lastName": lastName,
        "email": ?email,
      },
      "passphrase": ?passphrase,
    }));
    final words = answer?.json["recovery"];

    if (words is! List) return null;

    _instanceId = answer!.json["instanceId"] as String?;
    _set(LocalServerStatus.stopped);

    return words.cast<String>();
  }

  /// Makes sure the engine runs: attaches to the one already running (after it proved it is
  /// ours), or starts it detached and waits for it. Answers the status it settled in; `ready`
  /// or `locked` are running.
  Future<LocalServerStatus> start({String? passphrase, Duration timeout = const Duration(seconds: 20)}) async {
    final current = await refresh();

    if (current == LocalServerStatus.stopped) {
      try {
        await _commands.spawn(passphrase: passphrase);
      } catch (error) {
        _error = "spawn_failed";
        return _set(LocalServerStatus.error);
      }
    } else if (current != LocalServerStatus.starting) {
      return current;
    }

    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      final status = await refresh();

      if (status != LocalServerStatus.starting && status != LocalServerStatus.stopped) return status;

      await Future<void>.delayed(const Duration(milliseconds: 250));
    }

    return _status;
  }

  /// Stops the engine cleanly; every connected device loses it (the admin screen warns first,
  /// plan §3). Answers whether it stopped.
  Future<bool> stop() async {
    if (!_supported) return false;

    final answer = await _run(["stop"]);
    final stopped = answer?.json["stopped"] == true;

    if (stopped) _set(LocalServerStatus.stopped);

    return stopped;
  }

  /// Gets the data back with the recovery [words] on this computer (a lost vault or
  /// passphrase, a new machine: plan §6.2, §10.3). [passphrase] chooses the new unlock mode.
  Future<bool> recover(String words, {String? passphrase}) async {
    if (!_supported) return false;

    final answer = await _run(["recover"], input: jsonEncode({"words": words, "passphrase": ?passphrase}));

    return answer?.json["instanceId"] != null;
  }

  Future<NodeAnswer?> _run(List<String> command, {String? input}) async {
    try {
      final answer = await _commands.run(command, input: input);
      final code = answer.json["error"];

      if (answer.exitCode != 0 || code != null) {
        _error = code is String ? code : "exit_${answer.exitCode}";
        _set(LocalServerStatus.error);
        return null;
      }

      _error = null;
      return answer;
    } catch (error) {
      if (kDebugMode) print("lyra_node ${command.first} failed: $error");

      _error = "unreachable";
      _set(LocalServerStatus.error);
      return null;
    }
  }

  LocalServerStatus _set(LocalServerStatus status) {
    if (_status != status) {
      _status = status;
      notifyListeners();
    }

    return status;
  }

  static LocalServerStatus _statusOf(Object? name) {
    for (final status in LocalServerStatus.values) {
      if (status.name == name) return status;
    }

    // A status this app doesn't know is an engine it can't trust to understand.
    return LocalServerStatus.unverified;
  }
}
