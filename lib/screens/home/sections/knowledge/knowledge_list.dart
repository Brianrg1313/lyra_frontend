import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/knowledge/knowledge_entry_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/section_message.dart';

import './knowledge_row.dart';
import './state/knowledge_view.dart';

/// The questions, narrowed by the [view] and the header's search.
///
/// **The ones waiting for a context go first**, the most asked on top: they
/// are what the section asks the company to do, and the count is how many
/// customers got a person's "we'll confirm it" for lack of it. The rest keep
/// the company's order.
///
/// The search reads everything a question is found by on screen: the
/// question, its context, its words, its branch and its products.
class KnowledgeList extends StatelessWidget {
  const KnowledgeList({
    super.key,
    required this.entries,
    required this.view,
    required this.query
  });

  final List<KnowledgeEntry> entries;
  final KnowledgeView view;
  final ValueListenable<String> query;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
    valueListenable: query,
    builder: (context, value, _) {
      final shown = sortKnowledge([
        for (final entry in entries)
          if (view.accepts(entry) && _matches(entry, value)) entry
      ]);

      if (shown.isEmpty) {
        return SectionMessage(
          icon: CI.search,
          title: value.isEmpty
            ? S.of(context).knowledge_filter_empty
            : S.of(context).knowledge_search_empty
        );
      }

      return ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: shown.length,
        separatorBuilder: (_, _) => SizedBox(height: AppSize.gap),
        itemBuilder: (context, index) => KnowledgeRow(
          key: ValueKey(shown[index].id),
          entry: shown[index]
        )
      );
    }
  );

  static bool _matches(KnowledgeEntry entry, String query) {
    if (query.isEmpty) return true;

    return [
      entry.question,
      entry.answer,
      ...entry.tags,
      entry.branch?.name ?? "",
      for (final product in entry.products) product.name
    ].any((text) => text.toLowerCase().contains(query));
  }
}

/// The order the list draws: waiting ones first, most asked and then most
/// recently asked on top; the rest as the backend returned them (the
/// company's order).
@visibleForTesting
List<KnowledgeEntry> sortKnowledge(List<KnowledgeEntry> entries) {
  final indexed = entries.indexed.toList()
    ..sort((one, other) {
      final (oneIndex, a) = one;
      final (otherIndex, b) = other;

      if (a.isPending != b.isPending) return a.isPending ? -1 : 1;

      if (a.isPending) {
        final asks = b.asks.compareTo(a.asks);
        if (asks != 0) return asks;

        final asked = (b.asked ?? DateTime(0)).compareTo(a.asked ?? DateTime(0));
        if (asked != 0) return asked;
      }

      return oneIndex.compareTo(otherIndex);
    });

  return [for (final (_, entry) in indexed) entry];
}
