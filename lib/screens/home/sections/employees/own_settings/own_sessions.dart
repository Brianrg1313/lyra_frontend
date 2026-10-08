import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/client/client_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/employees/own_settings/widgets/own_link.dart';
import 'package:app/screens/home/sections/employees/own_settings/widgets/own_soon.dart';
import 'package:app/screens/home/sections/employees/own_settings/widgets/own_soon_list.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// Where the account is signed in. This device is known and can be signed out of; the backend
/// does not list the other sessions yet.
class OwnSessions extends StatelessWidget {
  const OwnSessions({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return SettingsList(rows: [
      SettingsRow(
        icon: kIsWeb ? CI.globe_shopping : CI.shop_mobile,
        label: s.account_sessions_this,
        hint: s.account_sessions_this_hint,
        child: Row(children: [
          Expanded(child: TextMedium(_platform(context), ellipsis: true)),
          OwnLink(
            label: s.sign_out,
            danger: true,
            action: () => context.read<ClientService>().signOut(context)
          )
        ])
      ),
      OwnSoonList(rows: [
        OwnSoon(icon: CI.network, label: s.account_sessions_others, hint: s.account_sessions_others_hint)
      ])
    ]);
  }

  static String _platform(BuildContext context) {
    final s = S.of(context);
    if (kIsWeb) return s.account_sessions_platform_web;

    return switch (defaultTargetPlatform) {
      TargetPlatform.windows => s.account_sessions_platform_windows,
      TargetPlatform.macOS => s.account_sessions_platform_macos,
      TargetPlatform.linux => s.account_sessions_platform_linux,
      TargetPlatform.iOS => s.account_sessions_platform_ios,
      _ => s.account_sessions_platform_android
    };
  }
}
