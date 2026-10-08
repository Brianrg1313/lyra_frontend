import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

import './own_soon_list.dart';

/// A setting that is part of the account but has no backend yet: named and explained, never
/// drawn as a switch that would do nothing. Quieter than a working row (one muted line, no
/// separator, no tag of its own) so what can be used today is what the panel is read for;
/// [OwnSoonList] says "coming soon" once for the group.
class OwnSoon extends StatelessWidget {
  const OwnSoon({super.key, required this.icon, required this.label, this.hint, this.marks = const []});

  final IconData icon;
  final String label;
  final String? hint;

  /// Icons drawn after the label: the brands one row stands for.
  final List<IconData> marks;

  @override
  Widget build(BuildContext context) {
    final muted = ThemeColor.of(context).text.secondary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: AppSize.gap * 0.3),
          child: Icon(icon, size: AppSize.text * 0.9, color: muted.withValues(alpha: 0.7))
        ),
        SizedBox(width: AppSize.spaceXS),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Flexible(child: TextSmall(label, ellipsis: true, color: muted)),
              for (final mark in marks) ...[
                SizedBox(width: AppSize.gap * 0.75),
                Icon(mark, size: AppSize.text * 0.85, color: muted.withValues(alpha: 0.7))
              ]
            ]),
            if (hint != null)
              TextSmall(hint!, lines: 2, ellipsis: true, color: muted.withValues(alpha: 0.7))
          ]
        ))
      ]
    );
  }
}
