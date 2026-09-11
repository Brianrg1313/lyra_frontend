/// Mirrors `SessionState` in `baileys_server/src/whatsapp/status.js` — the
/// wire values are shared verbatim with the server, not re-encoded, so a
/// state added there only needs a case added here.
enum BaileysSessionState {
  starting,
  qrPending,
  connected,
  reconnecting,
  stopped,
  loggedOut,
  error,
  /// The server has no session under this id at all (never created, or
  /// unreachable). Not one of the server's own states: it is what this app
  /// assumes when there is nothing to read yet.
  unknown;

  static BaileysSessionState from(dynamic raw) => switch (raw?.toString()) {
    "starting" => starting,
    "qr_pending" => qrPending,
    "connected" => connected,
    "reconnecting" => reconnecting,
    "stopped" => stopped,
    "logged_out" => loggedOut,
    "error" => error,
    _ => unknown
  };

  /// `true` while the session is meant to be running: the switch reads as
  /// "on" for all of these, even mid-retry or waiting on a QR scan — only a
  /// deliberate stop, a logout, or never having started reads as "off".
  bool get isActive => switch (this) {
    starting || qrPending || connected || reconnecting => true,
    stopped || loggedOut || error || unknown => false
  };
}

/// One WhatsApp session's live status, as `baileys_server`'s control API
/// reports it — the same shape for every route that returns one (`POST
/// /sessions`, `GET /sessions/:id`, `POST /sessions/:id/start|stop`).
class BaileysSessionStatus {
  const BaileysSessionStatus({
    required this.id,
    required this.state,
    this.phone,
    this.qr,
    this.qrImage,
    this.lastError
  });

  final String id;
  final BaileysSessionState state;
  final String? phone;

  /// Raw QR payload. Not used to render anything — [qrImage] is what the app
  /// shows — but kept in case a future screen wants the text form.
  final String? qr;

  /// `data:image/png;base64,...` — ready to decode and hand to `Image.memory`.
  final String? qrImage;

  final String? lastError;

  /// The session does not exist on the server (yet, or ever): nothing to
  /// show, and the switch reads as off.
  static const BaileysSessionStatus unknown = BaileysSessionStatus(
    id: "",
    state: BaileysSessionState.unknown
  );

  factory BaileysSessionStatus.fromJson(Map json) => BaileysSessionStatus(
    id: json["id"]?.toString() ?? "",
    state: BaileysSessionState.from(json["state"]),
    phone: json["phone"]?.toString(),
    qr: json["qr"]?.toString(),
    qrImage: json["qrImage"]?.toString(),
    lastError: json["lastError"]?.toString()
  );
}
