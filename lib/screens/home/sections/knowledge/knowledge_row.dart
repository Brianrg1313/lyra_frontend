import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/knowledge/knowledge_entry_model.dart';

import './knowledge_actions.dart';
import './knowledge_format.dart';
import './knowledge_options_button.dart';
import './knowledge_state_tag.dart';

/// One question: how customers ask it and its state; its context below, or
/// that it has none; and in a last line who asked it and where and when it
/// holds. Tapping it opens it in the form; the options button turns it off or
/// deletes it without opening it.
class KnowledgeRow extends StatelessWidget {
  const KnowledgeRow({super.key, required this.entry});

  final KnowledgeEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);
    final lyra = entry.source == KnowledgeSource.assistant;
    final scope = _scope(context);

    return FeedbackButton(
      action: () => openKnowledgeForm(context, entry: entry),
      color: scheme.surfaceOver,
      padding: EdgeInsets.all(AppSize.spaceS),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: AppSize.action,
          height: AppSize.action,
          decoration: BoxDecoration(
            color: entry.isPending
              ? scheme.accent.withValues(alpha: 0.12)
              : scheme.surfaceOver,
            borderRadius: BorderRadius.circular(AppSize.corner)
          ),
          child: Center(child: Icon(
            lyra ? CI.message_ai : CI.help,
            size: AppSize.text * 1.2,
            color: entry.isPending
              ? scheme.accent
              : entry.state == KnowledgeState.active ? scheme.icon : scheme.text.secondary
          ))
        ),
        SizedBox(width: AppSize.spaceS),
        Expanded(child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Flexible(child: TextMedium(entry.question, ellipsis: true, bold: true)),
              SizedBox(width: AppSize.spaceS),
              KnowledgeStateTag(entry: entry)
            ]),
            SizedBox(height: AppSize.gap),
            if (entry.isPending)
              TextSmall(s.knowledge_row_no_answer, ellipsis: true, color: scheme.accent)
            else
              TextSmall(entry.answer, lines: 2, color: scheme.text.secondary),
            if (scope.isNotEmpty) ...[
              SizedBox(height: AppSize.gap),
              TextSmall(scope, ellipsis: true, color: scheme.text.secondary)
            ]
          ]
        )),
        SizedBox(width: AppSize.spaceS),
        KnowledgeOptionsButton(entry: entry)
      ])
    );
  }

  /// Who asked it, and where and when it holds, in one line. The whole
  /// company and no dates are the default and say nothing.
  String _scope(BuildContext context) {
    final s = S.of(context);
    final products = entry.products;

    return [
      if (entry.source == KnowledgeSource.assistant) s.knowledge_row_from_lyra,
      if (entry.asks > 0) s.knowledge_row_asks(entry.asks),
      ?entry.branch?.name,
      if (products.isNotEmpty)
        products.length <= 2
          ? products.map((product) => product.name).where((name) => name.isNotEmpty).join(", ")
          : s.knowledge_row_products(products.length),
      if (entry.from != null) s.knowledge_row_from(knowledgeDay(context, entry.from!)),
      if (entry.until != null) s.knowledge_row_until(knowledgeDay(context, entry.until!))
    ].where((part) => part.isNotEmpty).join(" · ");
  }
}
