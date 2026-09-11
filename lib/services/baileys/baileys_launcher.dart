import 'dart:io';

import 'package:flutter/foundation.dart';

import 'baileys_client.dart';

/// Starts `baileys_server` as a detached OS process and waits for it to
/// answer, when it is not already running.
///
/// **Dev-time only.** It resolves the server by walking up from
/// [Directory.current] looking for a `baileys_server/package.json` —
/// true while running via `flutter run` from the project root, which is
/// where a `dev` launch of this feature is expected to run from today.
/// Shipping this to a real install needs the server packaged (a bundled
/// Node runtime, or a `pkg`/`nexe` executable) and this resolution replaced
/// with a path next to the app's own executable — deliberately not solved
/// here, since it is a packaging decision, not something this class can
/// guess at.
///
/// `mode: ProcessStartMode.detached` is what makes this survive the app
/// closing: the child is disowned from this process's tree instead of tied
/// to its lifetime, which is the whole point of the sidecar — see
/// `baileys_server/MODULE.md`.
class BaileysLauncher {
  const BaileysLauncher({required this.host, required this.port});

  final String host;
  final int port;

  /// Makes sure the server is reachable, starting it if not. Returns `true`
  /// once a health check succeeds, `false` if it never comes up (missing
  /// Node, missing source, or it crashed on boot — check
  /// `baileys_server/data/server.log`).
  ///
  /// In debug builds this also replaces a server that is running code older
  /// than what is on disk — see [_isOutdated].
  Future<bool> ensureRunning(BaileysClient client) async {
    final serverDir = _findServerDir();
    final health = await client.health();

    if (health != null) {
      if (serverDir == null || !_isOutdated(health, serverDir)) return true;

      debugPrint("[baileys] server is running older code — restarting it");
      if (!await _stopRunning(client)) return true;
    }

    if (!Platform.isWindows) return false;
    if (serverDir == null) return false;

    try {
      await Process.start(
        "node",
        ["src/index.js"],
        workingDirectory: serverDir.path,
        mode: ProcessStartMode.detached,
        environment: {
          "HOST": host,
          "PORT": port.toString(),
          "CONTROL_API_KEY": client.apiKey
        }
      );
    } catch (_) {
      // Most likely Node is not on PATH. Nothing more to try here — surfaced
      // to the caller as "did not come up", same as any other failure to
      // start.
      return false;
    }

    return _waitForHealth(client);
  }

  /// `true` when the running process started before the newest edit to the
  /// server's sources.
  ///
  /// The sidecar is detached on purpose: it outlives the app, which also
  /// means an edit to `baileys_server/src` has no effect until something
  /// stops the old process — the app restarting is not enough, since the
  /// next launch just health-checks the stale one and moves on. That is a
  /// silent trap while developing the server, so a debug build closes it.
  /// Never in release: there are no source edits to pick up there, only the
  /// risk of cycling a healthy sidecar.
  bool _isOutdated(Map health, Directory serverDir) {
    if (!kDebugMode) return false;

    // A server with no `startedAt` predates this check itself, which makes it
    // old by definition — that is the very build this exists to replace.
    final startedAtMs = health["startedAt"];
    if (startedAtMs is! num) return true;

    final startedAt = DateTime.fromMillisecondsSinceEpoch(startedAtMs.toInt());
    final sources = Directory("${serverDir.path}/src");
    if (!sources.existsSync()) return false;

    return sources
      .listSync(recursive: true)
      .whereType<File>()
      .any((file) => file.statSync().modified.isAfter(startedAt));
  }

  /// Shuts the running process down and waits for the port to go quiet.
  /// `false` if it is still answering afterwards — the caller then keeps the
  /// old instance rather than spawning a second one, which the server's own
  /// single-instance guard would kill on boot anyway.
  Future<bool> _stopRunning(BaileysClient client) async {
    try {
      await client.shutdown();
    } catch (_) {
      // Already gone, or refusing the key: the wait below decides either way.
    }

    for (var attempt = 0; attempt < 10; attempt++) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (await client.health() == null) return true;
    }

    return false;
  }

  Future<bool> _waitForHealth(BaileysClient client) async {
    for (var attempt = 0; attempt < 20; attempt++) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (await client.health() != null) return true;
    }

    return false;
  }

  Directory? _findServerDir() {
    var dir = Directory.current;

    for (var i = 0; i < 6; i++) {
      final candidate = Directory("${dir.path}/baileys_server");
      if (File("${candidate.path}/package.json").existsSync()) return candidate;

      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }

    return null;
  }
}
