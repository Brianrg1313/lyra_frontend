import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/home/sections/business/employees/own_settings/own_section.dart';
import 'package:app/screens/home/sections/business/employees/own_settings/own_setting.dart';

import './own_group.dart';
import './own_section_row.dart';
import './own_setting_row.dart';

/// What the search found: the subsections it names, then the rows inside them, each with the
/// subsection it opens.
class OwnResults extends StatelessWidget {
  const OwnResults({super.key, required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final words = OwnSetting.fold(query).split(" ").where((word) => word.isNotEmpty).toList();

    final sections = [
      for (final section in OwnSection.values)
        if (words.every(OwnSetting.fold("${section.title(s)} ${section.subtitle(s)}").contains)) section
    ];
    final settings = [
      for (final section in OwnSection.values)
        for (final setting in section.settings(s))
          if (setting.matches(words, section.title(s))) setting
    ];

    if (sections.isEmpty && settings.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: AppSize.spaceM),
        child: TextSmall(
          s.account_search_empty(query),
          lines: 3,
          textAlign: TextAlign.center,
          color: ThemeColor.of(context).text.secondary
        )
      );
    }

    return OwnGroup(rows: [
      for (final section in sections) OwnSectionRow(section: section),
      for (final setting in settings) OwnSettingRow(setting: setting)
    ]);
  }
}
