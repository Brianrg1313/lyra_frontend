import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/home/sections/employees/employee_facts/widgets/employee_fact_frame.dart';

import './permission_grid.dart';

/// One switch. On is a solid mark in the button colors, the strongest thing in the list; off is
/// an outline. Without [toggle] it is only drawn.
class PermissionCell extends StatelessWidget {
  const PermissionCell({
    super.key,
    required this.on,
    required this.icon,
    required this.message,
    required this.toggle,
    this.locked = false,
    this.dim = false
  });

  final bool on;
  final IconData icon;
  final String message;
  final VoidCallback? toggle;

  /// The viewer may not give or take it: a key instead of the icon while off, and says why.
  final bool locked;

  /// Under a closed section: stored, granting nothing.
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final size = PermissionGrid.cell;
    final fill = dim ? scheme.button.fill.withValues(alpha: 0.4) : scheme.button.fill;

    final mark = SizedBox(
      width: size,
      height: size,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: on ? fill : Colors.transparent,
          border: Border.all(color: on ? fill : scheme.line, width: AppSize.text * 0.1),
          borderRadius: BorderRadius.circular(EmployeeFactFrame.radius)
        ),
        child: Center(child: Icon(
          on ? CI.check : locked ? CI.key : icon,
          size: EmployeeFactFrame.hintSize,
          color: on ? scheme.button.text : scheme.text.secondary.withValues(alpha: 0.6)
        ))
      )
    );

    if (locked) return Tooltip(message: S.of(context).permission_locked, child: mark);
    if (toggle == null) return mark;

    return FeedbackButton(
      action: toggle!,
      message: message,
      radius: EmployeeFactFrame.radius,
      width: size,
      height: size,
      color: Colors.transparent,
      feedbackColor: scheme.line,
      child: mark
    );
  }
}
