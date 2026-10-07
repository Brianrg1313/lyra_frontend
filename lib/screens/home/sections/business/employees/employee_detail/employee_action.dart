import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES

// WIDGETS


/// The panels about the person that are not data of their card: each opens
/// beside the detail instead of growing it.
enum EmployeeAction {
  permissions(CI.safe_user),
  settings(CI.setting),
  activity(CI.task_list),
  sales(CI.sale);

  const EmployeeAction(this.icon);

  final IconData icon;

  String label(BuildContext context) => switch (this) {
    permissions => S.of(context).employee_action_permissions,
    settings => S.of(context).employee_action_settings,
    activity => S.of(context).employee_action_activity,
    sales => S.of(context).employee_action_sales
  };

  /// [own]: the viewer's card, where the settings are their own account's, not their job's.
  String description(BuildContext context, {bool own = false}) => switch (this) {
    permissions => S.of(context).employee_action_permissions_description,
    settings => own
      ? S.of(context).employee_action_settings_own_description
      : S.of(context).employee_action_settings_description,
    activity => S.of(context).employee_action_activity_description,
    sales => S.of(context).employee_action_sales_description
  };
}
