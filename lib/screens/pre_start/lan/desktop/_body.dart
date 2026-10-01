import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/toolkit/lan.dart';
import 'package:app/toolkit/settings/initial_builder.dart' show clientService;
import 'package:app/services/lan/lan_service.dart';
import 'package:app/services/preferences/preferences_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/pre_start/deployment/widgets/deployment_frame.dart';
import '../widgets/lan_sign_in.dart';
import '../widgets/lan_unlock.dart';
import '../_lan.dart';

class DesktopBody extends StatefulWidget {
  const DesktopBody({super.key, this.enter});

  /// Loads the session once signed in and answers where to go (`ClientService.resolve`); a
  /// seam for tests.
  final Future<String?> Function()? enter;

  @override
  State<DesktopBody> createState() => _DesktopBodyState();
}

/// One page, one [LanService.status] at a time: each state says what's wrong and the one thing
/// to do about it. Signed in, it loads the session and opens the app (plan §7.4).
class _DesktopBodyState extends State<DesktopBody> {
  bool _entering = false;

  /// The master answered but the session couldn't be loaded (an engine without this release's
  /// ops, a master set up before its company existed). Sending the person back here would only
  /// try again forever, so it stops and says so.
  bool _enterFailed = false;

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
      LanStatus.ready => _enter(),
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

  /// The session is the master's: [ClientService] reads the bootstrap through the LAN source,
  /// then the app opens where it would in the cloud.
  Widget _enter() {
    if (_enterFailed) {
      return _message(context, S.of(context).lan_error_title, S.of(context).lan_enter_failed, onRetry: () => setState(() => _enterFailed = false));
    }

    if (!_entering) {
      _entering = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final page = await (widget.enter ?? clientService.resolve)();
        _entering = false;
        if (!mounted || context.read<LanService>().status != LanStatus.ready) return;
        if (page == LanHome.path) return setState(() => _enterFailed = true);

        Navis.pushAndClearStack(context, page ?? Navis.consumePendingDeepLink() ?? PreferencesService().homePath);
      });
    }

    return DeploymentFrame(
      title: S.of(context).lan_entering,
      children: [SizedBox(height: AppSize.action, child: const Center(child: Loading()))]
    );
  }

  Widget _message(
    BuildContext context,
    String title,
    String subtitle, {
    bool retry = false,
    bool pair = false,
    String? retryTitle,
    VoidCallback? onRetry
  }) {
    final lan = context.read<LanService>();

    return DeploymentFrame(title: title, subtitle: subtitle, children: [
      if (retry || onRetry != null) MainButton(title: retryTitle ?? S.of(context).lan_retry, action: onRetry ?? lan.open),
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

/// Back to the sign in, forgetting this device's pairing. On the master the engine and its
/// data stay: "this computer is the server" there finds them again.
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
  if (context.mounted) Navis.pushAndClearStack(context, "/login");
}
