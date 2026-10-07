import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/account/account_history_service.dart';
import 'package:app/services/account/account_security_service.dart';
import 'package:app/services/capabilities/capability_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/business/employees/own_settings/widgets/own_index.dart';
import 'package:app/screens/home/sections/business/employees/own_settings/widgets/own_results.dart';

import './own_header.dart';
import './own_section.dart';

/// The person's own settings, from the settings action of their own card: what is theirs and no
/// administrator manages — how they sign in, where they are signed in, this device's language
/// and look, their work history, their notices and their privacy.
///
/// It is an index: whose account it is, a search, and one row per [OwnSection], each opening its
/// own panel over this one. The search looks through every row of every subsection, so a
/// setting is found by its name without knowing where it lives.
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

  final _form = FormController();
  late final _search = InputController.search(form: _form);

  /// What was typed. A notifier, so typing rebuilds the list and not the field.
  final _query = ValueNotifier<String>("");

  @override
  void initState() {
    super.initState();

    final capabilities = CapabilityService();
    if (capabilities.shows("account.security")) _security.load();
    if (capabilities.shows("account.history")) _history.load();

    // Listened to, not `onSearch`: that one waits for typing to stop, meant for a query that
    // travels, and the settings are all here.
    _search.textController.addListener(_write);
  }

  @override
  void dispose() {
    _search.textController.removeListener(_write);
    _form.dispose();
    _query.dispose();
    _security.dispose();
    _history.dispose();
    super.dispose();
  }

  void _write() => _query.value = _search.text.trim();

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: _security),
      ChangeNotifierProvider.value(value: _history)
    ],
    child: ScrollableWidget(
      padding: EdgeInsets.only(bottom: AppSize.padding),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OwnHeader(),
        SearchInput(
          controller: _search,
          placeholder: S.of(context).account_search,
          radius: AppSize.cornerInset(AppSize.gap),
          onSearch: (_) => _write()
        ),
        SizedBox(height: AppSize.spaceS),
        ValueListenableBuilder<String>(
          valueListenable: _query,
          builder: (context, query, _) => query.isEmpty ? const OwnIndex() : OwnResults(query: query)
        )
      ]
    )
  );
}
