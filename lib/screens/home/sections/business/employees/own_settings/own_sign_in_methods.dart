import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/client/client_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/business/employees/own_settings/widgets/own_soon.dart';
import 'package:app/screens/home/sections/business/employees/own_settings/widgets/own_soon_list.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// The ways out of the sign-in methods: the sign-in address, and the accounts that will sign in
/// instead of it (no backend yet: `LoginMethod` reserves them).
class OwnSignInMethods extends StatelessWidget {
  const OwnSignInMethods({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final client = context.watch<ClientService>();

    return SettingsList(rows: [
      SettingsValue(
        icon: CI.mail,
        label: s.account_methods_email,
        value: client.isAuthenticated ? client.client.email : "",
        hint: s.account_methods_email_hint,
        selectable: true
      ),
      OwnSoonList(rows: [
        OwnSoon(
          icon: CI.link,
          label: s.account_methods_linked,
          hint: s.account_methods_linked_hint,
          marks: const [CI.google, CI.apple, CI.microsoft]
        )
      ])
    ]);
  }
}
