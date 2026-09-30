import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/toolkit/lan.dart';
import 'package:app/services/lan/lan_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/pre_start/deployment/widgets/deployment_frame.dart';
import '../widgets/lan_sign_in.dart';
import '../widgets/lan_unlock.dart';
import '../widgets/lan_connected.dart';

class DesktopBody extends StatefulWidget {
  const DesktopBody({super.key});

  @override
  State<DesktopBody> createState() => _DesktopBodyState();
}

/// One page, one [LanService.status] at a time: each state says what's wrong and the one thing
/// to do about it.
class _DesktopBodyState extends State<DesktopBody> {
  @override
  void initState() {
    super.initState();

    final lan = context.read<LanService>();
    if (lan.status == LanStatus.idle) WidgetsBinding.instance.addPostFrameCallback((_) => lan.open());
  }

  @override
  Widget build(BuildContext context) {
    final lan = context.watch<LanService>();
    final s = S.of(context);

    return switch (lan.status) {
      LanStatus.idle || LanStatus.connecting => DeploymentFrame(
        title: s.lan_connecting,
        children: [SizedBox(height: AppSize.action, child: const Center(child: Loading()))]
      ),
      LanStatus.locked => lan.isMaster
        ? const LanUnlock()
        : _message(context, s.lan_locked_title, s.lan_locked_client, retry: true),
      LanStatus.signedOut => const LanSignIn(),
      LanStatus.ready => const LanConnected(),
      LanStatus.unpaired => lan.isMaster
        ? const LanUnlock(enroll: true)
        : _message(context, s.lan_unpaired_title, s.lan_unpaired_subtitle, pair: true),
      LanStatus.unreachable => _message(
        context,
        s.lan_unreachable_title,
        lan.isMaster ? s.lan_unreachable_master : s.lan_unreachable_client,
        retry: true,
        retryTitle: lan.isMaster ? s.lan_start_server : null
      ),
      LanStatus.revoked => _message(context, s.lan_revoked_title, s.lan_revoked_subtitle, pair: true),
      LanStatus.updateRequired => _message(context, s.lan_update_title, s.lan_update_subtitle, retry: true),
      LanStatus.error => _message(context, s.lan_error_title, s.lan_error_code(lan.error ?? "unknown"), retry: true)
    };
  }

  Widget _message(
    BuildContext context,
    String title,
    String subtitle, {
    bool retry = false,
    bool pair = false,
    String? retryTitle
  }) {
    final lan = context.read<LanService>();

    return DeploymentFrame(title: title, subtitle: subtitle, children: [
      if (retry) MainButton(title: retryTitle ?? S.of(context).lan_retry, action: lan.open),
      if (pair) MainButton(
        title: S.of(context).lan_pair_again,
        action: () => lan.leave().then((_) {
          if (context.mounted) Navis.pushAndClearStack(context, "/deployment/pair");
        })
      ),
      // A browser's page is the master's: there is no other way to use Lyra from it.
      if (lanServingMaster == null) ...[
        SizedBox(height: AppSize.spaceXS),
        Button(title: S.of(context).lan_leave, action: () => _leave(context))
      ]
    ]);
  }
}

/// Back to the mode chooser, forgetting this device's pairing. On the master the engine and its
/// data stay: choosing "this computer is the server" again finds them.
Future<void> _leave(BuildContext context) async {
  final confirmed = await showAlertModal(
    context: context,
    title: S.of(context).lan_leave_title,
    message: S.of(context).lan_leave_message,
    confirmText: S.of(context).lan_leave,
    cancelText: S.of(context).cancel
  );
  if (!confirmed || !context.mounted) return;

  await context.read<LanService>().leave();
  if (context.mounted) Navis.pushAndClearStack(context, "/deployment");
}
