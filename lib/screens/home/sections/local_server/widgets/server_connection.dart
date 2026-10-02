import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/toolkit/deployment.dart';
import 'package:app/toolkit/settings/initial_builder.dart' show businessService;
import 'package:app/services/lan/hybrid_service.dart';
import 'package:app/services/permissions/permissions_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/modals/server/link_company/_link_company.dart';

/// How this device works with its server, for a session opened online (plan §9.6): online
/// (`hybrid`) with "work offline", or offline by choice with "work online", the session kept
/// either way. While the company isn't joined with its company online, its owner can join it
/// from here. Nothing for a session opened on the master alone: it has no online side.
class ServerConnection extends StatelessWidget {
  const ServerConnection({super.key});

  @override
  Widget build(BuildContext context) {
    // It notifies on a link too, so the company is read from the app-wide instance.
    final hybrid = context.watch<HybridService>();
    if (!hybrid.joined) return const SizedBox.shrink();

    final linked = businessService.activeId == null || businessService.active.cloudId != null;

    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final online = Deployment.mode == DeploymentMode.hybrid;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.spaceM),
      child: Surface(
        color: scheme.surface,
        padding: EdgeInsets.all(AppSize.spaceS),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextMedium(online ? s.server_online_title : s.server_offline_title, bold: true),
          SizedBox(height: AppSize.gap),
          TextSmall(online ? s.server_online_subtitle : s.server_offline_subtitle, lines: 4, color: scheme.subtitle),
          SizedBox(height: AppSize.spaceS),
          Wrap(spacing: AppSize.spaceXS, runSpacing: AppSize.spaceXS, children: [
            Button(
              title: online ? s.server_work_offline : s.server_work_online,
              width: null,
              action: online ? hybrid.workOffline : hybrid.workOnline
            ),
            if (online && !linked && PermissionsService().owns())
              Button(title: s.server_link_button, width: null, action: () => askLinkCompany(context, force: true))
          ])
        ])
      )
    );
  }
}
