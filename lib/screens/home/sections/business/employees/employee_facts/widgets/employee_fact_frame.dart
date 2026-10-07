import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/home/sections/business/employees/employee_facts/_employee_facts.dart';

/// The inside of every tile: the datum's icon, what the datum is called, its
/// [child] (the value, or the field that edits it) and an optional [trailing]
/// hint of what a tap does.
class EmployeeFactFrame extends StatelessWidget {
  const EmployeeFactFrame({
    super.key,
    required this.icon,
    required this.label,
    required this.child,
    this.trailing,
    this.accent
  });

  final IconData icon;
  final String label;
  final Widget child;
  final Widget? trailing;

  /// Tints the icon and the label: the tile being edited.
  final Color? accent;

  /// Box every tile is padded with.
  static EdgeInsets get padding => EdgeInsets.all(AppSize.spaceXS);

  /// Corner of a group's sheet ([EmployeeFacts]).
  static double get sheetRadius => AppSize.cornerInset(AppSize.gap);

  /// Corner of a cell, nested in its sheet.
  static double get radius => AppSize.cornerInset(AppSize.gap * 0.5, sheetRadius);

  /// The datum's icon. The text size itself read lost in its box.
  static double get iconSize => AppSize.text * 1.35;

  /// The small hints at a tile's end (edit, copy, unfold).
  static double get hintSize => AppSize.text * 1.15;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Row(children: [
      // No box behind it: the cell is already one, and a box per datum is
      // what made the panel a grid of cards. The slot keeps labels aligned.
      SizedBox(
        width: AppSize.text * 2.5,
        child: Icon(icon, size: iconSize, color: accent ?? scheme.text.secondary)
      ),
      SizedBox(width: AppSize.gap * 0.5),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextSmall(label, ellipsis: true, color: accent ?? scheme.text.secondary),
          SizedBox(height: AppSize.gap * 0.25),
          child
        ]
      )),
      if (trailing != null) ...[
        SizedBox(width: AppSize.gap),
        trailing!
      ]
    ]);
  }
}
