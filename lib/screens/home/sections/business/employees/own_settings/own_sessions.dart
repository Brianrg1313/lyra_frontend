import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/client/client_service.dart';

// WIDGETS
import 'package:app/screens/modals/shared/settings/settings_block.dart';

import './own_soon.dart';

/// Where the account is signed in. This device is known and can be signed out of; the backend
/// does not list the other sessions yet.
class OwnSessions extends StatelessWidget {
  const OwnSessions({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return SettingsBlock(
      title: s.account_sessions_title,
      subtitle: s.account_sessions_subtitle,
      child: SettingsList(rows: [
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
      ])
    );
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
