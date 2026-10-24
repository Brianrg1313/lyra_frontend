import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/appointments/opening_hours_service.dart';
import 'package:app/services/business/branch_service.dart';
import 'package:app/services/business/business_branch_model.dart';

// WIDGETS
import 'package:app/screens/modals/business/branch_hours/_branch_hours.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

import './form_section.dart';

/// The hours of the branch an own delivery is seen from, right before its
/// prices: the prices' rows are the days that share them
/// (`DeliveryRatesField`), so a week that does not say how the branch works
/// is set here and not somewhere else first. It opens the branch's hours
/// panel on [hours], the form's own, so the prices follow a save at once.
class DeliveryHoursField extends StatelessWidget {
  const DeliveryHoursField({super.key, required this.hours, this.branch});

  final OpeningHoursService hours;

  /// The name of [hours]' branch.
  final String? branch;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final name = branch;

    return ListenableBuilder(
      listenable: hours,
      builder: (context, _) => FormSection(
        title: name == null || name.isEmpty ? s.branch_hours_title : s.business_delivery_hours(name),
        note: hours.status == OpeningHoursStatus.ready && hours.week.isEmpty
          ? s.business_delivery_hours_empty
          : s.business_delivery_hours_note,
        child: SettingsSelect(
          label: s.business_branch_hours_open,
          icon: CI.calendar,
          open: (_) => showBranchHours(
            context,
            branch: BranchService().byId(hours.branch) ?? BusinessBranchModel(id: hours.branch, name: name ?? ""),
            hours: hours
          )
        )
      )
    );
  }
}
