import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// A card of the home's summary: an icon and title, an optional note or link
/// on the right ([trailing], [onMore]) and its content.
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
    this.onMore
  });

  final IconData icon;
  final String title;
  final Widget child;

  /// A note beside the title (when it renews, how many).
  final String? trailing;

  /// "View all": opens the section the card summarises.
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Surface(
      padding: EdgeInsets.all(AppSize.spaceS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            SummaryIcon(icon: icon),
            SizedBox(width: AppSize.spaceXS),
            Expanded(child: TextMedium(title, bold: true, ellipsis: true)),
            if (trailing != null) TextSmall(trailing!, color: scheme.text.secondary),
            if (onMore != null) FeedbackButton(
              action: onMore,
              radius: AppSize.cornerInset(AppSize.gap),
              padding: EdgeInsets.symmetric(horizontal: AppSize.gap * 1.4, vertical: AppSize.gap),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                TextSmall(S.of(context).dashboard_view_all, color: scheme.primary, bold: true),
                Icon(CI.arrow_right, size: AppSize.text, color: scheme.primary)
              ])
            )
          ]),
          SizedBox(height: AppSize.spaceXS),
          child
        ]
      )
    );
  }
}

/// A card's icon in its tinted square.
class SummaryIcon extends StatelessWidget {
  const SummaryIcon({super.key, required this.icon, this.color});

  final IconData icon;

  /// The tint; the theme's primary when null.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? ThemeColor.of(context).primary;

    return Container(
      width: AppSize.button,
      height: AppSize.button,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSize.cornerInset(AppSize.gap, AppSize.gap * 2))
      ),
      child: Icon(icon, size: AppSize.text * 1.3, color: tint)
    );
  }
}

/// One count of the summary's grid: how many, of what, and where to see them.
class SummaryTile extends StatelessWidget {
  const SummaryTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.caption,
    this.color,
    this.live = false,
    this.onTap
  });

  final IconData icon;
  final String value;
  final String label;
  final String? caption;
  final Color? color;

  /// Something is happening now (people online): a dot beside the figure.
  final bool live;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return FeedbackButton(
      action: onTap,
      color: scheme.surface,
      radius: AppSize.corner,
      padding: EdgeInsets.all(AppSize.spaceS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SummaryIcon(icon: icon, color: color),
          SizedBox(height: AppSize.spaceXS),
          Row(children: [
            TextMedium(value, multiplier: 2, bold: true),
            if (live) ...[
              SizedBox(width: AppSize.gap),
              Container(
                width: AppSize.gap * 1.4,
                height: AppSize.gap * 1.4,
                decoration: BoxDecoration(color: scheme.chart.good, shape: BoxShape.circle)
              )
            ]
          ]),
          TextMedium(label, color: scheme.text.secondary, ellipsis: true),
          // Kept when empty: tiles side by side stay the same height.
          TextSmall(caption ?? "", color: scheme.text.secondary, ellipsis: true)
        ]
      )
    );
  }
}
