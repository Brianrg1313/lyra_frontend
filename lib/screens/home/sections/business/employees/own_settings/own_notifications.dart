import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/home/sections/business/employees/own_settings/widgets/own_soon.dart';
import 'package:app/screens/home/sections/business/employees/own_settings/widgets/own_soon_list.dart';

/// What a person will decide about their notices: where they arrive. No backend yet.
class OwnNotifications extends StatelessWidget {
  const OwnNotifications({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return OwnSoonList(caption: false, rows: [
      OwnSoon(icon: CI.notification, label: s.account_notifications_app, hint: s.account_notifications_app_hint),
      OwnSoon(icon: CI.mail, label: s.account_notifications_email, hint: s.account_notifications_email_hint),
      OwnSoon(icon: CI.shop_mobile, label: s.account_notifications_push, hint: s.account_notifications_push_hint)
    ]);
  }
}
