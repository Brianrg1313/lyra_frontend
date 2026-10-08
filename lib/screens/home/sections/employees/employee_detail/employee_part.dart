import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import './_employee_detail.dart';

/// The parts of one person's card: each is a row of their detail page and opens
/// a page of its own, where it is read and edited.
///
/// Each part **is a URL** (`/home/employees/:id/job`), like the business tabs:
/// `Navis` tells the shell of a page change by its key, so one route with a
/// `:part` argument would change the URL without the page knowing. The routes
/// come from here (see `routes`).
enum EmployeePart {
  personal(CI.user),
  job(CI.employee_badge),
  absences(CI.calendar),
  record(CI.documents),
  notes(CI.pen),
  permissions(CI.safe_user);

  const EmployeePart(this.icon);

  final IconData icon;

  /// Key of the [ScreenRoute] of this part.
  String get routeKey => "employee_$name";

  /// URL of this part for the person [id] (`EmployeeDetailPage.path`'s).
  String path(String id) => "${EmployeeDetailPage.path(id)}/$name";

  static final Map<String, EmployeePart> _byRouteKey = {
    for (final part in values) part.routeKey: part
  };

  static EmployeePart? byRouteKey(String key) => _byRouteKey[key];

  String title(BuildContext context) => switch (this) {
    personal => S.of(context).employee_person_title,
    job => S.of(context).employee_job_title,
    absences => S.of(context).employee_part_absences,
    record => S.of(context).employee_record_title,
    notes => S.of(context).employee_notes_title,
    permissions => S.of(context).employee_part_permissions
  };

  String subtitle(BuildContext context) => switch (this) {
    personal => S.of(context).employee_part_personal_subtitle,
    job => S.of(context).employee_part_job_subtitle,
    absences => S.of(context).employee_part_absences_subtitle,
    record => S.of(context).employee_part_record_subtitle,
    notes => S.of(context).employee_notes_subtitle,
    permissions => S.of(context).employee_part_permissions_subtitle
  };
}
