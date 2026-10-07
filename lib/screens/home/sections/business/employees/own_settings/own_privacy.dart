import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/home/sections/business/employees/own_settings/widgets/own_soon.dart';
import 'package:app/screens/home/sections/business/employees/own_settings/widgets/own_soon_list.dart';

/// What of the person's own optional data their company sees. No backend yet: today the
/// employees' `view_personal` permission decides it alone.
class OwnPrivacy extends StatelessWidget {
  const OwnPrivacy({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return OwnSoonList(caption: false, rows: [
      OwnSoon(icon: CI.eye_hidden, label: s.account_privacy_details, hint: s.account_privacy_details_hint),
      OwnSoon(icon: CI.employee_badge, label: s.account_privacy_presence, hint: s.account_privacy_presence_hint)
    ]);
  }
}
