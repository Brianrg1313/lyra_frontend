import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/section_message.dart';

/// Opens one of an employee's panels (permissions, settings, activity, sales)
/// beside the detail. The caller names it: the modal decides nothing about which one.
/// [builder] draws the panel's body; without it, the "coming soon" placeholder.
Future<void> showEmployeeTool(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String description,
  required String person,
  WidgetBuilder? builder
}) async {
  final width = employeeToolWidth(context);

  await showSideModal(
    context: context,
    title: person.isEmpty ? title : "$title · $person",
    minWidth: width,
    maxWidth: width,
    builder: builder ?? (context) => EmployeeToolModal(icon: icon, description: description)
  );
}

/// The width of an employee's panel, and of the panels opened from it: a stacked one as wide as
/// the one it covers leaves the older's quarter showing evenly.
double employeeToolWidth(BuildContext context) =>
  math.min(AppSize.action * 12, MediaQuery.of(context).size.width * .55);

/// Placeholder until each panel has its backend: says what it will hold.
class EmployeeToolModal extends StatelessWidget {
  const EmployeeToolModal({super.key, required this.icon, required this.description});

  final IconData icon;
  final String description;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(AppSize.padding),
    child: SectionMessage(
      icon: icon,
      title: S.of(context).employee_action_soon_title,
      subtitle: description
    )
  );
}
