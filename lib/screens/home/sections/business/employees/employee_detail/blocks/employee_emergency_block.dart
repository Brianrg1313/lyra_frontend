import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_employee_detail_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/business/employees/employee_facts/_employee_facts.dart';
import 'package:app/screens/home/sections/business/employees/employee_facts/employee_phone_fact.dart';
import 'package:app/screens/home/sections/business/employees/employee_facts/employee_section.dart';
import 'package:app/screens/home/sections/business/employees/employee_facts/employee_text_fact.dart';

import './employee_block_values.dart';
import './employee_editor.dart';

class EmployeeEmergencyBlock extends StatelessWidget {
  const EmployeeEmergencyBlock({super.key, required this.person, required this.edit});

  final EmployeePerson person;
  final EmployeeEditor edit;

  @override
  Widget build(BuildContext context) {
    final text = S.of(context);
    final none = text.employee_value_none;
    final editable = edit.person;

    return EmployeeSection(
      title: text.employee_emergency_title,
      children: [EmployeeFacts(facts: [
        EmployeeTextFact(
          icon: CI.support,
          // Read-only, the relation names the tile ("Brother") the way the
          // name alone would not; edited, each has its own.
          label: editable || person.emergencyRelation.isEmpty
            ? text.employee_field_emergency_name
            : person.emergencyRelation,
          value: person.emergencyName,
          empty: none,
          enabled: editable,
          validate: (value) => employeeCheckName(context, text.employee_field_emergency_name, value),
          onSave: edit.savePerson("EMERGENCY_NAME")
        ),
        if (editable) EmployeeTextFact(
          icon: CI.support,
          label: text.employee_field_emergency_relation,
          value: person.emergencyRelation,
          empty: none,
          validate: (value) => employeeCheckName(context, text.employee_field_emergency_relation, value),
          onSave: edit.savePerson("EMERGENCY_RELATION")
        ),
        if (editable || person.emergencyPhone.isNotEmpty) EmployeePhoneFact(
          icon: CI.phone,
          label: text.employee_field_phone,
          value: person.emergencyPhone,
          country: person.country.isEmpty ? employeeCompanyCountry(context) : person.country,
          empty: none,
          enabled: editable,
          onSave: edit.savePerson("EMERGENCY_PHONE")
        )
      ])]
    );
  }
}
