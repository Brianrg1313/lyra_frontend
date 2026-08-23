import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

import 'package:app/screens/home/sections/_sections.dart';

import './side_bar/side_bar.dart';

class DesktopBody extends StatelessWidget {
  const DesktopBody({
    super.key,
    required this.section,
    required this.header,
    required this.content
  });

  /// Open section, used to mark its option in the side bar. A sub-page
  /// is reflected in the section that contains it.
  final HomeSection section;

  /// Top bar, the same for all sections.
  ///
  /// It goes above the content and not above the whole window: next to the
  /// side bar the two fixed parts would sit in the same corner and the center
  /// panel would lose height for nothing. This way the bar spans the width of
  /// the panel it belongs to, which is also what you search on.
  final Widget header;

  /// Content of the center panel: the section's or its sub-page's.
  final Widget content;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(AppSize.gap),
    child: Row(children: [
      SideBar(section: section),
      SizedBox(width: AppSize.gap),
      Expanded(child: Column(children: [
        header,
        SizedBox(height: AppSize.gap),
        Expanded(child: content)
      ]))
    ])
  );
}
