/// Who wrote a line of the assistant's conversation, as the backend names it:
/// the person, the assistant, or an `event` (what happened when the person
/// pressed a confirmation's button: shown, never a turn the model reads).
enum AssistantLineRole {
  person,
  assistant,
  event;

  static AssistantLineRole from(Object? value) => switch (value) {
    "assistant" => AssistantLineRole.assistant,
    "event" => AssistantLineRole.event,
    _ => AssistantLineRole.person
  };
}

/// One operation the assistant ran to answer (`knowledge.list`, `stock.adjust`).
class AssistantCall {
  const AssistantCall({required this.operation, required this.status, this.effect});

  factory AssistantCall.fromJson(Map json) => AssistantCall(
    operation: json["operation"] as String? ?? "",
    status: json["status"] as String? ?? "done",
    effect: json["effect"] as String?
  );

  final String operation;

  /// `done`, `failed` or `confirm` (held for the person's yes).
  final String status;

  /// `read`, `write`, `destructive`…; `app` for a tool this app ran
  /// (`app.open`, `app.view`).
  final String? effect;

  bool get failed => status == "failed";
}

/// One line of the conversation (`GET/POST /harness/assistant`).
class AssistantLine {
  const AssistantLine({
    required this.id,
    required this.role,
    required this.text,
    this.date,
    this.calls = const [],
    this.operation,
    this.outcome
  });

  factory AssistantLine.fromJson(Map json) => AssistantLine(
    id: "${json["id"] ?? ""}",
    role: AssistantLineRole.from(json["role"]),
    text: json["text"] as String? ?? "",
    date: DateTime.tryParse("${json["date"] ?? ""}")?.toLocal(),
    calls: [
      for (final call in json["calls"] as List? ?? const [])
        if (call is Map) AssistantCall.fromJson(call)
    ],
    operation: json["operation"] as String?,
    outcome: json["outcome"] as String?
  );

  final String id;
  final AssistantLineRole role;
  final String text;
  final DateTime? date;

  /// An assistant line's operations.
  final List<AssistantCall> calls;

  /// An event's operation and how it ended: `done`, `failed`, `declined`,
  /// `expired`.
  final String? operation;
  final String? outcome;
}

/// Something the assistant wants to do that waits for the person's yes: a
/// delete, a bulk import, a message to a customer. The model never confirms
/// it; the panel's buttons do, by this [id].
class AssistantPending {
  const AssistantPending({required this.id, required this.summary, this.operation, this.expires});

  factory AssistantPending.fromJson(Map json) => AssistantPending(
    id: "${json["id"] ?? ""}",
    summary: json["summary"] as String? ?? "",
    operation: json["operation"] as String?,
    expires: DateTime.tryParse("${json["expires"] ?? ""}")?.toLocal()
  );

  final String id;

  /// Exactly what a yes does.
  final String summary;
  final String? operation;

  /// After this a yes runs nothing (`outcome: expired`).
  final DateTime? expires;

  bool expiredAt(DateTime now) => expires != null && !now.isBefore(expires!);
}

/// What one read, one message or one button answered, and what the socket
/// carries: the conversation's id and the lines and pendings that come with
/// it. Read whole for `GET`; new lines only for everything else.
class AssistantBatch {
  const AssistantBatch({this.thread, this.lines = const [], this.pending = const []});

  /// `GET` names the conversation `id`; `POST` and the socket, `thread`.
  factory AssistantBatch.fromJson(Object? json) {
    if (json is! Map) return const AssistantBatch();

    final thread = json["thread"] ?? json["id"];

    return AssistantBatch(
      thread: thread == null ? null : "$thread",
      lines: [
        for (final line in json["messages"] as List? ?? const [])
          if (line is Map) AssistantLine.fromJson(line)
      ],
      pending: [
        for (final pending in json["pending"] as List? ?? const [])
          if (pending is Map) AssistantPending.fromJson(pending)
      ]
    );
  }

  /// Null while the person has no open conversation.
  final String? thread;
  final List<AssistantLine> lines;
  final List<AssistantPending> pending;
}
