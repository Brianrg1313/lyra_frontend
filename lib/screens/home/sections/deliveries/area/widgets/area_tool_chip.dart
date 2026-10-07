import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES

// SERVICES

// WIDGETS


/// A small action of the tools, faded while there is nothing for it to do.
class AreaToolChip extends StatelessWidget {
  const AreaToolChip({
    super.key,
    required this.label,
    required this.action,
    this.icon,
    this.chosen = false
  });

  final String label;
  final void Function()? action;
  final IconData? icon;
  final bool chosen;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final color = action == null
      ? scheme.text.secondary.withValues(alpha: 0.5)
      : chosen ? scheme.primary : scheme.text.primary;

    return FeedbackButton(
      action: action ?? () {},
      height: AppSize.button * 0.8,
      padding: EdgeInsets.symmetric(horizontal: AppSize.gap),
      radius: AppSize.cornerInset(AppSize.spaceXS),
      color: chosen ? scheme.primary.withValues(alpha: 0.12) : scheme.surfaceOver,
      feedbackColor: scheme.line,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSize.text * 0.9, color: color),
            SizedBox(width: AppSize.gap * 0.5)
          ],
          TextSmall(label, color: color)
        ]
      )
    );
  }
}
