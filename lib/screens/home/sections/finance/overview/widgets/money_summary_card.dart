import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES


/// One figure, on its own block over the body's sheet.
class MoneySummaryCard extends StatelessWidget {
  const MoneySummaryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.amount,
    required this.accent,
    required this.detail
  });

  final IconData icon;
  final String title;
  final String amount;

  /// The colour of the icon and of the amount. It is what tells the four apart
  /// at a glance, which is how this row is read.
  final Color accent;

  /// The line under the amount: what it is made of, or what it means.
  final String detail;

  /// A fixed width and not a `Flexible`: the four are laid out in a [Wrap], so
  /// they need a measure of their own to decide when to break the line.
  static const double _width = 230;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return SizedBox(
      width: _width,
      child: Surface.over(
        padding: EdgeInsets.all(AppSize.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Icon(icon, size: AppSize.text, color: accent),
              SizedBox(width: AppSize.gap),
              Expanded(child: TextSmall(
                title,
                color: scheme.text.secondary,
                ellipsis: true
              ))
            ]),
            SizedBox(height: AppSize.spaceXS),
            TextLarge(amount, color: accent, ellipsis: true),
            SizedBox(height: AppSize.gap),
            TextSmall(
              detail,
              color: scheme.text.secondary,
              multiplier: 0.9,
              ellipsis: true
            )
          ]
        )
      )
    );
  }
}
