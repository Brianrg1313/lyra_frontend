import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_employee_detail_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/employees/employee_facts/employee_event.dart';
import 'package:app/screens/home/sections/employees/employee_facts/employee_note.dart';
import 'package:app/screens/home/sections/employees/employee_facts/employee_section.dart';
import 'package:app/screens/home/sections/employees/employee_format.dart';

import './employee_block_values.dart';

/// The absence running today, first: it is what changes what can be asked of
/// them.
class EmployeeLeaveNowBlock extends StatelessWidget {
  const EmployeeLeaveNowBlock({super.key, required this.leave});

  final EmployeeLeave leave;

  @override
  Widget build(BuildContext context) {
    final text = S.of(context);

    return EmployeeSection(
      title: text.employee_leave_now_title,
      children: [
        EmployeeEvent(
          date: leave.startDate,
          color: ThemeColor.of(context).chart.warning,
          title: employeeLeaveLabel(context, leave.type),
          subtitle: employeeJoined([
            employeeRangeLabel(context, leave.startDate, leave.endDate),
            text.employee_leave_days(leave.days)
          ], " · ")
        ),
        if (leave.note.isNotEmpty) EmployeeNote(title: text.employee_field_note, text: leave.note, lines: 4)
      ]
    );
  }
}
