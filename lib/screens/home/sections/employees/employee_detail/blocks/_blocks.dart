import 'package:flutter/material.dart';

// SERVICES
import 'package:app/services/business/business_employee_detail_model.dart';
import 'package:app/services/business/business_employee_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/employees/employee_detail/employee_part.dart';

import './employee_editor.dart';
import './employee_emergency_block.dart';
import './employee_ending_block.dart';
import './employee_job_block.dart';
import './employee_leave_now_block.dart';
import './employee_notes_block.dart';
import './employee_person_block.dart';
import './employee_record_block.dart';
import './employee_tenure_block.dart';
import './employee_upcoming_block.dart';
import './employee_work_contact_block.dart';

/// The blocks of one [part] of the card, in the order they are looked for.
/// [EmployeePart.permissions] has none: it is a page of its own.
///
/// Blocks that have nothing to say are left out rather than drawn empty —
/// except the job and the person, which say what is missing in words, and
/// the ones that can be filled from here, which are the only place to do it.
/// A part left with no block is not offered (`EmployeeDetailPage`).
List<Widget> employeePartBlocks(
  BuildContext context,
  EmployeePart part,
  BusinessEmployeeDetail detail,
  {bool own = false}
) {
  final edit = EmployeeEditor(context, detail, own: own);

  return switch (part) {
    EmployeePart.personal => [
      EmployeePersonBlock(detail: detail, edit: edit),
      if (detail.fullProfile && (edit.person || _hasEmergency(detail.person)))
        EmployeeEmergencyBlock(person: detail.person, edit: edit)
    ],
    EmployeePart.job => [
      if (detail.state != EmployeeState.invited) EmployeeTenureBlock(detail: detail),
      EmployeeJobBlock(detail: detail, edit: edit),
      if (edit.job || detail.job.workEmail.isNotEmpty || detail.job.workPhone.isNotEmpty)
        EmployeeWorkContactBlock(job: detail.job, edit: edit)
    ],
    EmployeePart.absences => [
      if (detail.leave != null) EmployeeLeaveNowBlock(leave: detail.leave!),
      if (detail.upcomingLeaves.isNotEmpty) EmployeeUpcomingBlock(leaves: detail.upcomingLeaves)
    ],
    EmployeePart.record => [
      if (detail.ending != null) EmployeeEndingBlock(ending: detail.ending!),
      if (detail.invitedAt != null) EmployeeRecordBlock(detail: detail)
    ],
    EmployeePart.notes => [
      if (edit.job || detail.job.notes.isNotEmpty) EmployeeNotesBlock(notes: detail.job.notes, edit: edit)
    ],
    EmployeePart.permissions => const []
  };
}

bool _hasEmergency(EmployeePerson person) =>
  person.emergencyName.isNotEmpty || person.emergencyPhone.isNotEmpty;
