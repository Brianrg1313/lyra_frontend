import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

import './permission_grid.dart';

/// The line down from the section's icon to each action, lit at the branch while the action
/// holds.
class PermissionThread extends StatelessWidget {
  const PermissionThread({super.key, required this.last, required this.open});

  final bool last;
  final bool open;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final stroke = AppSize.text * 0.12;
    final left = PermissionGrid.inset + PermissionGrid.cell / 2 - stroke / 2;

    return Stack(children: [
      Positioned(
        left: left,
        top: 0,
        bottom: 0,
        child: FractionallySizedBox(
          heightFactor: last ? 0.5 : 1,
          alignment: Alignment.topCenter,
          child: Container(width: stroke, color: scheme.line)
        )
      ),
      Positioned(
        left: left,
        right: AppSize.spaceXS,
        top: 0,
        bottom: 0,
        child: Center(child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: stroke,
          color: open ? scheme.primary : scheme.line
        ))
      )
    ]);
  }
}
