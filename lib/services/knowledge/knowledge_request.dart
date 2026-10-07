/// Bodies of the writes for a frequent question: creation
/// (`POST /v1/knowledge/`), editing (`PUT /v1/knowledge/`) and retiring
/// (`DELETE /v1/knowledge/`).
///
/// The business does not go in the body: it travels in the `business_id`
/// header of every request (see `useBusiness` in `toolkit/api.dart`).
///
/// Every scope key travels on both writes, emptied when there is none, and the
/// backend reads an empty one as "clear it": `BRANCH_ID` `""` is the whole
/// company, `VALID_FROM` / `VALID_UNTIL` `""` no limit, `PRODUCTS` `[]` none in
/// particular. `TAGS` and `PRODUCTS` replace the whole list.
///
/// ```json
/// {
///   "QUESTION": "¿Los productos tienen garantía?",
///   "ANSWER": "Solo productos Apple con factura, por defectos de fábrica…",
///   "TAGS": ["garantía", "reclamo"],
///   "BRANCH_ID": "",
///   "VALID_FROM": "",
///   "VALID_UNTIL": "2026-12-31",
///   "PRODUCTS": [{"TABLE_ID": "…", "PRODUCT_ID": "…"}]
/// }
/// ```
library;

// SERVICES
import 'package:app/services/knowledge/knowledge_entry_model.dart';

/// What the form collects: the same for a new question and an edited one.
class KnowledgeDraft {
  const KnowledgeDraft({
    required this.question,
    this.answer = "",
    this.tags = const [],
    this.branchId = "",
    this.from = "",
    this.until = "",
    this.products = const []
  });

  final String question;

  /// Empty leaves the question waiting: Lyra does not use it.
  final String answer;
  final List<String> tags;

  /// Empty is the whole company.
  final String branchId;

  /// `YYYY-MM-DD`, or empty for no limit.
  final String from;
  final String until;
  final List<KnowledgeProduct> products;

  Map<String, dynamic> get _body => {
    "QUESTION": question.trim(),
    "ANSWER": answer.trim(),
    "TAGS": tags,
    "BRANCH_ID": branchId,
    "VALID_FROM": from,
    "VALID_UNTIL": until,
    "PRODUCTS": [
      for (final product in products)
        {"TABLE_ID": product.table, "PRODUCT_ID": product.id}
    ]
  };
}

/// Builds the creation body. A new question is turned on: with no answer it
/// waits anyway, and with one it is what the company wanted to say.
Map<String, dynamic> createKnowledgeRequest(KnowledgeDraft draft) => draft._body;

/// Builds the edit body: the whole form, since every key replaces what the
/// entry had.
Map<String, dynamic> editKnowledgeRequest({
  required String id,
  required KnowledgeDraft draft
}) => {"ID": id, ...draft._body};

/// Turns an entry on or off, without touching anything else.
Map<String, dynamic> toggleKnowledgeRequest({
  required String id,
  required bool enabled
}) => {"ID": id, "ENABLED": enabled ? 1 : 0};

/// Retires an entry for good. To stop Lyra giving it while it is rewritten,
/// turn it off instead ([toggleKnowledgeRequest]).
Map<String, dynamic> deleteKnowledgeRequest({required String id}) => {"ID": id};

/// The tags typed in one field, comma-separated, as the list the backend
/// stores: trimmed, empty ones and repeats dropped.
List<String> splitKnowledgeTags(String raw) {
  final seen = <String>{};

  return [
    for (final tag in raw.split(","))
      if (tag.trim().isNotEmpty && seen.add(tag.trim().toLowerCase())) tag.trim()
  ];
}
