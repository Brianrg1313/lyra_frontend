import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES


/// A block over the body's sheet: a title and its rows.
class MoneyBreakdownBlock extends StatelessWidget {
  const MoneyBreakdownBlock({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Surface.over(
      padding: EdgeInsets.all(AppSize.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextMedium(
            title,
            bold: true,
            multiplier: 0.9,
            color: scheme.text.secondary
          ),
          SizedBox(height: AppSize.spaceXS),
          if (children.isEmpty)
            TextSmall(
              S.of(context).finance_breakdown_empty,
              color: scheme.text.secondary
            )
          else
            ...children
        ]
      )
    );
  }
}
