import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import './assistant_orb.dart';

/// The empty chat: the mark, the question and a few things to ask, each one
/// sent as if typed ([onAsk]).
class AssistantWelcome extends StatelessWidget {
  const AssistantWelcome({super.key, required this.onAsk});

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

    return Center(child: SingleChildScrollView(
      padding: EdgeInsets.all(AppSize.spaceM),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AssistantOrb(size: AppSize.picture * 1.3),
          SizedBox(height: AppSize.spaceL),
          TextMedium(s.assistant_welcome_title, multiplier: 2.2, bold: true, textAlign: TextAlign.center, lines: 2),
          SizedBox(height: AppSize.spaceXS),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: AppSize.picture * 9),
            child: TextMedium(
              s.assistant_welcome_subtitle,
              color: scheme.text.secondary,
              textAlign: TextAlign.center,
              lines: 3
            )
          ),
          SizedBox(height: AppSize.spaceL),
          LayoutBuilder(builder: (context, constraints) {
            // Two columns while each card keeps room for its prompt.
            final columns = constraints.maxWidth > AppSize.picture * 8 ? 2 : 1;
            final width = (constraints.maxWidth - AppSize.spaceXS * (columns - 1)) / columns;

            return Wrap(
              spacing: AppSize.spaceXS,
              runSpacing: AppSize.spaceXS,
              children: [
                for (final (icon, title, prompt) in suggestions) SizedBox(
                  width: width,
                  child: _Suggestion(icon: icon, title: title, prompt: prompt, onTap: () => onAsk(prompt))
                )
              ]
            );
          })
        ]
      )
    ));
  }
}

class _Suggestion extends StatelessWidget {
  const _Suggestion({
    required this.icon,
    required this.title,
    required this.prompt,
    required this.onTap
  });

  final IconData icon;
  final String title;
  final String prompt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final radius = AppSize.cornerInset(AppSize.gap);

    return FeedbackButton(
      action: onTap,
      radius: radius,
      color: scheme.surfaceOver,
      padding: EdgeInsets.all(AppSize.spaceS),
      child: Row(children: [
        Container(
          width: AppSize.button,
          height: AppSize.button,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSize.cornerInset(AppSize.gap, radius))
          ),
          child: Icon(icon, size: AppSize.text * 1.3, color: scheme.primary)
        ),
        SizedBox(width: AppSize.spaceXS),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextMedium(title, bold: true, ellipsis: true),
            TextSmall(prompt, color: scheme.text.secondary, ellipsis: true)
          ]
        ))
      ])
    );
  }
}
