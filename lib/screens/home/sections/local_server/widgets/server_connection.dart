import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/connection/connection_service.dart';
import 'package:app/services/lan/hybrid_service.dart';
import 'package:app/services/lan/sync_service.dart';
import 'package:app/services/permissions/permissions_service.dart';
import 'package:app/toolkit/backend/deployment.dart';
import 'package:app/toolkit/settings/initial_builder.dart' show businessService;

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
///
/// Online, it says how the sync with the company online stands ([SyncService], which enrols the
/// server by itself): one line, and a button only when the owner has something to decide.
class ServerConnection extends StatefulWidget {
  const ServerConnection({super.key});

  @override
  State<ServerConnection> createState() => _ServerConnectionState();
}

class _ServerConnectionState extends State<ServerConnection> {
  /// The engine syncs every minute on its own; the line follows it while the page is open.
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final sync = context.read<SyncService>();
    unawaited(sync.refresh());
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => unawaited(sync.refresh()));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

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

    final sync = context.watch<SyncService>();
    final syncLine = online && linked ? _syncLine(context, sync) : null;
    final syncAction = online && linked && sync.canEnrol && !sync.working
      ? sync.taken
        ? Button(title: s.server_sync_use_this, width: null, action: () => _replace(context, sync))
        : sync.state?.revoked == true
          ? Button(title: s.server_sync_link_again, width: null, action: () => _enrol(sync))
          : null
      : null;

    final state = Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: EdgeInsets.only(top: AppSize.gap * 0.8), child: StatusDot(on: online)),
      SizedBox(width: AppSize.spaceS),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextMedium(title, bold: true),
        TextSmall(subtitle, lines: 4, color: scheme.subtitle),
        if (syncLine != null) TextSmall(syncLine, lines: 3, color: scheme.subtitle)
      ]))
    ]);
    final actions = Wrap(spacing: AppSize.spaceXS, runSpacing: AppSize.spaceXS, children: [
      if (online && !linked && PermissionsService().owns())
        Button(title: s.server_link_button, width: null, action: () => askLinkCompany(context, force: true)),
      ?syncAction,
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

  /// One line on the sync, or none while there is nothing to say (enrolling for the first time).
  static String? _syncLine(BuildContext context, SyncService sync) {
    final s = S.of(context);
    final state = sync.state;

    if (sync.taken) return s.server_sync_taken;
    if (state == null || !state.enrolled) return null;
    if (state.revoked) return s.server_sync_revoked;
    if (state.lastError != null) return s.server_sync_failing;

    final last = state.lastSync;
    if (last == null) return s.server_sync_starting;

    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final today = last.year == now.year && last.month == now.month && last.day == now.day;
    final time = today ? DateFormat.jm(locale).format(last) : "${DateFormat.MMMd(locale).format(last)} · ${DateFormat.jm(locale).format(last)}";

    return s.server_sync_done(time);
  }

  /// Linking again a server someone unlinked: B-36. When another server took the branch since,
  /// the answer is [SyncService.taken], and the line then offers [_replace].
  static Future<void> _enrol(SyncService sync) => sync.enrol();

  /// The other server stops syncing: asked once, since it was someone's server.
  static Future<void> _replace(BuildContext context, SyncService sync) async {
    final s = S.of(context);
    final confirmed = await showAlertModal(
      context: context,
      title: s.server_sync_replace_title,
      message: s.server_sync_replace_message,
      confirmText: s.server_sync_use_this,
      cancelText: s.cancel
    );
    if (!confirmed) return;

    await sync.enrol(replace: true);
  }

  /// "Work offline" closed the cloud's socket, and the watcher only reopens it when the
  /// internet comes back, which it never left.
  static void _workOnline(HybridService hybrid) {
    hybrid.workOnline();
    unawaited(ConnectionService().open());
  }
}
