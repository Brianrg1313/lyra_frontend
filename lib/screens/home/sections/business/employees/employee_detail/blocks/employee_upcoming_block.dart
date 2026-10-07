import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_employee_detail_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/business/employees/employee_facts/employee_event.dart';
import 'package:app/screens/home/sections/business/employees/employee_facts/employee_section.dart';
import 'package:app/screens/home/sections/business/employees/employee_format.dart';

import './employee_block_values.dart';

class EmployeeUpcomingBlock extends StatelessWidget {
  const EmployeeUpcomingBlock({super.key, required this.leaves});

  final List<EmployeeLeave> leaves;

  @override
  Widget build(BuildContext context) => EmployeeSection(
    title: S.of(context).employee_upcoming_title,
    children: [
      for (final leave in leaves) EmployeeEvent(
        date: leave.startDate,
        title: employeeLeaveLabel(context, leave.type),
        subtitle: employeeJoined([
          employeeRangeLabel(context, leave.startDate, leave.endDate),
          S.of(context).employee_leave_days(leave.days),
          leave.note
        ], " · ")
      )
    ]
  );
}
