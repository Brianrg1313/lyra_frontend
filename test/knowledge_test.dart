import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/knowledge/knowledge_entry_model.dart';
import 'package:app/services/knowledge/knowledge_request.dart';
import 'package:app/screens/home/sections/knowledge/knowledge_list.dart';
import 'package:app/screens/home/sections/knowledge/state/knowledge_view.dart';

/// `GET /knowledge/` compressed, as the backend answers it.
Map<String, dynamic> _response() => {
  "keys": [
    "id", "question", "answer", "tags", "language", "position", "enabled", "pending", "source", "chat",
    "asks", "asked", "branch", "from", "until", "products", "state", "date"
  ],
  "values": [
    [
      "k-1", "¿Venden al mayor?", "", [], "es", 1, true, true, "assistant", "65f000000000000000000000",
      4, "2026-10-07T02:49:12Z", null, null, null, [], "pending", "2026-10-07T02:49:12Z"
    ],
    [
      "k-2", "¿Cuál es el horario?", "Lunes a viernes 9 a 18.", ["horario"], "es", 2, true, false, "panel", null,
      0, null, {"id": "b-1", "name": "Centro"}, "2026-01-01", "2026-12-31",
      [{"id": "p-1", "table": "t-1", "name": "iPhone 15"}, {"id": "", "table": "t-1"}], "active", "2026-10-07T02:49:12Z"
    ],
    [
      "k-3", "¿Tienen promoción?", "2x1 en cremas.", [], "es", 3, true, false, "panel", null,
      0, null, null, null, "2026-09-30", [], "expired", null
    ],
    [
      "k-4", "¿Hacen envíos?", "", [], "es", 4, true, true, "assistant", null,
      9, "2026-10-01T10:00:00Z", null, null, null, [], "pending", null
    ]
  ]
};

void main() {
  final entries = KnowledgeEntry.fromResponse(_response());

  test('a compressed list is read into entries', () {
    expect(entries.map((entry) => entry.id), ["k-1", "k-2", "k-3", "k-4"]);

    final pending = entries[0];
    expect(pending.isPending, isTrue);
    expect(pending.source, KnowledgeSource.assistant);
    expect(pending.asks, 4);
    expect(pending.asked, isNotNull);
    expect(pending.chat, "65f000000000000000000000");

    final scoped = entries[1];
    expect(scoped.state, KnowledgeState.active);
    expect(scoped.branch?.name, "Centro");
    expect(scoped.from, "2026-01-01");
    expect(scoped.until, "2026-12-31");
    // A product without its id is not one.
    expect(scoped.products.map((product) => product.name), ["iPhone 15"]);
    expect(scoped.isScoped, isTrue);

    expect(entries[2].state, KnowledgeState.expired);
  });

  test('the bodies carry the whole scope, an empty one clearing it', () {
    const draft = KnowledgeDraft(
      question: "  ¿Tienen garantía? ",
      answer: "Solo Apple con factura.",
      tags: ["garantía"],
      until: "2026-12-31",
      products: [KnowledgeProduct(id: "p-1", table: "t-1", name: "iPhone 15")]
    );

    expect(createKnowledgeRequest(draft), {
      "QUESTION": "¿Tienen garantía?",
      "ANSWER": "Solo Apple con factura.",
      "TAGS": ["garantía"],
      "BRANCH_ID": "",
      "VALID_FROM": "",
      "VALID_UNTIL": "2026-12-31",
      "PRODUCTS": [{"TABLE_ID": "t-1", "PRODUCT_ID": "p-1"}]
    });

    expect(editKnowledgeRequest(id: "k-1", draft: draft)["ID"], "k-1");
    expect(toggleKnowledgeRequest(id: "k-1", enabled: false), {"ID": "k-1", "ENABLED": 0});
  });

  test('tags are split on commas, trimmed, without repeats', () {
    expect(splitKnowledgeTags(" mayor, docena ,, Mayor, al por mayor "), ["mayor", "docena", "al por mayor"]);
  });

  test('the questions waiting go first, the most asked on top', () {
    expect(sortKnowledge(entries).map((entry) => entry.id), ["k-4", "k-1", "k-2", "k-3"]);
  });

  test('the filters and the branch narrow the list', () {
    final view = KnowledgeView();
    List<String> shown() => [for (final entry in entries) if (view.accepts(entry)) entry.id];

    view.show(KnowledgeFilter.pending);
    expect(shown(), ["k-1", "k-4"]);

    view.show(KnowledgeFilter.active);
    expect(shown(), ["k-2"]);

    view.show(KnowledgeFilter.inactive);
    expect(shown(), ["k-3"]);

    view
      ..show(KnowledgeFilter.all)
      ..inBranch("b-1");
    expect(shown(), ["k-2"]);

    view.inBranch(KnowledgeView.companyWide);
    expect(shown(), ["k-1", "k-3", "k-4"]);
    expect(view.isFiltered, isTrue);
  });
}
