import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// A labelled bar: the assistant catalog's `Progress` and the summary's usage
/// and stock rows draw the same one.
class UsageBar extends StatelessWidget {
  const UsageBar({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.caption
  });

  final String label;
  final String? caption;

  /// From 0 to 1.
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final height = AppSize.gap * 1.2;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSize.gap * 0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(child: TextMedium(label, ellipsis: true)),
            if (caption != null) TextSmall(caption!, color: scheme.text.secondary)
          ]),
          SizedBox(height: AppSize.gap),
          ClipRRect(
            borderRadius: BorderRadius.circular(height),
            child: Container(
              height: height,
              color: scheme.chart.grid,
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: value.clamp(0.0, 1.0),
                heightFactor: 1,
                child: Container(color: color)
              )
            )
          )
        ]
      )
    );
  }
}
