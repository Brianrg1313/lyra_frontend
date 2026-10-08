import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

import './employee_row.dart';

/// Names the columns of the wide rows, once, above them.
class EmployeeListColumns extends StatelessWidget {
  const EmployeeListColumns({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final text = S.of(context);

    Widget label(String value) => TextSmall(
      value,
      multiplier: 0.9,
      ellipsis: true,
      color: scheme.text.secondary
    );

    return Padding(
      padding: EdgeInsets.only(
        left: AppSize.spaceXS,
        right: AppSize.spaceXS,
        bottom: AppSize.gap
      ),
      child: Row(children: [
        SizedBox(width: AppSize.action + AppSize.spaceXS),
        Expanded(flex: 4, child: label(text.employees_column_person)),
        Expanded(flex: 2, child: label(text.employees_column_contract)),
        Expanded(flex: 2, child: label(text.employees_column_since)),
        SizedBox(width: EmployeeRow.statusWidth, child: label(text.employees_column_status))
      ])
    );
  }
}
