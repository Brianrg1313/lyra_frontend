import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/toolkit/deployment.dart';
import 'package:app/toolkit/settings/initial_builder.dart' show businessService;
import 'package:app/services/connection/connection_service.dart';
import 'package:app/services/lan/hybrid_service.dart';
import 'package:app/services/permissions/permissions_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/modals/server/link_company/_link_company.dart';
import 'package:app/screens/modals/server/online_sign_in/_online_sign_in.dart';
import './status_dot.dart';

/// How this device works with its server, for a session opened online (plan §9.6): online
/// (`hybrid`) with "work offline", or offline by choice with "work online", the session kept
/// either way. While the company isn't joined with its company online, its owner can join it
/// from here. A session opened on the master alone has no online side until the backend answers
/// ([HybridService.canGoOnline]): then it offers to sign in online ([showOnlineSignIn]).
class ServerConnection extends StatelessWidget {
  const ServerConnection({super.key});

  @override
  Widget build(BuildContext context) {
    // It notifies on a link too, so the company is read from the app-wide instance.
    final hybrid = context.watch<HybridService>();
    if (!hybrid.joined && !hybrid.canGoOnline) return const SizedBox.shrink();

    final linked = businessService.activeId == null || businessService.active.cloudId != null;

    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final online = Deployment.mode == DeploymentMode.hybrid;
    final (title, subtitle) = !hybrid.joined
      ? (s.server_back_title, s.server_back_subtitle)
      : online
        ? (s.server_online_title, s.server_online_subtitle)
        : (s.server_offline_title, s.server_offline_subtitle);

    final state = Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: EdgeInsets.only(top: AppSize.gap * 0.8), child: StatusDot(on: online)),
      SizedBox(width: AppSize.spaceS),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextMedium(title, bold: true),
        TextSmall(subtitle, lines: 4, color: scheme.subtitle)
      ]))
    ]);
    final actions = Wrap(spacing: AppSize.spaceXS, runSpacing: AppSize.spaceXS, children: [
      if (online && !linked && PermissionsService().owns())
        Button(title: s.server_link_button, width: null, action: () => askLinkCompany(context, force: true)),
      if (!hybrid.joined)
        Button(title: s.server_sign_in_online, width: null, action: () => showOnlineSignIn(context))
      else
        Button(
          title: online ? s.server_work_offline : s.server_work_online,
          width: null,
          action: online ? hybrid.workOffline : () => _workOnline(hybrid)
        )
    ]);

    // A strip, not a card: it states how the whole page works right now and is switched from
    // here, so it spans the width and stays low.
    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.spaceM),
      child: Surface.line(
        borderColor: scheme.line,
        padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS, vertical: AppSize.spaceXS),
        child: LayoutBuilder(builder: (context, box) => box.maxWidth >= 640
          ? Row(children: [Expanded(child: state), SizedBox(width: AppSize.spaceS), actions])
          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              state,
              SizedBox(height: AppSize.spaceXS),
              Padding(padding: EdgeInsets.only(left: AppSize.spaceS + 8), child: actions)
            ])
        )
      )
    );
  }

  /// "Work offline" closed the cloud's socket, and the watcher only reopens it when the
  /// internet comes back, which it never left.
  static void _workOnline(HybridService hybrid) {
    hybrid.workOnline();
    unawaited(ConnectionService().open());
  }
}
