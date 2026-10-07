import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_employee_detail_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/business/employees/employee_facts/employee_event.dart';
import 'package:app/screens/home/sections/business/employees/employee_facts/employee_note.dart';
import 'package:app/screens/home/sections/business/employees/employee_facts/employee_section.dart';
import 'package:app/screens/home/sections/business/employees/employee_format.dart';

import './employee_block_values.dart';

/// How the job ended. It goes near the top on a former employee: it is the
/// first thing asked about them.
class EmployeeEndingBlock extends StatelessWidget {
  const EmployeeEndingBlock({super.key, required this.ending});

  final EmployeeEnding ending;

  @override
  Widget build(BuildContext context) {
    final text = S.of(context);
    final reason = employeeEndReasonLabel(context, ending.reason);

    return EmployeeSection(
      title: text.employee_ending_title,
      children: [
        EmployeeEvent(
          date: ending.date,
          title: text.employee_field_ended,
          subtitle: employeeJoined([
            employeeDayLabel(context, ending.date),
            reason.isEmpty ? text.employee_value_none : reason
          ], " · ")
        ),
        if (ending.note.isNotEmpty) EmployeeNote(title: text.employee_field_note, text: ending.note, lines: 4)
      ]
    );
  }
}
