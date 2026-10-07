import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// Lines that start the conditions a context usually needs —hours, a
/// deadline, spots, an agent's confirmation— added at the end of it with a
/// click, with brackets where the company's figure goes.
///
/// They are text and not fields on purpose: Lyra reads the context as the
/// company wrote it, so a deadline or a number of spots is said exactly as it
/// stands there, and a field of its own would be one more thing to keep in
/// step with the sentence around it. What is structured is when the answer
/// holds at all (the dates below), because past it Lyra must not give it.
class KnowledgeSnippets extends StatelessWidget {
  const KnowledgeSnippets({super.key, required this.onAdd});

  final void Function(String line) onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);

    final snippets = [
      (CI.calendar, s.knowledge_snippet_hours, s.knowledge_snippet_hours_text),
      (CI.task_list, s.knowledge_snippet_deadline, s.knowledge_snippet_deadline_text),
      (CI.user_basket, s.knowledge_snippet_spots, s.knowledge_snippet_spots_text),
      (CI.support, s.knowledge_snippet_agent, s.knowledge_snippet_agent_text)
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.spaceS),
      child: Wrap(
        spacing: AppSize.gap,
        runSpacing: AppSize.gap,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          TextSmall(s.knowledge_form_snippets, color: scheme.text.secondary),
          for (final (icon, label, line) in snippets) FeedbackButton(
            action: () => onAdd(line),
            color: scheme.surfaceOver,
            padding: EdgeInsets.symmetric(
              horizontal: AppSize.spaceS,
              vertical: AppSize.gap
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: AppSize.text * 0.9, color: scheme.icon),
              SizedBox(width: AppSize.gap),
              TextSmall(label)
            ])
          )
        ]
      )
    );
  }
}
