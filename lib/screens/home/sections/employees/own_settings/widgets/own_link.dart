import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS

/// A text action under a row's value: the panel reads, and its few actions are words, not a
/// column of buttons.
class OwnLink extends StatelessWidget {
  const OwnLink({super.key, required this.label, required this.action, this.danger = false});

  final String label;
  final void Function() action;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final color = danger ? scheme.chart.critical : scheme.primary;

    return FeedbackButton(
      action: action,
      message: label,
      radius: AppSize.cornerInset(AppSize.gap),
      color: color.withValues(alpha: 0.08),
      feedbackColor: color.withValues(alpha: 0.18),
      padding: EdgeInsets.symmetric(horizontal: AppSize.spaceXS, vertical: AppSize.gap * 0.8),
      child: TextMedium(label, multiplier: 0.9, bold: true, color: color)
    );
  }
}
