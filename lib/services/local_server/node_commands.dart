import 'dart:convert';
import 'dart:io';

/// One run of a `lyra_node` command: its exit code and the JSON line it printed.
typedef NodeAnswer = ({int exitCode, Map<String, Object?> json});

/// The `lyra_node` executable, as [LocalServerService] drives it. A seam, so the service's
/// tests run without the engine.
abstract interface class NodeCommands {
  /// Runs [command] to completion. [input] goes to stdin: it is the only way a secret (the
  /// owner's password, a passphrase, recovery words) reaches the engine, never an argument
  /// (`lyra_node/bin/lyra_node.dart`).
  Future<NodeAnswer> run(List<String> command, {String? input});

  /// Starts `run` detached, so the engine outlives this app (plan §3, D4). With [passphrase]
  /// the engine reads it from stdin and unlocks.
  Future<void> spawn({String? passphrase});
}

/// [NodeCommands] over the real executable.
///
/// It lives in `lyra_node/` next to the app's own executable (`lyra_node/bin/lyra_node(.exe)`,
/// the bundle `dart build cli` makes, with its `lib/` of native libraries). `LYRA_NODE` points
/// elsewhere while developing. Packaging it with the installers is plan phase 5.
final class ProcessNodeCommands implements NodeCommands {
  ProcessNodeCommands({this.dataFolder});

  /// The engine's data folder; null is its per-OS default.
  final String? dataFolder;

  /// The executable, or null when this install has none.
  static String? locate() {
    final override = Platform.environment["LYRA_NODE"];
    if (override != null && override.isNotEmpty) return File(override).existsSync() ? override : null;

    final name = Platform.isWindows ? "lyra_node.exe" : "lyra_node";
    final bundled = File(
      [File(Platform.resolvedExecutable).parent.path, "lyra_node", "bin", name].join(Platform.pathSeparator),
    );

    return bundled.existsSync() ? bundled.path : null;
  }

  /// The web build the engine serves to browsers (plan §3): `lyra_node/web` next to the
  /// executable's bundle, or `LYRA_WEB` while developing. Null when there is none; the engine
  /// then serves no pages, and native clients work the same.
  static String? locateWeb() {
    final override = Platform.environment["LYRA_WEB"];
    if (override != null && override.isNotEmpty) return Directory(override).existsSync() ? override : null;

    final bundled = Directory([File(Platform.resolvedExecutable).parent.path, "lyra_node", "web"].join(Platform.pathSeparator));

    return bundled.existsSync() ? bundled.path : null;
  }

  List<String> get _data => dataFolder == null ? const [] : ["--data", dataFolder!];

  String get _executable => locate() ?? (throw StateError("lyra_node is not installed"));

  @override
  Future<NodeAnswer> run(List<String> command, {String? input}) async {
    final process = await Process.start(_executable, [...command, ..._data]);

    if (input != null) process.stdin.write(input);
    await process.stdin.close();

    final (out, _, code) = await (
      process.stdout.transform(utf8.decoder).join(),
      process.stderr.drain<void>(),
      process.exitCode,
    ).wait;

    Map<String, Object?> json = const {};
    try {
      final decoded = jsonDecode(out.trim());
      if (decoded is Map<String, Object?>) json = decoded;
    } on FormatException {
      // No JSON line: the exit code alone says what happened.
    }

    return (exitCode: code, json: json);
  }

  @override
  Future<void> spawn({String? passphrase}) async {
    final process = await Process.start(
      _executable,
      ["run", ..._data, if (locateWeb() case final web?) ...["--web", web], if (passphrase != null) "--passphrase-stdin"],
      mode: passphrase == null ? ProcessStartMode.detached : ProcessStartMode.detachedWithStdio,
    );

    if (passphrase != null) {
      process.stdin.writeln(passphrase);
      await process.stdin.flush();
      await process.stdin.close();
    }
  }
}
