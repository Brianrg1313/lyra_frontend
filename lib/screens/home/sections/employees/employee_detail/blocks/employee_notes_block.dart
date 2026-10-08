import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/home/sections/employees/employee_facts/_employee_facts.dart';
import 'package:app/screens/home/sections/employees/employee_facts/employee_note.dart';
import 'package:app/screens/home/sections/employees/employee_facts/employee_section.dart';
import 'package:app/screens/home/sections/employees/employee_facts/employee_text_fact.dart';

import './employee_editor.dart';

class EmployeeNotesBlock extends StatelessWidget {
  const EmployeeNotesBlock({super.key, required this.notes, required this.edit});

  final String notes;
  final EmployeeEditor edit;

  @override
  Widget build(BuildContext context) => EmployeeSection(
    title: S.of(context).employee_notes_title,
    subtitle: S.of(context).employee_notes_subtitle,
    children: [
      if (edit.job) EmployeeFacts(facts: [EmployeeTextFact(
        icon: CI.pen,
        label: S.of(context).employee_notes_title,
        value: notes,
        empty: S.of(context).employee_value_none,
        wide: true,
        lines: 12,
        onSave: edit.save("NOTES")
      )])
      else EmployeeNote(text: notes)
    ]
  );
}
