import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES

// SERVICES

class InboxFilterChip extends StatelessWidget {
  const InboxFilterChip({
    super.key,
    required this.label,
    required this.count,
    required this.active,
    required this.alert,
    required this.action
  });

  final String label;
  final int? count;
  final bool active;

  /// The counter is drawn as a warning while above zero.
  final bool alert;
  final void Function() action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final shown = count != null && count! > 0;
    final badge = alert ? scheme.chart.serious : scheme.primary;

    return FeedbackButton(
      action: action,
      message: label,
      height: AppSize.button * 0.9,
      padding: EdgeInsets.symmetric(horizontal: AppSize.spaceXS),
      radius: AppSize.corner,
      color: active ? scheme.primary.withValues(alpha: 0.14) : scheme.surfaceOver,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextMedium(
            label,
            multiplier: 0.9,
            bold: active,
            color: active ? scheme.primary : scheme.text.secondary
          ),
          if (shown) ...[
            SizedBox(width: AppSize.gap),
            Container(
              padding: EdgeInsets.symmetric(horizontal: AppSize.gap, vertical: 1),
              decoration: BoxDecoration(
                color: badge,
                borderRadius: BorderRadius.circular(AppSize.corner)
              ),
              child: TextSmall("$count", multiplier: 0.85, color: scheme.surface)
            )
          ]
        ]
      )
    );
  }
}
