import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

import './own_soon.dart';
import './own_soon_tag.dart';

/// The [OwnSoon] rows of a block, close together under one "coming soon". [caption] is false
/// where the panel's lead line already carries the tag (a subsection with nothing working yet).
class OwnSoonList extends StatelessWidget {
  const OwnSoonList({super.key, required this.rows, this.caption = true});

  final List<OwnSoon> rows;
  final bool caption;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (caption) ...[
        const OwnSoonTag(),
        SizedBox(height: AppSize.spaceXS)
      ],
      for (int i = 0; i < rows.length; i++) ...[
        if (i > 0) SizedBox(height: AppSize.spaceXS),
        rows[i]
      ]
    ]
  );
}
