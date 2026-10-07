import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/home/sections/business/employees/employee_facts/widgets/employee_fact_frame.dart';
import 'package:app/screens/home/sections/business/employees/employee_facts/widgets/employee_fact_value.dart';
import 'package:app/screens/home/sections/business/employees/employee_facts/widgets/employee_hint.dart';
import 'package:app/screens/home/sections/business/employees/employee_facts/widgets/employee_hover.dart';

import './_employee_facts.dart';
import './employee_copy.dart';

/// One datum that is only read: its icon, what it is called, and its value.
///
/// With [copy], a tile holding a value copies it on a tap: it is what is taken
/// out of the app (a phone, a document number).
class EmployeeFact extends StatelessWidget implements EmployeeTile {
  const EmployeeFact({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.empty,
    this.copy = false,
    this.wide = false,
    this.lines = 1
  });

  final IconData icon;
  @override
  final String label;
  @override
  final String value;
  final String? empty;
  final bool copy;
  @override
  final bool wide;
  final int lines;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final copyable = copy && value.trim().isNotEmpty;

    if (!copyable) {
      return Surface(
        color: scheme.surface,
        radius: EmployeeFactFrame.radius,
        padding: EmployeeFactFrame.padding,
        child: EmployeeFactFrame(
          icon: icon,
          label: label,
          child: EmployeeFactValue(value: value, empty: empty, lines: lines)
        )
      );
    }

    return EmployeeHover(builder: (context, hover) => FeedbackButton(
      action: () => employeeCopy(context, value, label),
      message: S.of(context).employee_copy,
      color: scheme.surface,
      feedbackColor: scheme.line,
      radius: EmployeeFactFrame.radius,
      padding: EmployeeFactFrame.padding,
      child: EmployeeFactFrame(
        icon: icon,
        label: label,
        trailing: EmployeeHint(
          shown: hover,
          child: Icon(CI.copy, size: EmployeeFactFrame.hintSize, color: scheme.text.secondary)
        ),
        child: EmployeeFactValue(value: value, empty: empty, lines: lines)
      )
    ));
  }
}
