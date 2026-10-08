import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/home/sections/employees/own_settings/own_section.dart';

import './own_soon_tag.dart';

/// A subsection of the account on its own page: what it is for in one line, then its rows over one
/// surface.
class OwnSectionPage extends StatelessWidget {
  const OwnSectionPage({super.key, required this.section});

  final OwnSection section;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return ScrollableWidget(
      padding: EdgeInsets.only(bottom: AppSize.padding),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Expanded(child: TextSmall(section.subtitle(s), lines: 3, color: ThemeColor.of(context).text.secondary)),
          if (section.soon) ...[
            SizedBox(width: AppSize.spaceXS),
            const OwnSoonTag()
          ]
        ]),
        SizedBox(height: AppSize.spaceS),
        Surface.over(
          padding: EdgeInsets.all(AppSize.spaceS),
          child: section.body
        )
      ]
    );
  }
}
