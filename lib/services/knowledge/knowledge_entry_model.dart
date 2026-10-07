/// Whether Lyra offers an entry today, as the backend computed it on the read
/// (`GET /knowledge/`). Never derived here: the dates are the company's
/// calendar days, and only the backend knows which day it is there.
///
/// In the backend's order: an entry with no answer is [pending] whatever its
/// switch says, because the switch is not what is missing.
enum KnowledgeState {
  /// No answer yet: Lyra never gives it. What the section is for.
  pending,

  /// Turned off by the company, while its policy is rewritten.
  off,

  /// Its first day has not come.
  scheduled,

  /// Its last day has passed.
  expired,

  /// Lyra gives it.
  active;

  static KnowledgeState from(Object? value) => switch (value) {
    "pending" => pending,
    "off" => off,
    "scheduled" => scheduled,
    "expired" => expired,
    _ => active
  };
}

/// Who wrote the question.
enum KnowledgeSource {
  /// Somebody at the company, from this section.
  panel,

  /// Lyra, from a question a customer asked that she promised to confirm
  /// (`ask_team`). It arrives without an answer.
  assistant;

  static KnowledgeSource from(Object? value) =>
    value == "assistant" ? assistant : panel;
}

/// The one branch an answer is about (its hours, its address).
class KnowledgeBranch {
  const KnowledgeBranch({required this.id, required this.name});

  final String id;
  final String name;

  static KnowledgeBranch? fromJson(Object? json) {
    if (json is! Map) return null;

    final id = json["id"]?.toString() ?? "";

    return id.isEmpty ? null : KnowledgeBranch(id: id, name: json["name"]?.toString() ?? "");
  }
}

/// A product an answer is about: a record of one of the company's tables,
/// named by the backend on every read (the register's name for it).
class KnowledgeProduct {
  const KnowledgeProduct({required this.id, required this.table, this.name = ""});

  /// The record's id.
  final String id;

  /// The table it is a row of. Travels back on every write: a product is
  /// named by both.
  final String table;

  /// What it is called. Empty on a row that holds nothing textual.
  final String name;

  static KnowledgeProduct? fromJson(Object? json) {
    if (json is! Map) return null;

    final id = json["id"]?.toString() ?? "";
    final table = json["table"]?.toString() ?? "";

    if (id.isEmpty || table.isEmpty) return null;

    return KnowledgeProduct(id: id, table: table, name: json["name"]?.toString() ?? "");
  }

  @override
  bool operator ==(Object other) => other is KnowledgeProduct && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// One frequent question of the company, as a row of `GET /knowledge/`.
///
/// The [answer] is not what Lyra sends: it is what she knows about the topic,
/// in the company's own words, and she says it in her voice without adding a
/// condition, figure or deadline it does not state. That is why it is called
/// the answer's context on screen.
class KnowledgeEntry {
  const KnowledgeEntry({
    required this.id,
    required this.question,
    this.answer = "",
    this.tags = const [],
    this.language = "es",
    this.position = 0,
    this.enabled = true,
    this.source = KnowledgeSource.panel,
    this.chat,
    this.asks = 0,
    this.asked,
    this.branch,
    this.from,
    this.until,
    this.products = const [],
    this.state = KnowledgeState.active,
    this.date
  });

  final String id;

  /// How a customer asks it.
  final String question;

  /// Empty while it waits for one ([isPending]).
  final String answer;

  /// Extra words that should find it and are not in the question.
  final List<String> tags;
  final String language;
  final int position;
  final bool enabled;
  final KnowledgeSource source;

  /// The conversation Lyra took it from.
  final String? chat;

  /// Customers who asked it while nothing answered it.
  final int asks;

  /// When the last of them did.
  final DateTime? asked;

  /// Null is the whole company.
  final KnowledgeBranch? branch;

  /// First and last company-local day Lyra offers it, as `YYYY-MM-DD`.
  final String? from;
  final String? until;
  final List<KnowledgeProduct> products;
  final KnowledgeState state;
  final DateTime? date;

  bool get isPending => state == KnowledgeState.pending;

  /// Whether it says where or when it holds.
  bool get isScoped =>
    branch != null || products.isNotEmpty || from != null || until != null;

  KnowledgeEntry copyWith({bool? enabled, KnowledgeState? state}) => KnowledgeEntry(
    id: id,
    question: question,
    answer: answer,
    tags: tags,
    language: language,
    position: position,
    enabled: enabled ?? this.enabled,
    source: source,
    chat: chat,
    asks: asks,
    asked: asked,
    branch: branch,
    from: from,
    until: until,
    products: products,
    state: state ?? this.state,
    date: date
  );

  factory KnowledgeEntry.fromJson(Map json) {
    final tags = json["tags"];
    final products = json["products"];

    return KnowledgeEntry(
      id: json["id"]?.toString() ?? "",
      question: json["question"]?.toString() ?? "",
      answer: json["answer"]?.toString() ?? "",
      tags: tags is List ? [for (final tag in tags) tag.toString()] : const [],
      language: json["language"]?.toString() ?? "es",
      position: int.tryParse("${json["position"]}") ?? 0,
      enabled: json["enabled"] == true || json["enabled"] == 1,
      source: KnowledgeSource.from(json["source"]),
      chat: _text(json["chat"]),
      asks: int.tryParse("${json["asks"]}") ?? 0,
      asked: DateTime.tryParse(json["asked"]?.toString() ?? "")?.toLocal(),
      branch: KnowledgeBranch.fromJson(json["branch"]),
      from: _text(json["from"]),
      until: _text(json["until"]),
      products: products is List
        ? [for (final product in products) ?KnowledgeProduct.fromJson(product)]
        : const [],
      state: KnowledgeState.from(json["state"]),
      date: DateTime.tryParse(json["date"]?.toString() ?? "")?.toLocal()
    );
  }

  /// The compressed list (`{keys, values}`) the backend answers with.
  static List<KnowledgeEntry> fromResponse(dynamic data) {
    if (data is List) {
      return [
        for (final row in data)
          if (row is Map) KnowledgeEntry.fromJson(row)
      ];
    }

    if (data is Map) {
      final keys = data["keys"];
      final rows = data["values"];

      if (keys is List && rows is List) {
        return [
          for (final row in rows)
            if (row is List)
              KnowledgeEntry.fromJson({
                for (int i = 0; i < keys.length && i < row.length; i++)
                  keys[i].toString(): row[i]
              })
        ];
      }
    }

    return const [];
  }

  static String? _text(Object? value) {
    final text = value?.toString() ?? "";

    return text.isEmpty ? null : text;
  }
}
