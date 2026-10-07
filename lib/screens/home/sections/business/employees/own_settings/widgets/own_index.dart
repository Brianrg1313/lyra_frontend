import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/home/sections/business/employees/own_settings/own_section.dart';

import './own_group.dart';
import './own_section_row.dart';

/// Every subsection: what works first, the ones with nothing working yet apart and last.
class OwnIndex extends StatelessWidget {
  const OwnIndex({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      OwnGroup(rows: [
        for (final section in OwnSection.values.where((section) => !section.soon)) OwnSectionRow(section: section)
      ]),
      SizedBox(height: AppSize.spaceS),
      OwnGroup(rows: [
        for (final section in OwnSection.values.where((section) => section.soon)) OwnSectionRow(section: section)
      ])
    ]
  );
}
