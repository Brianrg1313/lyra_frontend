import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_employee_detail_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/employees/employee_facts/_employee_facts.dart';
import 'package:app/screens/home/sections/employees/employee_facts/employee_fact.dart';
import 'package:app/screens/home/sections/employees/employee_facts/employee_section.dart';
import 'package:app/screens/home/sections/employees/employee_format.dart';

/// When the job was filed and when the person answered.
class EmployeeRecordBlock extends StatelessWidget {
  const EmployeeRecordBlock({super.key, required this.detail});

  final BusinessEmployeeDetail detail;

  @override
  Widget build(BuildContext context) {
    final text = S.of(context);

    return EmployeeSection(
      title: text.employee_record_title,
      children: [EmployeeFacts(facts: [
        EmployeeFact(
          icon: CI.mail,
          label: text.employee_field_invited,
          value: employeeMomentLabel(context, detail.invitedAt)
        ),
        EmployeeFact(
          icon: CI.check,
          label: text.employee_field_responded,
          value: employeeMomentLabel(context, detail.respondedAt),
          empty: text.employee_value_waiting
        )
      ])]
    );
  }
}
