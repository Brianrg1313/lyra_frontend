import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// Free text over a tile: notes, the "about", a reason a block is empty.
class EmployeeNote extends StatelessWidget {
  const EmployeeNote({super.key, required this.text, this.title, this.lines = 12});

  final String? title;
  final String text;
  final int lines;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Surface(
      color: scheme.surface,
      radius: AppSize.cornerInset(AppSize.gap),
      padding: EdgeInsets.all(AppSize.spaceXS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            TextMedium(title!, bold: true, ellipsis: true),
            SizedBox(height: AppSize.gap * 0.5)
          ],
          TextSmall(text, lines: lines, ellipsis: true, selectable: true, color: scheme.text.secondary)
        ]
      )
    );
  }
}
