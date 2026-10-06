import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_employee_model.dart';
import 'package:app/services/permissions/permissions_service.dart';

// WIDGETS
import 'package:app/screens/modals/business/employee_tool/_employee_tool.dart';

import './employee_card.dart';
import './employee_permissions.dart';
import './own_settings/_own_settings.dart';

/// The panels about the person that are not data of their card: each opens
/// beside the detail instead of growing it.
enum EmployeeAction {
  permissions(CI.safe_user),
  settings(CI.setting),
  activity(CI.task_list),
  sales(CI.sale);

  const EmployeeAction(this.icon);

  final IconData icon;

  String label(BuildContext context) => switch (this) {
    permissions => S.of(context).employee_action_permissions,
    settings => S.of(context).employee_action_settings,
    activity => S.of(context).employee_action_activity,
    sales => S.of(context).employee_action_sales
  };

  /// [own]: the viewer's card, where the settings are their own account's, not their job's.
  String description(BuildContext context, {bool own = false}) => switch (this) {
    permissions => S.of(context).employee_action_permissions_description,
    settings => own
      ? S.of(context).employee_action_settings_own_description
      : S.of(context).employee_action_settings_description,
    activity => S.of(context).employee_action_activity_description,
    sales => S.of(context).employee_action_sales_description
  };
}

/// One sheet under the search, a grid of [EmployeeAction] cells: drawn like
/// the blocks below it so it reads as part of the card, not as a toolbar.
/// Two columns, one when the panel is as narrow as [EmployeeFacts] folds at.
class EmployeeActions extends StatelessWidget {
  const EmployeeActions({super.key, required this.employee});

  final BusinessEmployeeModel employee;

  @override
  Widget build(BuildContext context) {
    final gap = AppSize.gap * 0.5;

    // Someone else's permissions open only for whoever may read and assign them; one's own,
    // always.
    final permitted = employee.me || context.watch<PermissionsService>().can("business.employees.permissions");
    final actions = [
      for (final action in EmployeeAction.values)
        if (action != EmployeeAction.permissions || permitted) action
    ];

    return Surface(
      color: ThemeColor.of(context).surface,
      radius: EmployeeFactFrame.sheetRadius,
      padding: EdgeInsets.all(gap),
      child: LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth < AppSize.action * 8 ? 1 : 2;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var start = 0; start < actions.length; start += columns) ...[
              if (start > 0) SizedBox(height: gap),
              // Stretched per row: a cell whose description takes one line
              // keeps the height of its neighbour's two.
              IntrinsicHeight(child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = start; i < start + columns; i++) ...[
                    if (i > start) SizedBox(width: gap),
                    Expanded(child: i < actions.length
                      ? _ActionCell(action: actions[i], employee: employee)
                      : const SizedBox.shrink())
                  ]
                ]
              ))
            ]
          ]
        );
      })
    );
  }
}

class _ActionCell extends StatelessWidget {
  const _ActionCell({required this.action, required this.employee});

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
