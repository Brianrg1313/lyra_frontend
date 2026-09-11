import 'baileys_session_status.dart';

/// One message as `baileys_server` normalizes it
/// (`baileys_server/src/whatsapp/message-mapper.js`) — the same flat shape the
/// server sends to the backend, so anything built on this later reads exactly
/// what the backend does.
class BaileysMessage {
  const BaileysMessage({
    required this.id,
    required this.from,
    required this.fromMe,
    required this.type,
    this.pushName,
    this.text,
    this.timestamp,
    this.mediaMimetype,
    this.mediaSizeBytes
  });

  final String? id;

  /// Phone number of the other end of the chat, already stripped of the JID
  /// suffix by the server.
  final String? from;

  /// `true` for a message this number sent (from the phone, or through this
  /// server) — WhatsApp echoes those back over the same event.
  final bool fromMe;

  /// `text`, `image`, `audio`, `location`, ... — the server's own vocabulary,
  /// which stays open-ended: an unrecognized Baileys content type arrives
  /// under its raw key rather than being dropped.
  final String type;

  /// The sender's WhatsApp display name, when WhatsApp included it.
  final String? pushName;

  final String? text;
  final DateTime? timestamp;
  final String? mediaMimetype;
  final int? mediaSizeBytes;

  factory BaileysMessage.fromJson(Map json) {
    final seconds = json["timestamp"];
    final media = json["media"];

    return BaileysMessage(
      id: json["id"]?.toString(),
      from: json["from"]?.toString(),
      fromMe: json["fromMe"] == true,
      type: json["type"]?.toString() ?? "unknown",
      pushName: json["pushName"]?.toString(),
      text: json["text"]?.toString(),
      timestamp: seconds is num
        ? DateTime.fromMillisecondsSinceEpoch(seconds.toInt() * 1000)
        : null,
      mediaMimetype: media is Map ? media["mimetype"]?.toString() : null,
      mediaSizeBytes: media is Map && media["sizeBytes"] is num
        ? (media["sizeBytes"] as num).toInt()
        : null
    );
  }

  /// One-line form for the console feed: who, which way, and enough of the
  /// content to tell two messages apart while developing.
  String get summary {
    final who = pushName == null || pushName!.isEmpty
      ? from ?? "unknown"
      : "$from ($pushName)";

    final body = switch (type) {
      "text" => text ?? "",
      _ when text != null && text!.isNotEmpty => "[$type] $text",
      _ => "[$type${mediaMimetype == null ? "" : " $mediaMimetype"}]"
    };

    return "${fromMe ? "→" : "←"} $who: $body";
  }
}

/// One frame off the server's local event feed (`ws://127.0.0.1:<port>/events`,
/// `baileys_server/src/control/events.js`).
///
/// Only the two event types the feed actually broadcasts are modelled;
/// anything else (the `hello` frame, or a type added server-side later)
/// arrives as [BaileysEventType.other] with [raw] intact rather than throwing,
/// so an older app build never chokes on a newer server.
enum BaileysEventType { sessionStatus, messageReceived, other }

class BaileysEvent {
  const BaileysEvent({
    required this.type,
    required this.raw,
    this.sessionId,
    this.status,
    this.message
  });

  final BaileysEventType type;
  final Map raw;
  final String? sessionId;
  final BaileysSessionStatus? status;
  final BaileysMessage? message;

  factory BaileysEvent.fromJson(Map json) {
    final status = json["status"];
    final message = json["message"];

    return BaileysEvent(
      type: switch (json["type"]?.toString()) {
        "session.status" => BaileysEventType.sessionStatus,
        "message.received" => BaileysEventType.messageReceived,
        _ => BaileysEventType.other
      },
      raw: json,
      sessionId: json["session_id"]?.toString(),
      status: status is Map ? BaileysSessionStatus.fromJson(status) : null,
      message: message is Map ? BaileysMessage.fromJson(message) : null
    );
  }
}
