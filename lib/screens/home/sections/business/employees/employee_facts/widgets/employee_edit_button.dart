import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/home/sections/business/employees/employee_facts/employee_copy.dart';

import './employee_fact_frame.dart';
import './employee_fact_value.dart';
import './employee_hint.dart';
import './employee_hover.dart';

/// A closed typed tile: its value and, under the pointer, a copy button when
/// [copy] and the pencil that says a click edits it.
class EmployeeEditButton extends StatelessWidget {
  const EmployeeEditButton({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onOpen,
    this.empty,
    this.copy = false,
    this.lines = 1
  });

  final IconData icon;
  final String label;
  final String value;
  final String? empty;
  final bool copy;
  final int lines;
  final void Function() onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final copyable = copy && value.trim().isNotEmpty;

    return EmployeeHover(builder: (context, hover) => FeedbackButton(
      action: onOpen,
      message: S.of(context).employee_edit_hint(label),
      color: scheme.surface,
      feedbackColor: scheme.line,
      radius: EmployeeFactFrame.radius,
      padding: EmployeeFactFrame.padding,
      child: EmployeeFactFrame(
        icon: icon,
        label: label,
        trailing: EmployeeHint(
          shown: hover,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (copyable) ...[
                _Copy(value: value, label: label),
                SizedBox(width: AppSize.gap * 0.5)
              ],
              Icon(CI.edit, size: EmployeeFactFrame.hintSize, color: scheme.text.secondary)
            ]
          )
        ),
        child: EmployeeFactValue(value: value, empty: empty, lines: lines)
      )
    ));
  }
}

/// Copies a tile's value without opening its field.
class _Copy extends StatelessWidget {
  const _Copy({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final size = AppSize.text * 1.9;

    return FeedbackButton(
      action: () => employeeCopy(context, value, label),
      message: S.of(context).employee_copy,
      width: size,
      height: size,
      radius: AppSize.cornerInset(AppSize.gap, AppSize.gap * 1.5),
      color: scheme.surface,
      feedbackColor: scheme.line,
      child: Center(child: Icon(CI.copy, size: EmployeeFactFrame.hintSize, color: scheme.text.secondary))
    );
  }
}
