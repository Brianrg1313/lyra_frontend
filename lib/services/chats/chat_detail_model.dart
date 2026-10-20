// SERVICES
import 'package:app/services/chats/chat_model.dart';

/// The attention mark of a conversation (`attention` on the detail, and every
/// entry of its [also]).
class ChatAttention {
  const ChatAttention({
    required this.kind,
    this.stage = "",
    this.reason = "",
    this.detail = "",
    this.partial = false,
    this.since,
    this.count = 0,
    this.questions = const [],
    this.also = const []
  });

  final ChatWaiting kind;

  /// Where it happened: for `pending`, `question` · `payment` · `confirmation`.
  final String stage;
  final String reason;

  /// Text for the team (the customer's question(s), one per line, or the
  /// provider error). **Internal: never shown to the customer.**
  final String detail;

  /// Part of the answer reached the customer before a failure: they see a
  /// message cut in half.
  final bool partial;
  final DateTime? since;

  /// On `failure`: failed turns in a row.
  final int count;

  /// On `question`: each question the assistant left with the team, answered
  /// one by one ([ChatThreadService.answer]).
  final List<ChatQuestion> questions;

  /// More work on the same conversation, less urgent.
  final List<ChatAttention> also;

  static ChatAttention? from(dynamic json) {
    if (json is! Map) return null;

    final kind = ChatWaiting.from(json["kind"]);
    if (kind == null) return null;

    return ChatAttention(
      kind: kind,
      stage: chatText(json["stage"]),
      reason: chatText(json["reason"]),
      detail: json["detail"]?.toString().trim() ?? "",
      partial: json["partial"] == true,
      since: chatDate(json["since"]),
      count: chatInt(json["count"]),
      questions: [
        if (json["questions"] is List)
          for (final entry in json["questions"] as List)
            ?ChatQuestion.from(entry)
      ],
      also: [
        if (json["also"] is List)
          for (final entry in json["also"] as List)
            ?ChatAttention.from(entry)
      ]
    );
  }

  /// Every mark on the conversation, most urgent first.
  List<ChatAttention> get all => [this, ...also];
}

/// One question the assistant promised the customer to confirm (`ask_team`).
/// Its [id] is what an answer names (`QUESTION_ID`).
class ChatQuestion {
  const ChatQuestion({required this.id, required this.text, this.since});

  final String id;

  /// The question in the assistant's words. **Internal: never shown to the
  /// customer.**
  final String text;
  final DateTime? since;

  static ChatQuestion? from(dynamic json) {
    if (json is! Map) return null;

    final id = chatText(json["id"]);
    final text = chatText(json["text"]);
    if (id.isEmpty || text.isEmpty) return null;

    return ChatQuestion(id: id, text: text, since: chatDate(json["since"]));
  }
}

/// Payment state of the conversation.
class ChatPayment {
  const ChatPayment({required this.state, this.method = "", this.at});

  /// `handed` (account given) · `claimed` (says they paid) · `settled`.
  final String state;
  final String method;
  final DateTime? at;

  static ChatPayment? from(dynamic json) {
    if (json is! Map) return null;

    final state = chatText(json["state"]);
    if (state.isEmpty) return null;

    return ChatPayment(
      state: state,
      method: chatText(json["method"]),
      at: chatDate(json["at"])
    );
  }
}

/// A product the customer showed interest in or has units held of.
class ChatCartItem {
  const ChatCartItem({
    required this.id,
    this.label = "",
    this.state = "",
    this.qty = 0,
    this.available,
    this.gone = false
  });

  final String id;
  final String label;

  /// `interest` · `reserved`.
  final String state;
  final int qty;
  final int? available;

  /// Can no longer be sold as asked.
  final bool gone;

  bool get isReserved => state == "reserved";

  static ChatCartItem? from(dynamic json) {
    if (json is! Map) return null;

    final id = chatText(json["id"]);
    if (id.isEmpty) return null;

    return ChatCartItem(
      id: id,
      label: chatText(json["label"]),
      state: chatText(json["state"]),
      qty: chatInt(json["qty"]),
      available: json["available"] == null ? null : chatInt(json["available"]),
      gone: json["gone"] == true
    );
  }
}

/// What one area of the session spent (`usage.areas.*`).
class ChatUsageArea {
  const ChatUsageArea({this.requests = 0, this.input = 0, this.output = 0, this.cost = 0});

  final int requests;
  final int input;
  final int output;

  /// USD.
  final double cost;

  bool get ran => requests > 0 || cost > 0;

  static ChatUsageArea from(dynamic json) {
    if (json is! Map) return const ChatUsageArea();

    return ChatUsageArea(
      requests: chatInt(json["requests"]),
      input: chatInt(json["input"]),
      output: chatInt(json["output"]),
      cost: chatDouble(json["cost"])
    );
  }
}

/// What this conversation session cost the company in AI (`usage` on the
/// detail): every model that ran for it, as the providers billed it.
///
/// A session no model ran for is a measured zero (people answered it); the
/// backend sends `null` when it could not read the spend, and [from] keeps
/// that apart from zero — a zero is a claim.
class ChatUsage {
  const ChatUsage({
    this.cost = 0,
    this.input = 0,
    this.output = 0,
    this.cached = 0,
    this.requests = 0,
    this.areas = const {}
  });

  /// USD, what the company is charged (a cached read at the full input rate).
  final double cost;

  /// Includes the system prompt, the tools and the history resent every round.
  final int input;

  /// Includes the reasoning a model spent.
  final int output;

  /// The part of [input] served from the provider's cache: a split, not an
  /// addend.
  final int cached;
  final int requests;

  /// `replies` · `routing` · `media` · `research` · `embeddings`, in the
  /// backend's order.
  final Map<String, ChatUsageArea> areas;

  bool get isEmpty => requests == 0 && cost == 0;

  static ChatUsage? from(dynamic json) {
    if (json is! Map) return null;

    return ChatUsage(
      cost: chatDouble(json["cost"]),
      input: chatInt(json["input"]),
      output: chatInt(json["output"]),
      cached: chatInt(json["cached"]),
      requests: chatInt(json["requests"]),
      areas: {
        if (json["areas"] is Map)
          for (final entry in (json["areas"] as Map).entries)
            "${entry.key}": ChatUsageArea.from(entry.value)
      }
    );
  }
}

/// One conversation in full (`GET /aries/v1/chats/detail/:ID`): the header and
/// side facts of the open chat.
class ChatDetailModel {
  const ChatDetailModel({
    required this.id,
    this.contact = "",
    this.name = "",
    this.channel = "",
    this.status = "",
    this.created,
    this.activity,
    this.line,
    this.stage = const ChatStage(),
    this.tags = const [],
    this.answered = true,
    this.awaiting,
    this.attempts = 0,
    this.attention,
    this.bot = const ChatBot(),
    this.assignee,
    this.payment,
    this.proofs = 0,
    this.cart = const [],
    this.sessions = 1,
    this.usage
  });

  final String id;
  final String contact;
  final String name;
  final String channel;
  final String status;
  final DateTime? created;
  final DateTime? activity;
  final ChatLine? line;
  final ChatStage stage;

  /// Active tags with `since` and `tickets`, in drawing order.
  final List<ChatTag> tags;
  final bool answered;
  final DateTime? awaiting;

  /// Automatic bot retries over the current wait (max 3).
  final int attempts;
  final ChatAttention? attention;
  final ChatBot bot;
  final ChatPerson? assignee;
  final ChatPayment? payment;

  /// Payment proofs the customer sent.
  final int proofs;
  final List<ChatCartItem> cart;

  /// Sessions of this customer on this number. Above one, older history can be
  /// read with `ALL=1`.
  final int sessions;

  /// What the session cost in AI. Null when the backend could not read it, and
  /// on a detail drawn from the inbox row (before the read).
  final ChatUsage? usage;

  String get title => name.isNotEmpty ? name : contact;

  factory ChatDetailModel.fromJson(Map<String, dynamic> json) => ChatDetailModel(
    id: chatText(json["id"]),
    contact: chatText(json["contact"]),
    name: chatText(json["name"]),
    channel: chatText(json["channel"]),
    status: chatText(json["status"]),
    created: chatDate(json["created"]),
    activity: chatDate(json["activity"]),
    line: ChatLine.from(json["line"]),
    stage: ChatStage.from(json["stage"]),
    tags: ChatTag.listOf(json["tags"]),
    answered: json["answered"] != false,
    awaiting: chatDate(json["awaiting"]),
    attempts: chatInt(json["attempts"]),
    attention: ChatAttention.from(json["attention"]),
    bot: ChatBot.from(json["bot"]),
    assignee: ChatPerson.from(json["assignee"]),
    payment: ChatPayment.from(json["payment"]),
    proofs: chatInt(json["proofs"]),
    cart: [
      if (json["cart"] is List)
        for (final entry in json["cart"] as List)
          ?ChatCartItem.from(entry)
    ],
    sessions: chatInt(json["sessions"], fallback: 1),
    usage: ChatUsage.from(json["usage"])
  );

  /// Detail drawn from the inbox row, so the header shows before the read.
  /// The row holds tag codes only; [tagOf] names them from the catalog.
  factory ChatDetailModel.fromRow(ChatModel row, {ChatTag Function(String code)? tagOf}) => ChatDetailModel(
    id: row.id,
    contact: row.contact,
    name: row.name,
    channel: row.channel,
    status: row.status,
    created: row.created,
    activity: row.activity,
    line: row.line,
    stage: row.stage,
    tags: [for (final code in row.tags) tagOf?.call(code) ?? ChatTag(tag: code)],
    answered: row.answered,
    awaiting: row.awaiting,
    bot: row.bot,
    assignee: row.assignee
  );

  ChatDetailModel copyWith({
    String? name,
    String? status,
    DateTime? activity,
    ChatStage? stage,
    List<ChatTag>? tags,
    bool? answered,
    DateTime? Function()? awaiting,
    ChatAttention? Function()? attention,
    ChatBot? bot,
    ChatPerson? Function()? assignee
  }) => ChatDetailModel(
    id: id,
    contact: contact,
    name: name ?? this.name,
    channel: channel,
    status: status ?? this.status,
    created: created,
    activity: activity ?? this.activity,
    line: line,
    stage: stage ?? this.stage,
    tags: tags ?? this.tags,
    answered: answered ?? this.answered,
    awaiting: awaiting == null ? this.awaiting : awaiting(),
    attempts: attempts,
    attention: attention == null ? this.attention : attention(),
    bot: bot ?? this.bot,
    assignee: assignee == null ? this.assignee : assignee(),
    payment: payment,
    proofs: proofs,
    cart: cart,
    sessions: sessions,
    usage: usage
  );
}
