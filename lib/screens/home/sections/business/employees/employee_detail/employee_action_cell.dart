import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_employee_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/business/employees/employee_facts/widgets/employee_fact_frame.dart';
import 'package:app/screens/home/sections/business/employees/employee_permissions/_employee_permissions.dart';
import 'package:app/screens/home/sections/business/employees/own_settings/_own_settings.dart';
import 'package:app/screens/modals/business/employee_tool/_employee_tool.dart';

import './employee_action.dart';

class EmployeeActionCell extends StatelessWidget {
  const EmployeeActionCell({super.key, required this.action, required this.employee});

  final EmployeeAction action;
  final BusinessEmployeeModel employee;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final label = action.label(context);
    final description = action.description(context, own: employee.me);
    final box = AppSize.text * 2.2;

    return FeedbackButton(
      action: () => showEmployeeTool(
        context,
        icon: action.icon,
        title: label,
        description: description,
        person: employee.fullName,
        builder: switch (action) {
          // One's own are shown, never changed (the backend refuses a
          // self-assignment too).
          EmployeeAction.permissions => (_) => employee.me
            ? const EmployeePermissions()
            : EmployeePermissions(username: employee.username, person: employee.fullName),
          // One's own account; someone else's job settings have no backend yet.
          EmployeeAction.settings when employee.me => (_) => const OwnSettings(),
          _ => null
        }
      ),
      message: label,
      radius: EmployeeFactFrame.radius,
      color: scheme.surfaceOver.withValues(alpha: 0.5),
      feedbackColor: scheme.line,
      padding: EmployeeFactFrame.padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: box,
                height: box,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(EmployeeFactFrame.radius)
                ),
                child: Center(child: Icon(action.icon, size: EmployeeFactFrame.iconSize, color: scheme.primary))
              ),
              const Spacer(),
              Icon(CI.arrow_right, size: EmployeeFactFrame.hintSize, color: scheme.text.secondary)
            ]
          ),
          SizedBox(height: AppSize.spaceXS),
          TextMedium(label, bold: true, ellipsis: true),
          TextSmall(description, lines: 2, ellipsis: true, color: scheme.text.secondary)
        ]
      )
    );
  }
}
