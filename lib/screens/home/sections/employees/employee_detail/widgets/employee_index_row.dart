import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/home/sections/employees/own_settings/widgets/own_soon_tag.dart';

/// One row of the detail page: its icon, its name and what it holds, and the
/// arrow to its page. A [soon] one (nothing in it works yet) is muted and
/// tagged instead.
class EmployeeIndexRow extends StatelessWidget {
  const EmployeeIndexRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
    this.soon = false
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final void Function() action;
  final bool soon;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final tint = soon ? scheme.text.secondary : scheme.primary;
    final box = AppSize.action * 0.85;
    final radius = AppSize.cornerInset(AppSize.gap);

    return FeedbackButton(
      action: action,
      message: title,
      radius: radius,
      color: Colors.transparent,
      feedbackColor: scheme.surfaceFeedback,
      padding: EdgeInsets.all(AppSize.spaceXS),
      child: Row(children: [
        Container(
          width: box,
          height: box,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(radius)
          ),
          child: Icon(icon, size: AppSize.text * 1.15, color: tint)
        ),
        SizedBox(width: AppSize.spaceS),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextMedium(title, bold: true, ellipsis: true, color: soon ? scheme.text.secondary : null),
            TextSmall(subtitle, lines: 2, ellipsis: true, color: scheme.text.secondary)
          ]
        )),
        SizedBox(width: AppSize.spaceXS),
        soon
          ? const OwnSoonTag()
          : Icon(CI.arrow_right, size: AppSize.text, color: scheme.text.secondary)
      ])
    );
  }
}
