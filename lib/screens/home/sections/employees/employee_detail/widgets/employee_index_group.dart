import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// Rows of the detail page over one surface, a line between each, under an
/// optional [title].
class EmployeeIndexGroup extends StatelessWidget {
  const EmployeeIndexGroup({super.key, required this.rows, this.title});

  final List<Widget> rows;
  final String? title;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (title != null) Padding(
        padding: EdgeInsets.only(left: AppSize.spaceXS, bottom: AppSize.gap),
        child: TextSmall(title!, ellipsis: true, color: ThemeColor.of(context).text.secondary)
      ),
      Surface.over(
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
      )
    ]
  );
}
