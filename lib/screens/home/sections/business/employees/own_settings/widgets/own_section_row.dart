import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/home/sections/business/employees/own_settings/own_section.dart';

import './own_arrow.dart';
import './own_row_tap.dart';
import './own_soon_tag.dart';

/// A subsection of the index: its icon, its name and what it is for, and where it leads.
class OwnSectionRow extends StatelessWidget {
  const OwnSectionRow({super.key, required this.section});

  final OwnSection section;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final tint = section.soon ? scheme.text.secondary : scheme.primary;
    final box = AppSize.action * 0.85;

    return OwnRowTap(
      label: section.title(s),
      action: () => section.open(context),
      child: Row(children: [
        Container(
          width: box,
          height: box,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSize.cornerInset(AppSize.gap))
          ),
          child: Icon(section.icon, size: AppSize.text * 1.15, color: tint)
        ),
        SizedBox(width: AppSize.spaceS),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextMedium(section.title(s), bold: true, ellipsis: true, color: section.soon ? scheme.text.secondary : null),
            TextSmall(section.subtitle(s), lines: 2, ellipsis: true, color: scheme.text.secondary)
          ]
        )),
        SizedBox(width: AppSize.spaceXS),
        section.soon ? const OwnSoonTag() : const OwnArrow()
      ])
    );
  }
}
