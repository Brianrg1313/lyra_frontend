import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_employee_detail_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/employees/employee_facts/_employee_facts.dart';
import 'package:app/screens/home/sections/employees/employee_facts/employee_phone_fact.dart';
import 'package:app/screens/home/sections/employees/employee_facts/employee_section.dart';
import 'package:app/screens/home/sections/employees/employee_facts/employee_text_fact.dart';

import './employee_block_values.dart';
import './employee_editor.dart';

class EmployeeWorkContactBlock extends StatelessWidget {
  const EmployeeWorkContactBlock({super.key, required this.job, required this.edit});

  final EmployeeJob job;
  final EmployeeEditor edit;

  @override
  Widget build(BuildContext context) {
    final text = S.of(context);
    final none = text.employee_value_none;

    return EmployeeSection(
      title: text.employee_work_contact_title,
      children: [EmployeeFacts(facts: [
        if (edit.job || job.workPhone.isNotEmpty) EmployeePhoneFact(
          icon: CI.phone,
          label: text.employee_field_phone,
          value: job.workPhone,
          country: employeeCompanyCountry(context),
          empty: none,
          enabled: edit.job,
          onSave: edit.save("WORK_PHONE")
        ),
        if (edit.job || job.workEmail.isNotEmpty) EmployeeTextFact(
          icon: CI.mail,
          label: text.employee_field_email,
          value: job.workEmail,
          empty: none,
          copy: true,
          enabled: edit.job,
          validate: (value) => employeeCheckEmail(context, value),
          onSave: edit.save("WORK_EMAIL")
        )
      ])]
    );
  }
}
