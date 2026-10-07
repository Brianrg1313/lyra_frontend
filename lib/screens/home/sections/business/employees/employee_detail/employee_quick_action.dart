import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/home/sections/business/employees/employee_facts/employee_copy.dart';
import 'package:app/screens/home/sections/business/employees/employee_facts/widgets/employee_fact_frame.dart';

/// A square icon button of the header: copies a way to reach the person.
class EmployeeQuickAction extends StatelessWidget {
  const EmployeeQuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.value
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final size = AppSize.text * 2.2;

    return FeedbackButton(
      action: () => employeeCopy(context, value, label),
      message: "$label · $value",
      width: size,
      height: size,
      radius: AppSize.cornerInset(AppSize.gap, AppSize.gap * 1.5),
      color: scheme.surface.withValues(alpha: 0.6),
      feedbackColor: scheme.line,
      child: Center(child: Icon(icon, size: EmployeeFactFrame.iconSize, color: scheme.text.primary))
    );
  }
}
