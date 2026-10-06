import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/account/account_history_service.dart';
import 'package:app/services/account/account_security_service.dart';
import 'package:app/services/capabilities/capability_service.dart';

// WIDGETS
import './own_header.dart';
import './own_history.dart';
import './own_preferences.dart';
import './own_security.dart';
import './own_sessions.dart';
import './own_soon.dart';

/// The person's own settings, from the settings action of their own card: what is theirs and no
/// administrator manages — how they sign in, where they are signed in, this device's language
/// and look, their work history, their notices and their privacy. Rows without a backend yet
/// are named, drawn quieter and marked "coming soon" once per block.
///
/// It owns its services: they are the account's, read when the panel opens and dropped with it.
class OwnSettings extends StatefulWidget {
  const OwnSettings({super.key});

  @override
  State<OwnSettings> createState() => _OwnSettingsState();
}

class _OwnSettingsState extends State<OwnSettings> {
  final _security = AccountSecurityService();
  final _history = AccountHistoryService();

  @override
  void initState() {
    super.initState();

    final capabilities = CapabilityService();
    if (capabilities.shows("account.security")) _security.load();
    if (capabilities.shows("account.history")) _history.load();
  }

  @override
  void dispose() {
    _security.dispose();
    _history.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: _security),
      ChangeNotifierProvider.value(value: _history)
    ],
    child: ScrollableWidget(
      padding: EdgeInsets.only(bottom: AppSize.padding),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      // What works first, the blocks with nothing working yet last.
      children: const [
        OwnHeader(),
        OwnSecurity(),
        OwnSignInMethods(),
        OwnSessions(),
        OwnPreferences(),
        OwnHistory(),
        OwnNotifications(),
        OwnPrivacy()
      ]
    )
  );
}
