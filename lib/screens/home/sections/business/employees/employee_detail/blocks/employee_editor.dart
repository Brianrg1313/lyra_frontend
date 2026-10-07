import 'package:flutter/material.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_employee_detail_model.dart';
import 'package:app/services/business/business_employee_model.dart';
import 'package:app/services/business/business_employees_service.dart';
import 'package:app/services/business/business_places_model.dart';
import 'package:app/services/permissions/permissions_service.dart';

// WIDGETS


/// What of one detail can be changed from the panel, and how a change travels
/// (`PUT /business/employees/`, see [BusinessEmployeesService.edit]; the
/// viewer's own personal data `PUT /profile/`, see
/// [BusinessEmployeesService.editOwn]).
class EmployeeEditor {
  EmployeeEditor(this.context, this.detail, {this.own = false});

  final BuildContext context;
  final BusinessEmployeeDetail detail;

  /// The detail is the viewer's own employment.
  final bool own;

  /// The job: with `employees.manage`, while it is invited or active — the
  /// backend refuses a closed one.
  bool get job =>
    // The app's tree has no edit action of its own: inviting is the area that
    // maps to the backend's `employees.manage`, the grant the edit needs.
    PermissionsService().can("business.employees.invite") &&
    (detail.state == EmployeeState.invited || detail.state == EmployeeState.active);

  /// The personal data: while the job is active. It is the person's own
  /// profile, so a change reaches their account and every other employer.
  /// The viewer always writes their own, with or without a permission.
  bool get person => detail.fullProfile && (own || (job && detail.profileEditable));

  /// Saves one backend key with what a tile sent, reshaped by [shape] (a
  /// salary typed with a comma travels with a dot).
  Future<bool> Function(String value) save(String key, [String Function(String value)? shape]) =>
    (value) => context.read<BusinessEmployeesService>().edit(
      context,
      detail.id,
      {key: shape == null || value.isEmpty ? value : shape(value)}
    );

  /// Saves one personal key like [save]; the viewer's own through their
  /// profile, since the company endpoint needs `employees.manage`.
  Future<bool> Function(String value) savePerson(String key) =>
    (value) => _person({key: value});

  Future<bool> _person(Map<String, dynamic> changes) {
    final service = context.read<BusinessEmployeesService>();

    return own
      ? service.editOwn(context, detail.id, changes)
      : service.edit(context, detail.id, changes);
  }

  /// Saves a place picked from the address search: the street line and the
  /// parts it came with, in one change. A part the place did not answer is
  /// left as it was rather than erased.
  Future<bool> place(PlaceModel place) => _person({
    "ADDRESS": place.address,
    if (place.city.isNotEmpty) "CITY": place.city,
    if (place.region.isNotEmpty) "REGION": place.region,
    if (place.postalCode.isNotEmpty) "POSTAL_CODE": place.postalCode,
    if (place.country.isNotEmpty) "COUNTRY": place.country
  });
}
