import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// A secondary way to start, compact and without an image, laid under the
/// [WelcomeOption]. Ends in an arrow, or in [tag] when the path is not
/// really open yet, so the card does not promise more than it opens.
class WelcomeChoice extends StatelessWidget {
  const WelcomeChoice({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
    this.tag
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback action;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final label = tag;

    return FeedbackButton(
      width: double.infinity,
      color: scheme.surface,
      feedbackColor: scheme.surfaceOver,
      action: action,
      padding: EdgeInsets.all(AppSize.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: scheme.text.primary),
            SizedBox(width: AppSize.gap),
            Expanded(child: TextMedium(title, bold: true, ellipsis: true)),
            SizedBox(width: AppSize.gap),
            if (label == null)
              Icon(CI.arrow_right, size: 18, color: scheme.icon)
            else
              Container(
                padding: EdgeInsets.symmetric(
                  vertical: AppSize.gap * 0.5,
                  horizontal: AppSize.gap
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceOver,
                  borderRadius: BorderRadius.circular(AppSize.corner)
                ),
                child: TextSmall(label, color: scheme.subtitle)
              )
          ]),
          SizedBox(height: AppSize.spaceXS),
          TextSmall(subtitle, lines: 2, ellipsis: true, color: scheme.subtitle)
        ]
      )
    );
  }
}
