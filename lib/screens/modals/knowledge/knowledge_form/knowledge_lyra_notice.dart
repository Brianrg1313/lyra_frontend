import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/knowledge/knowledge_entry_model.dart';

/// The head of a question Lyra left: a customer asked it, she could not answer
/// it, and how many have asked it since. It replaces the form's explanation —
/// what the company is being asked for is the same, said about this question.
class KnowledgeLyraNotice extends StatelessWidget {
  const KnowledgeLyraNotice({super.key, required this.entry});

  final KnowledgeEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.spaceS),
      child: Surface.over(
        padding: EdgeInsets.all(AppSize.spaceS),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(CI.message_ai, size: AppSize.text * 1.2, color: scheme.accent),
          SizedBox(width: AppSize.spaceS),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextMedium(
                [
                  s.knowledge_row_from_lyra,
                  if (entry.asks > 0) s.knowledge_row_asks(entry.asks)
                ].join(" · "),
                multiplier: 0.9,
                bold: true
              ),
              SizedBox(height: AppSize.gap / 2),
              TextSmall(
                entry.isPending ? s.knowledge_form_from_lyra : s.knowledge_form_subtitle,
                lines: 4,
                color: scheme.text.secondary
              )
            ]
          ))
        ])
      )
    );
  }
}
