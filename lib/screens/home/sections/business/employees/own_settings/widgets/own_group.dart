import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES

// SERVICES

// WIDGETS


/// Rows over one surface, a line between each.
class OwnGroup extends StatelessWidget {
  const OwnGroup({super.key, required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => Surface.over(
    padding: EdgeInsets.all(AppSize.gap),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < rows.length; i++) ...[
          if (i > 0) Separator.horizontal(margin: EdgeInsets.symmetric(horizontal: AppSize.spaceXS)),
          rows[i]
        ]
      ]
    )
  );
}
