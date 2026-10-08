import 'package:app/services/badges/badge_model.dart';

/// One notification of the feed behind the bell (`GET /lyra/v1/notifications`), or one that just
/// arrived over the socket (`notification/new`). Both share this shape.
///
/// The backend writes [title] and [body] for a human already: they are shown as received, never
/// translated (`lib/l10n/MODULE.md`).
class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    this.level = BadgeLevel.info,
    this.link,
    this.data,
    this.seen = false,
    this.date
  });

  final String id;

  /// What happened, in the backend's vocabulary: `chat.new`, `sale.ticket`, `knowledge.pending`.
  final String type;

  final String title;
  final String? body;

  /// `success` reads as [BadgeLevel.info]: a notification is coloured like the dots it explains.
  final BadgeLevel level;

  /// The backend's guess at a route. The app opens [area] instead.
  final String? link;

  /// Ids the destination needs (`chat`, `ticket`).
  final Object? data;

  /// Whether it is older than the last time this person opened the bell.
  final bool seen;

  final DateTime? date;

  /// **The section this notification is about**, as a `HomeSection.key` and permission area,
  /// or `null` for one every member may read. It is both the gate (a person who cannot open the
  /// chats is not shown a customer's first message: the event goes to the whole company room)
  /// and where tapping it goes. A type the backend gates (`Notifications.#gates`) gets its line
  /// here too.
  String? get area => switch (type) {
    "chat.new" => "messages",
    "sale.ticket" => "sales",
    "knowledge.pending" => "knowledge",
    _ => null
  };

  NotificationModel get asSeen => NotificationModel(
    id: id,
    type: type,
    title: title,
    body: body,
    level: level,
    link: link,
    data: data,
    seen: true,
    date: date
  );

  /// A row of the compressed table or the socket payload. One without an id or a title is not a
  /// notification anybody can read.
  static NotificationModel? fromJson(Map json) {
    final id = json["id"];
    final title = json["title"];
    if (id is! String || id.isEmpty || title is! String || title.isEmpty) return null;

    final body = json["body"];
    final level = json["level"];

    return NotificationModel(
      id: id,
      type: json["type"]?.toString() ?? "",
      title: title,
      body: body is String && body.isNotEmpty ? body : null,
      level: level == "success" ? BadgeLevel.info : BadgeLevel.of(level),
      link: json["link"] is String ? json["link"] as String : null,
      data: json["data"],
      seen: json["seen"] == true,
      date: DateTime.tryParse("${json["date"]}")?.toLocal()
    );
  }
}
