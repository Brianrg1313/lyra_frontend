import 'dart:convert';
import 'dart:io';

import 'baileys_event.dart';
import 'baileys_session_status.dart';

/// Raised by every [BaileysClient] call that could not complete — the server
/// is not reachable, rejected the key, or answered with an error status.
/// Callers treat this the same regardless of cause: the session's state is
/// unknown until the next successful call.
class BaileysClientException implements Exception {
  BaileysClientException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Thin client for `baileys_server`'s local control API
/// (`baileys_server/src/control`). Talks to `127.0.0.1` only — this is a
/// sidecar on the same machine, never a remote service — with the shared
/// `x-api-key` every route but `/health` requires.
///
/// Deliberately not built on `package:core/api.dart`'s `RestAPI`: that class
/// is shaped around the app's own backend (a session token, a `business_id`
/// header, dev/prod hosts), none of which applies to a fixed-key localhost
/// sidecar. A dozen lines of `HttpClient` say what is actually happening
/// more plainly than fitting this into a shape built for something else.
class BaileysClient {
  BaileysClient({required this.host, required this.port, required this.apiKey});

  final String host;
  final int port;
  final String apiKey;

  static const _timeout = Duration(seconds: 5);

  /// The server's `/health` payload, or `null` if the process does not answer
  /// at all. Does not require the key: the app needs to tell "not running"
  /// apart from "running but rejecting me" (see
  /// `baileys_server/src/control/routes/health.js`).
  Future<Map?> health() async {
    try {
      final data = await _send("GET", "/health", auth: false);
      return data is Map ? data : const {};
    } catch (_) {
      return null;
    }
  }

  /// Live feed of everything happening on the server — inbound WhatsApp
  /// messages and session status changes — over the WebSocket the control API
  /// serves on its own port (`baileys_server/src/control/events.js`).
  ///
  /// The key goes in the query string because that is the single form the
  /// server accepts on the upgrade request. Frames that fail to parse are
  /// skipped rather than closing the stream: a malformed frame is a server
  /// bug worth surviving, not a reason to stop watching.
  Stream<BaileysEvent> events() async* {
    final socket = await WebSocket.connect(
      "ws://$host:$port/events?key=${Uri.encodeQueryComponent(apiKey)}"
    ).timeout(_timeout);

    try {
      await for (final frame in socket) {
        if (frame is! String) continue;

        final json = jsonDecode(frame);
        if (json is Map) yield BaileysEvent.fromJson(json);
      }
    } finally {
      await socket.close();
    }
  }

  /// Asks the process to exit. The app does not hold an OS handle to it (it is
  /// started detached), so this is the only way to stop it.
  Future<void> shutdown() => _send("POST", "/control/shutdown");

  Future<List<BaileysSessionStatus>> listSessions() async {
    final data = await _send("GET", "/sessions");
    final sessions = data is Map ? data["sessions"] : null;

    if (sessions is! List) return const [];

    return [
      for (final item in sessions)
        if (item is Map) BaileysSessionStatus.fromJson(item)
    ];
  }

  /// Creates the session if it does not exist and (re)starts it either way.
  Future<BaileysSessionStatus> ensureStarted(String id) async {
    final data = await _send("POST", "/sessions", body: {"id": id});
    return BaileysSessionStatus.fromJson(data as Map);
  }

  /// `null` if the server has no session under this id — not an error, just
  /// nothing to report yet.
  Future<BaileysSessionStatus?> getStatus(String id) async {
    try {
      final data = await _send("GET", "/sessions/$id");
      return BaileysSessionStatus.fromJson(data as Map);
    } on BaileysClientException catch (error) {
      if (error.message.contains("404")) return null;
      rethrow;
    }
  }

  Future<BaileysSessionStatus> stop(String id) async {
    final data = await _send("POST", "/sessions/$id/stop");
    return BaileysSessionStatus.fromJson(data as Map);
  }

  Future<BaileysSessionStatus> logout(String id) async {
    final data = await _send("POST", "/sessions/$id/logout");
    return BaileysSessionStatus.fromJson(data as Map);
  }

  Future<void> remove(String id) => _send("DELETE", "/sessions/$id");

  /// Hands the sidecar the session it should act as when it talks to the
  /// backend.
  ///
  /// This is the whole of the sidecar's identity there. The backend issues it
  /// no token and stores none: it authenticates the relay with **this app's
  /// own user session**, so `POST /cygnus/v1/whatsapp_personal/session` and
  /// every message forwarded afterwards carry the same `Authorization`,
  /// `device` and `business_id` a request from this app carries.
  ///
  /// Sent again whenever any of it changes. The address a reply is emitted to
  /// is the room of the session that announced the number, so a stale token
  /// here is not a slow relay — it is answers sent to a room nobody is in.
  Future<void> setBackend({
    required String url,
    required String token,
    required String device,
    required String business,
    String? language
  }) => _send("PUT", "/backend", body: {
    "url": url,
    "token": token,
    "device": device,
    "business": business,
    "language": ?language
  });

  /// Signing out: the sidecar stops relaying. Its WhatsApp sessions are left
  /// alone on purpose — nobody unlinked a phone, and undoing that would cost a
  /// QR scan.
  Future<void> clearBackend() => _send("DELETE", "/backend");

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool auth = true
  }) async {
    final client = HttpClient();

    try {
      final request = await client
        .openUrl(method, Uri(scheme: "http", host: host, port: port, path: path))
        .timeout(_timeout);

      if (auth) request.headers.set("x-api-key", apiKey);

      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }

      final response = await request.close().timeout(_timeout);
      final text = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw BaileysClientException(
          "baileys_server $method $path -> HTTP ${response.statusCode}"
        );
      }

      return text.isEmpty ? null : jsonDecode(text);
    } on BaileysClientException {
      rethrow;
    } catch (error) {
      throw BaileysClientException("baileys_server unreachable: $error");
    } finally {
      client.close(force: true);
    }
  }
}
