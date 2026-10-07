import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_employee_model.dart';
import 'package:app/services/permissions/permissions_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/business/employees/employee_facts/_employee_facts.dart';
import 'package:app/screens/home/sections/business/employees/employee_facts/widgets/employee_fact_frame.dart';

import './employee_action.dart';
import './employee_action_cell.dart';

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
                      ? EmployeeActionCell(action: actions[i], employee: employee)
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
