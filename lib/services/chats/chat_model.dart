/// One conversation of the inbox, as `GET /aries/v1/chats` and the chat socket
/// events describe it.
///
/// **Everything about where a conversation stands is measured by the backend
/// on read** (stage, attention, whether it was answered): nothing here computes
/// it. A socket event either carries the new value, which replaces the field,
/// or it does not, and the page is read again.
library;

// SERVICES
import 'package:app/services/catalog/catalog_table.dart';

/// Colour hint the backend attaches to a stage or a tag.
enum ChatLevel {
  info,
  warning,
  success,

  /// Only tags use it (`failure`).
  critical,

  /// Over: nothing left to do (`ended`, `abandoned`).
  muted;

  static ChatLevel from(dynamic raw) => switch (raw?.toString().trim()) {
    "warning" => ChatLevel.warning,
    "success" => ChatLevel.success,
    "critical" => ChatLevel.critical,
    "muted" => ChatLevel.muted,
    _ => ChatLevel.info
  };
}

/// Kind of attention mark a conversation carries (`waiting` on a row).
enum ChatWaiting {
  /// A bot turn failed; clears itself once anybody answers.
  failure,

  /// Work only a person can do; clears only through `alerts/resolve`.
  pending;

  static ChatWaiting? from(dynamic raw) => switch (raw?.toString().trim()) {
    "failure" => ChatWaiting.failure,
    "pending" => ChatWaiting.pending,
    _ => null
  };
}

/// A member of the company as the desk exposes it: never an internal id.
class ChatPerson {
  const ChatPerson({required this.username, this.name = ""});

  final String username;
  final String name;

  /// The name, or the username when the member has none.
  String get label => name.isNotEmpty ? name : username;

  static ChatPerson? from(dynamic json) {
    if (json is! Map) return null;

    final username = json["username"]?.toString().trim() ?? "";
    if (username.isEmpty) return null;

    return ChatPerson(username: username, name: chatText(json["name"]));
  }

  @override
  bool operator ==(Object other) =>
    other is ChatPerson && other.username == username;

  @override
  int get hashCode => username.hashCode;
}

/// Who answers the conversation.
///
/// [enabled] is the **number's** switch (all its conversations), [paused] is
/// this conversation taken by a person. A pause with [until] expires on the
/// server **without an event**, which is why [isPausedAt] exists.
class ChatBot {
  const ChatBot({
    this.enabled = true,
    this.paused = false,
    this.active = true,
    this.until,
    this.reason = "",
    this.at,
    this.by
  });

  final bool enabled;
  final bool paused;
  final bool active;
  final DateTime? until;
  final String reason;
  final DateTime? at;
  final ChatPerson? by;

  /// Whether a person still holds the conversation at [now]: an expired
  /// [until] reads as resumed.
  bool isPausedAt(DateTime now) =>
    paused && (until == null || until!.isAfter(now));

  factory ChatBot.from(dynamic json) {
    if (json is! Map) return const ChatBot();

    return ChatBot(
      enabled: json["enabled"] != false,
      paused: json["paused"] == true,
      active: json["active"] != false,
      until: chatDate(json["until"]),
      reason: chatText(json["reason"]),
      at: chatDate(json["at"]),
      by: ChatPerson.from(json["by"])
    );
  }
}

/// Company number that holds the conversation.
class ChatLine {
  const ChatLine({
    this.phone = "",
    this.purpose = "",
    this.transport = "",
    this.enabled = true
  });

  final String phone;
  final String purpose;

  /// `personal` (a phone linked by QR) or `cloud`.
  final String transport;
  final bool enabled;

  static ChatLine? from(dynamic json) {
    if (json is! Map) return null;

    return ChatLine(
      phone: chatText(json["phone"]),
      purpose: chatText(json["purpose"]),
      transport: chatText(json["transport"]),
      enabled: json["enabled"] != false
    );
  }
}

/// The measured stage of a conversation.
class ChatStage {
  const ChatStage({
    this.stage = "",
    this.label = "",
    this.level = ChatLevel.info,
    this.attention = false,
    this.since
  });

  final String stage;

  /// The backend's name for [stage]. On events it travels as `label` (never
  /// `name`, which is the customer's).
  final String label;
  final ChatLevel level;

  /// A person has work at this stage.
  final bool attention;
  final DateTime? since;

  bool get isEmpty => stage.isEmpty;

  factory ChatStage.from(dynamic json) {
    if (json is! Map) return const ChatStage();

    return ChatStage(
      stage: chatText(json["stage"]),
      label: chatText(json["label"]),
      level: ChatLevel.from(json["level"]),
      attention: json["attention"] == true,
      since: chatDate(json["since"])
    );
  }
}

/// One tag of a conversation, or of the catalog (`GET /aries/v1/chats/tags`).
///
/// The stage picks **one** place on the path of a sale; tags are **everything
/// that is true at once** (`unpaid` + `shipped` for a customer paying on
/// delivery). None is settable: each is measured from the fact that owns it,
/// and moves when a person does the thing (resolve, approve, state a handover).
class ChatTag {
  const ChatTag({
    required this.tag,
    this.name = "",
    this.group = "",
    this.level = ChatLevel.info,
    this.attention = false,
    this.since,
    this.tickets = const []
  });

  /// Code the state is keyed by (`question`, `unpaid`, `shipped`…).
  final String tag;

  /// What the chip says. The detail sends it as `label`, the catalog and the
  /// `chat/tags` event as `name`.
  final String name;

  /// `chat` · `stock` · `payment` · `delivery`.
  final String group;
  final ChatLevel level;

  /// A person of the company has work here.
  final bool attention;

  /// When it became true; only on a conversation's tags, when known.
  final DateTime? since;

  /// Ticket codes it was read from: a customer can have two sales in flight,
  /// and "paid" beside "unpaid" only reads right when each names its sale.
  final List<String> tickets;

  String get label => name.isNotEmpty ? name : tag;

  static ChatTag? from(dynamic json) {
    if (json is! Map) return null;

    final tag = chatText(json["tag"]);
    if (tag.isEmpty) return null;

    final label = chatText(json["label"]);

    return ChatTag(
      tag: tag,
      name: label.isNotEmpty ? label : chatText(json["name"]),
      group: chatText(json["group"]),
      level: ChatLevel.from(json["level"]),
      attention: json["attention"] == true,
      since: chatDate(json["since"]),
      tickets: chatCodes(json["tickets"])
    );
  }

  /// A full list (the detail's `tags`, the event's `detail`), in drawing order.
  static List<ChatTag> listOf(dynamic raw) => [
    if (raw is List)
      for (final entry in raw)
        ?ChatTag.from(entry)
  ];

  /// The catalog, compressed as `keys`/`values`.
  static List<ChatTag> catalogFrom(dynamic data) => [
    for (final row in catalogRows(data))
      ?ChatTag.from(row)
  ];
}

/// A row of the inbox.
class ChatModel {
  const ChatModel({
    required this.id,
    this.contact = "",
    this.name = "",
    this.channel = "",
    this.status = "",
    this.stage = const ChatStage(),
    this.waiting,
    this.answered = true,
    this.awaiting,
    this.method = "",
    this.held = 0,
    this.activity,
    this.created,
    this.bot = const ChatBot(),
    this.assignee,
    this.line,
    this.tags = const []
  });

  final String id;

  /// Customer's number.
  final String contact;

  /// WhatsApp profile name; may be empty.
  final String name;
  final String channel;

  /// `open` · `expired` · `closed`.
  final String status;
  final ChatStage stage;
  final ChatWaiting? waiting;

  /// `false`: the customer wrote and nobody answered yet.
  final bool answered;

  /// Since when the customer waits, null when they do not.
  final DateTime? awaiting;

  /// Payment method handed to the customer, if any.
  final String method;

  /// Units held for the customer.
  final int held;

  /// Last message in either direction.
  final DateTime? activity;
  final DateTime? created;
  final ChatBot bot;
  final ChatPerson? assignee;
  final ChatLine? line;

  /// Codes of the active tags, in drawing order. The row carries codes only:
  /// names and colours come from the catalog (`ChatsService.tagOf`).
  final List<String> tags;

  /// What the conversation is called on screen: the profile name, else the number.
  String get title => name.isNotEmpty ? name : contact;

  factory ChatModel.fromJson(Map<String, dynamic> json) => ChatModel(
    id: chatText(json["id"]),
    contact: chatText(json["contact"]),
    name: chatText(json["name"]),
    channel: chatText(json["channel"]),
    status: chatText(json["status"]),
    stage: ChatStage(
      stage: chatText(json["stage"]),
      label: chatText(json["label"]),
      level: ChatLevel.from(json["level"]),
      attention: json["attention"] == true,
      since: chatDate(json["since"])
    ),
    waiting: ChatWaiting.from(json["waiting"]),
    answered: json["answered"] != false,
    awaiting: chatDate(json["awaiting"]),
    method: chatText(json["method"]),
    held: chatInt(json["held"]),
    activity: chatDate(json["activity"]),
    created: chatDate(json["created"]),
    bot: ChatBot.from(json["bot"]),
    assignee: ChatPerson.from(json["assignee"]),
    line: ChatLine.from(json["line"]),
    tags: chatCodes(json["tags"])
  );

  /// The row after a `chat/message` event: only what that event carries.
  ChatModel touched(Map<String, dynamic> event) => _copy(
    name: event.containsKey("name") ? chatText(event["name"]) : name,
    status: event.containsKey("status") ? chatText(event["status"]) : status,
    activity: chatDate(event["activity"]) ?? activity,
    answered: event.containsKey("answered") ? event["answered"] != false : answered,
    awaiting: event.containsKey("awaiting") ? chatDate(event["awaiting"]) : awaiting,
    clearAwaiting: event.containsKey("awaiting") && event["awaiting"] == null
  );

  /// The row after a handover (`chat/handover`, or a pause/resume/assign answer).
  /// Both values are replaced whole.
  ChatModel handedOver({required ChatBot bot, required ChatPerson? assignee}) =>
    _copy(bot: bot, assignee: assignee, clearAssignee: assignee == null);

  ChatModel staged(ChatStage stage) => _copy(stage: stage);

  ChatModel flagged(ChatWaiting? waiting) =>
    _copy(waiting: waiting, clearWaiting: waiting == null);

  /// The row after `chat/tags`: the whole set is replaced, never merged.
  ChatModel tagged(List<String> tags) => _copy(tags: tags);

  ChatModel _copy({
    String? name,
    String? status,
    ChatStage? stage,
    ChatWaiting? waiting,
    bool clearWaiting = false,
    bool? answered,
    DateTime? awaiting,
    bool clearAwaiting = false,
    DateTime? activity,
    ChatBot? bot,
    ChatPerson? assignee,
    bool clearAssignee = false,
    List<String>? tags
  }) => ChatModel(
    id: id,
    contact: contact,
    name: name ?? this.name,
    channel: channel,
    status: status ?? this.status,
    stage: stage ?? this.stage,
    waiting: clearWaiting ? null : (waiting ?? this.waiting),
    answered: answered ?? this.answered,
    awaiting: clearAwaiting ? null : (awaiting ?? this.awaiting),
    method: method,
    held: held,
    activity: activity ?? this.activity,
    created: created,
    bot: bot ?? this.bot,
    assignee: clearAssignee ? null : (assignee ?? this.assignee),
    line: line,
    tags: tags ?? this.tags
  );
}

/// One page of the inbox.
class ChatsPage {
  const ChatsPage({
    required this.chats,
    this.page = 1,
    this.size = 0,
    this.total = 0,
    this.isLoaded = true
  });

  final List<ChatModel> chats;
  final int page;
  final int size;
  final int total;

  /// `false` when the answer was not an inbox page at all.
  final bool isLoaded;

  factory ChatsPage.fromResponse(dynamic data) {
    if (data is! Map || data["chats"] == null) {
      return const ChatsPage(chats: [], isLoaded: false);
    }

    return ChatsPage(
      page: chatInt(data["page"], fallback: 1),
      size: chatInt(data["size"]),
      total: chatInt(data["total"]),
      chats: [
        for (final row in catalogRows(data["chats"]))
          if (ChatModel.fromJson(row) case final chat when chat.id.isNotEmpty) chat
      ]
    );
  }
}

/// Counters of the inbox tabs (`GET /aries/v1/chats/summary`).
class ChatSummary {
  const ChatSummary({this.awaiting, this.attention = 0, this.paused = 0, this.mine = 0});

  /// Open conversations waiting for an answer. **Null when it could not be
  /// measured**, which is not zero.
  final int? awaiting;
  final int attention;
  final int paused;
  final int mine;

  factory ChatSummary.from(dynamic json) {
    if (json is! Map) return const ChatSummary();

    return ChatSummary(
      awaiting: json["awaiting"] == null ? null : chatInt(json["awaiting"]),
      attention: chatInt(json["attention"]),
      paused: chatInt(json["paused"]),
      mine: chatInt(json["mine"])
    );
  }
}

/// A stage of the catalog (`GET /aries/v1/chats/stages`).
class ChatStageOption {
  const ChatStageOption({
    required this.stage,
    this.name = "",
    this.level = ChatLevel.info,
    this.attention = false,
    this.manual = false
  });

  final String stage;
  final String name;
  final ChatLevel level;
  final bool attention;

  /// Can be set by hand with `PUT /aries/v1/chats/stage`.
  final bool manual;

  static List<ChatStageOption> listFrom(dynamic data) => [
    for (final row in catalogRows(data))
      if (chatText(row["stage"]) case final stage when stage.isNotEmpty)
        ChatStageOption(
          stage: stage,
          name: chatText(row["name"]),
          level: ChatLevel.from(row["level"]),
          attention: row["attention"] == true,
          manual: row["manual"] == true
        )
  ];
}

// ─── Parsing helpers ──────────────────────────────────────────────────────────

String chatText(dynamic raw) => raw?.toString().trim() ?? "";

int chatInt(dynamic raw, {int fallback = 0}) {
  if (raw is num) return raw.toInt();
  return int.tryParse("$raw") ?? fallback;
}

double chatDouble(dynamic raw, {double fallback = 0}) {
  if (raw is num) return raw.toDouble();
  return double.tryParse("$raw") ?? fallback;
}

/// A list of codes (`tags`, `tickets`), blanks dropped.
List<String> chatCodes(dynamic raw) => [
  if (raw is List)
    for (final entry in raw)
      if (chatText(entry) case final code when code.isNotEmpty) code
];

/// ISO-8601 UTC as it travels, or null.
DateTime? chatDate(dynamic raw) {
  if (raw == null) return null;
  return DateTime.tryParse(raw.toString());
}

/// A socket payload as a string-keyed map, or null.
Map<String, dynamic>? chatEvent(dynamic data) {
  if (data is! Map) return null;
  return data.map((key, value) => MapEntry(key.toString(), value));
}
