import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/account/account_history_service.dart';
import 'package:app/services/capabilities/capability_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/employees/own_settings/widgets/own_history_job.dart';
import 'package:app/screens/home/sections/employees/own_settings/widgets/own_link.dart';
import 'package:app/screens/home/sections/employees/own_settings/widgets/own_offline.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// Every company the person worked for, the current ones first, over [AccountHistoryService]
/// (provided by `OwnSettings`). Theirs, kept after each job; read from the cloud.
class OwnHistory extends StatelessWidget {
  const OwnHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);

    if (!CapabilityService().shows("account.history")) {
      return OwnOffline(icon: CI.shop, label: s.account_history_title);
    }

    final service = context.watch<AccountHistoryService>();

    return switch (service.status) {
      AccountHistoryStatus.ready => SettingsList(rows: [
        for (final job in service.jobs) OwnHistoryJob(job: job)
      ]),
      AccountHistoryStatus.empty => TextSmall(s.account_history_empty, color: scheme.text.secondary),
      AccountHistoryStatus.error => Row(children: [
        Expanded(child: TextSmall(s.account_history_error, lines: 2, color: scheme.text.secondary)),
        OwnLink(label: s.account_retry, action: service.load)
      ]),
      _ => Center(child: SizedBox.square(dimension: AppSize.text * 1.4, child: Loading(color: scheme.primary)))
    };
  }
}
