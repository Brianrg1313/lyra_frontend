import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/home/sections/business/employees/own_settings/own_setting.dart';

import './own_arrow.dart';
import './own_row_tap.dart';
import './own_soon_tag.dart';

/// A row inside a subsection, as a search result: its name and the subsection that holds it.
class OwnSettingRow extends StatelessWidget {
  const OwnSettingRow({super.key, required this.setting});

  final OwnSetting setting;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final section = setting.section;

    return OwnRowTap(
      label: setting.label,
      action: () => section.open(context),
      child: Row(children: [
        SizedBox(
          width: AppSize.action * 0.85,
          child: Icon(setting.icon, size: AppSize.text * 1.1, color: scheme.text.secondary)
        ),
        SizedBox(width: AppSize.spaceS),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextMedium(setting.label, ellipsis: true),
            TextSmall(section.title(s), ellipsis: true, color: scheme.text.secondary)
          ]
        )),
        SizedBox(width: AppSize.spaceXS),
        section.soon ? const OwnSoonTag() : const OwnArrow()
      ])
    );
  }
}
