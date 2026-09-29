import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:intl/intl.dart';

// SERVICES
import 'package:app/services/business/business_employee_detail_model.dart';
import 'package:app/services/business/business_employee_model.dart';

/// Where a person stands, as the list and the detail header say it in one tag:
/// the lifecycle first (invited, former, no job filed) and, for the active
/// ones, where they are today.
({String label, Color color, IconData icon}) employeePresence(
  BuildContext context, {
  required EmployeeState? state,
  required EmployeeWorkStatus? work
}) {
  final text = S.of(context);
  final scheme = ThemeColor.of(context);

  return switch (state) {
    null => (label: text.employee_state_unfiled, color: scheme.text.secondary, icon: CI.user),
    EmployeeState.invited => (label: text.employee_state_invited, color: scheme.primary, icon: CI.mail),
    EmployeeState.ended => (label: text.employee_state_ended, color: scheme.text.secondary, icon: CI.log_out),
    EmployeeState.declined => (label: text.employee_state_declined, color: scheme.text.secondary, icon: CI.info),
    EmployeeState.cancelled => (label: text.employee_state_cancelled, color: scheme.text.secondary, icon: CI.info),
    EmployeeState.active => switch (work?.kind) {
      EmployeeWorkKind.away => (
        label: employeeLeaveLabel(context, work!.leave),
        color: scheme.chart.warning,
        icon: CI.calendar
      ),
      EmployeeWorkKind.notStarted => (
        label: text.employee_work_not_started,
        color: scheme.primary,
        icon: CI.calendar
      ),
      _ => (label: text.employee_work_working, color: scheme.chart.good, icon: CI.employee_badge)
    }
  };
}

String employeeLeaveLabel(BuildContext context, EmployeeLeaveType? type) {
  final text = S.of(context);

  return switch (type) {
    EmployeeLeaveType.vacation => text.employee_leave_vacation,
    EmployeeLeaveType.sick => text.employee_leave_sick,
    EmployeeLeaveType.maternity => text.employee_leave_maternity,
    EmployeeLeaveType.paternity => text.employee_leave_paternity,
    EmployeeLeaveType.personal => text.employee_leave_personal,
    EmployeeLeaveType.unpaid => text.employee_leave_unpaid,
    EmployeeLeaveType.suspension => text.employee_leave_suspension,
    EmployeeLeaveType.other || null => text.employee_leave_other
  };
}

String employeeContractLabel(BuildContext context, EmployeeContract? contract) {
  final text = S.of(context);

  return switch (contract) {
    EmployeeContract.permanent => text.employee_contract_permanent,
    EmployeeContract.fixedTerm => text.employee_contract_fixed_term,
    EmployeeContract.probation => text.employee_contract_probation,
    EmployeeContract.internship => text.employee_contract_internship,
    EmployeeContract.freelance => text.employee_contract_freelance,
    EmployeeContract.temporary => text.employee_contract_temporary,
    null => ""
  };
}

String employeeWorkdayLabel(BuildContext context, EmployeeWorkday? workday) {
  final text = S.of(context);

  return switch (workday) {
    EmployeeWorkday.fullTime => text.employee_workday_full_time,
    EmployeeWorkday.partTime => text.employee_workday_part_time,
    EmployeeWorkday.hourly => text.employee_workday_hourly,
    EmployeeWorkday.shifts => text.employee_workday_shifts,
    null => ""
  };
}

String employeePeriodLabel(BuildContext context, EmployeePayPeriod? period) {
  final text = S.of(context);

  return switch (period) {
    EmployeePayPeriod.hour => text.employee_period_hour,
    EmployeePayPeriod.day => text.employee_period_day,
    EmployeePayPeriod.week => text.employee_period_week,
    EmployeePayPeriod.fortnight => text.employee_period_fortnight,
    EmployeePayPeriod.month => text.employee_period_month,
    EmployeePayPeriod.year => text.employee_period_year,
    null => ""
  };
}

String employeeEndReasonLabel(BuildContext context, EmployeeEndReason? reason) {
  final text = S.of(context);

  return switch (reason) {
    EmployeeEndReason.resignation => text.employee_end_resignation,
    EmployeeEndReason.dismissal => text.employee_end_dismissal,
    EmployeeEndReason.contractEnd => text.employee_end_contract_end,
    EmployeeEndReason.mutual => text.employee_end_mutual,
    EmployeeEndReason.other => text.employee_end_other,
    null => ""
  };
}

String employeeDocumentLabel(BuildContext context, EmployeeDocument? document) {
  final text = S.of(context);

  return switch (document) {
    EmployeeDocument.nationalId => text.employee_document_national_id,
    EmployeeDocument.passport => text.employee_document_passport,
    EmployeeDocument.foreignId => text.employee_document_foreign_id,
    EmployeeDocument.taxId => text.employee_document_tax_id,
    null => ""
  };
}

String employeeSexLabel(BuildContext context, EmployeeSex? sex) {
  final text = S.of(context);

  return switch (sex) {
    EmployeeSex.female => text.employee_sex_female,
    EmployeeSex.male => text.employee_sex_male,
    EmployeeSex.other => text.employee_sex_other,
    null => ""
  };
}

/// Only the contract states worth a warning get a tag: a current contract is
/// the normal case and says nothing, and the closed ones are already the
/// lifecycle tag.
({String label, Color color})? employeeContractWarning(
  BuildContext context,
  EmployeeContractStatus? status
) {
  final chart = ThemeColor.of(context).chart;

  return switch (status) {
    EmployeeContractStatus.expiring => (label: S.of(context).employee_contract_expiring, color: chart.warning),
    EmployeeContractStatus.expired => (label: S.of(context).employee_contract_expired, color: chart.critical),
    _ => null
  };
}

/// A calendar day, in the language the screen is read in. Empty for none.
String employeeDayLabel(BuildContext context, DateTime? day) =>
  day == null ? "" : DateFormat.yMMMd(_locale(context)).format(day);

/// A moment (an invitation, an answer): day and hour.
String employeeMomentLabel(BuildContext context, DateTime? at) {
  if (at == null) return "";

  final locale = _locale(context);

  return "${DateFormat.yMMMd(locale).format(at)} · ${DateFormat.jm(locale).format(at)}";
}

/// `2 years, 3 months` — the two largest parts are enough to read a tenure;
/// the days are said only when there is nothing larger. Zero reads as "less
/// than a day", not as an empty value.
String employeeSpanLabel(BuildContext context, EmployeeSpan span) {
  final text = S.of(context);

  final parts = [
    if (span.years > 0) text.employee_years(span.years),
    if (span.months > 0) text.employee_months(span.months),
    if (span.years == 0 && span.days > 0) text.employee_days(span.days)
  ];

  return parts.isEmpty ? text.employee_span_none : parts.take(2).join(", ");
}

/// A date range with its ends inclusive: `Mar 3 – Mar 9, 2026`.
String employeeRangeLabel(BuildContext context, DateTime? from, DateTime? to) {
  final start = employeeDayLabel(context, from);
  final end = employeeDayLabel(context, to);

  if (start.isEmpty || end.isEmpty || start == end) return start.isEmpty ? end : start;

  return "$start – $end";
}

/// The two lines of a calendar leaf: `MAR` over `14`. Dashes for no date.
({String month, String day}) employeeCalendarLeaf(BuildContext context, DateTime? day) {
  if (day == null) return (month: "—", day: "—");

  return (
    month: DateFormat.MMM(_locale(context)).format(day).replaceAll(".", "").toUpperCase(),
    day: "${day.day}"
  );
}

String _locale(BuildContext context) => Localizations.localeOf(context).toString();
