import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// The top of both panels: one height and a line across, so the list's
/// heading and the person on the right sit on one row and their lines meet,
/// as the inbox's and the open chat's do.
class EmployeePanelBar extends StatelessWidget {
  const EmployeePanelBar({super.key, required this.child});

  final Widget child;

  /// Fits a picture beside two lines, and the invite button.
  static double get height => AppSize.action + AppSize.spaceS * 2;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(
        height: height,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSize.spaceM),
          child: Align(alignment: Alignment.centerLeft, child: child)
        )
      ),
      Separator.horizontal()
    ]
  );
}
