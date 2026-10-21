import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import './assistant_orb.dart';

/// Above the composer while the chat is empty: the mark, a greeting for the
/// hour and the question. It sits right on top of the field, the way the big
/// chat apps open: what to do is to write.
class AssistantGreeting extends StatelessWidget {
  const AssistantGreeting({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final hour = DateTime.now().hour;

    final greeting = hour < 12
      ? s.assistant_greeting_morning
      : hour < 19 ? s.assistant_greeting_afternoon : s.assistant_greeting_evening;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.spaceM),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AssistantOrb(size: AppSize.picture),
          SizedBox(height: AppSize.spaceM),
          TextInter(greeting, multiplier: 2.4, bold: true, textAlign: TextAlign.center, lines: 2),
          SizedBox(height: AppSize.gap),
          TextMedium(s.assistant_welcome_title, multiplier: 1.2, color: scheme.text.secondary, textAlign: TextAlign.center, lines: 2)
        ]
      )
    );
  }
}

/// Under the composer while the chat is empty: a few things to ask, each sent
/// as if typed ([onAsk]). Chips, not cards: they are shortcuts to a sentence,
/// and the whole prompt shows on hover.
class AssistantSuggestions extends StatelessWidget {
  const AssistantSuggestions({super.key, required this.onAsk});

  final void Function(String prompt) onAsk;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);

    final suggestions = [
      (CI.sale, s.assistant_suggestion_sales_title, s.assistant_suggestion_sales_prompt),
      (CI.inventory, s.assistant_suggestion_stock_title, s.assistant_suggestion_stock_prompt),
      (CI.employee, s.assistant_suggestion_team_title, s.assistant_suggestion_team_prompt),
      (CI.ia, s.assistant_suggestion_help_title, s.assistant_suggestion_help_prompt)
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSize.gap * 1.6,
      runSpacing: AppSize.gap * 1.6,
      children: [
        for (final (icon, title, prompt) in suggestions) DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: scheme.line),
            borderRadius: BorderRadius.circular(AppSize.action)
          ),
          child: FeedbackButton(
            action: () => onAsk(prompt),
            message: prompt,
            radius: AppSize.action,
            padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS, vertical: AppSize.gap * 1.8),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: AppSize.text * 1.2, color: scheme.text.secondary),
              SizedBox(width: AppSize.gap * 1.6),
              TextMedium(title)
            ])
          )
        )
      ]
    );
  }
}
