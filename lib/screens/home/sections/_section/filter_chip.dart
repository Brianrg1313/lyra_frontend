import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES

// SERVICES

// WIDGETS


/// One control of a filter bar (sales, payments). The active ones are filled
/// with the line colour: the table below is where the colour that means
/// something lives.
class SectionFilterChip extends StatelessWidget {
  const SectionFilterChip({
    super.key,
    required this.title,
    required this.isActive,
    required this.action,
    this.icon,
    this.leading,
    this.trailing
  });

  final IconData? icon;

  /// A mark of the value's own, in place of [icon]. It is drawn as it arrives:
  /// what identifies a value is not the chip's business.
  final Widget? leading;

  final String title;
  final bool isActive;
  final void Function() action;
  final IconData? trailing;

  /// Longest a control's label gets before it is cut.
  ///
  /// A chip is sized by its text, and the labels here are the backend's —a
  /// state's name, a channel's— so one long one would push the whole bar off
  /// the right edge of a narrow window. Cut at a width that still holds the
  /// longest state anybody wrote, with the full wording in the tooltip.
  static double get _maxTitle => AppSize.action * 4;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final color = isActive ? scheme.text.primary : scheme.text.secondary;

    return FeedbackButton(
      action: action,
      height: AppSize.button,
      message: title,
      padding: EdgeInsets.symmetric(horizontal: AppSize.spaceXS),
      radius: AppSize.cornerInset(AppSize.gap),
      color: isActive ? scheme.line : scheme.surfaceOver,
      feedbackColor: scheme.lineOver,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading!,
            SizedBox(width: AppSize.gap)
          ] else if (icon != null) ...[
            Icon(icon, size: AppSize.text, color: color),
            SizedBox(width: AppSize.gap)
          ],
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: _maxTitle),
            child: TextMedium(
              title,
              bold: isActive,
              multiplier: 0.9,
              ellipsis: true,
              color: color
            )
          ),
          if (trailing != null) ...[
            SizedBox(width: AppSize.gap),
            Icon(trailing, size: AppSize.text * 0.8, color: color)
          ]
        ]
      )
    );
  }
}
