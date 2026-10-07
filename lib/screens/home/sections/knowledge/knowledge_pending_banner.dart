import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// How many questions wait for their context, on top of the list, with the way
/// to see only them. A question without one is a customer that will get a
/// person's "we'll confirm it" again, so it is said and not left to a filter.
class KnowledgePendingBanner extends StatelessWidget {
  const KnowledgePendingBanner({super.key, required this.count, required this.onShow});

  final int count;
  final void Function() onShow;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.spaceXS),
      child: Surface.over(
        padding: EdgeInsets.symmetric(
          horizontal: AppSize.spaceS,
          vertical: AppSize.spaceXS
        ),
        child: Row(children: [
          Icon(CI.message_ai, size: AppSize.text * 1.2, color: scheme.accent),
          SizedBox(width: AppSize.spaceS),
          Expanded(child: TextSmall(
            S.of(context).knowledge_pending_banner(count),
            lines: 2
          )),
          SizedBox(width: AppSize.spaceS),
          FeedbackButton(
            action: onShow,
            color: scheme.accent.withValues(alpha: 0.12),
            padding: EdgeInsets.symmetric(
              horizontal: AppSize.spaceS,
              vertical: AppSize.gap
            ),
            child: TextMedium(
              S.of(context).knowledge_pending_show,
              multiplier: 0.9,
              color: scheme.accent,
              bold: true
            )
          )
        ])
      )
    );
  }
}
