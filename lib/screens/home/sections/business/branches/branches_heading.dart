import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// What the tab is and one line that says what it is for. [count], once the
/// list is read, sits by the title: how many places the company has is the
/// first thing the map is asked.
class BranchesHeading extends StatelessWidget {
  const BranchesHeading({super.key, this.count});

  final int? count;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(child: TextLarge(S.of(context).business_branches_title, ellipsis: true)),
            if (count != null) ...[
              SizedBox(width: AppSize.spaceXS),
              TextLarge("$count", color: scheme.text.secondary)
            ]
          ]
        ),
        SizedBox(height: AppSize.gap * 0.5),
        TextSmall(
          S.of(context).business_branches_subtitle,
          lines: 2,
          ellipsis: true,
          color: scheme.text.secondary
        )
      ]
    );
  }
}
