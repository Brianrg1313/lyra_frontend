import 'package:flutter/material.dart';

// SERVICES
import 'package:app/services/business/business_employee_detail_model.dart';
import 'package:app/services/business/business_employee_model.dart';

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

/// The blocks of the detail panel, in the order they are looked for: who the
/// person is, how long and on what contract, whether they are here today, how
/// to reach them, the job, what absences are coming, and the record of how it
/// started and ended.
///
/// Blocks that have nothing to say are left out rather than drawn empty —
/// except the job and the person, which say what is missing in words, and
/// the ones that can be filled from here, which are the only place to do it.
List<Widget> employeeBlocks(BuildContext context, BusinessEmployeeDetail detail, {bool own = false}) {
  final edit = EmployeeEditor(context, detail, own: own);

  return [
    EmployeePersonBlock(detail: detail, edit: edit),
    if (detail.state != EmployeeState.invited) EmployeeTenureBlock(detail: detail),
    if (detail.leave != null) EmployeeLeaveNowBlock(leave: detail.leave!),
    if (detail.ending != null) EmployeeEndingBlock(ending: detail.ending!),
    if (edit.job || detail.job.workEmail.isNotEmpty || detail.job.workPhone.isNotEmpty)
      EmployeeWorkContactBlock(job: detail.job, edit: edit),
    EmployeeJobBlock(detail: detail, edit: edit),
    if (detail.fullProfile && (edit.person || _hasEmergency(detail.person)))
      EmployeeEmergencyBlock(person: detail.person, edit: edit),
    if (detail.upcomingLeaves.isNotEmpty) EmployeeUpcomingBlock(leaves: detail.upcomingLeaves),
    if (detail.invitedAt != null) EmployeeRecordBlock(detail: detail),
    if (edit.job || detail.job.notes.isNotEmpty) EmployeeNotesBlock(notes: detail.job.notes, edit: edit)
  ];
}

bool _hasEmergency(EmployeePerson person) =>
  person.emergencyName.isNotEmpty || person.emergencyPhone.isNotEmpty;
