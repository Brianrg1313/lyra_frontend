import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/toolkit/deployment.dart';
import 'package:app/toolkit/lan.dart' show lanServingMaster;
import 'package:app/services/lan/lan_service.dart';
import 'package:app/services/lan/network_scan_service.dart';
import 'package:app/services/sign_in/sign_in_service.dart';

// WIDGETS
import 'package:app/screens/pre_start/deployment/master/desktop/_body.dart' as master;
import 'desktop/_body.dart';
import 'auth_lan.dart';
import 'auth_master.dart';
import 'auth_offline.dart';

/// Single entry for signing in and signing up: the person only types the
/// email, and `email/verify` decides which of the two flows follows.
///
/// What is drawn depends on the network ([NetworkScanService], plan §7.4), never on a choice:
/// the backend answers → the cloud's form, as always, paired with a master or not (the session
/// it opens is the cloud's, [Deployment.online]); it doesn't and this device is paired with a
/// master (or is one) → that master's sign in, [AuthMaster], in the same frame and steps
/// ([Deployment.offline]); it doesn't but a master is on the LAN → [AuthLan] signs in to it;
/// neither → [AuthLan] creates the master on this computer, or [AuthOffline] where none can run
/// (web, phones). A browser on a master's page has only that master: the cloud is another origin.
class Authentication extends PageBuilder {
  const Authentication({super.key, this.scan});

  /// Makes the scan. Injected by the tests.
  final NetworkScanService Function()? scan;

  @override
  Widget build(BuildContext context) => lanServingMaster != null ? const _MasterGate() : MultiProvider(
    providers: [
      Provider(create: (_) => SignInService()),
      ChangeNotifierProvider(create: (_) => (scan ?? NetworkScanService.new)()..watch())
    ],
    child: const _Gate()
  );
}

class _Gate extends StatefulWidget {
  const _Gate();

  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  /// Set by "create the server": the setup takes the page, and no look of the
  /// network may take it back until the person returns from it.
  ({String email, String password})? _owner;

  void _create(String email, String password) {
    context.read<NetworkScanService>().hold(true);
    setState(() => _owner = (email: email, password: password));
  }

  void _back() {
    context.read<NetworkScanService>().hold(false);
    setState(() => _owner = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_owner != null) return master.DesktopBody(owner: _owner, onBack: _back);

    final scan = context.watch<NetworkScanService>();

    // The sources follow the form on screen: the cloud's identify the e-mail through the backend,
    // a master's through `LanService`. Nothing reads them before a submit.
    if (scan.reach == NetworkReach.online) Deployment.online();
    if (scan.reach != NetworkReach.online && scan.reach != NetworkReach.searching && Deployment.paired != null) {
      Deployment.offline();
      return const _MasterGate();
    }

    return switch (scan.reach) {
      NetworkReach.searching => const Center(child: Loading()),
      NetworkReach.online => const DesktopBody(),
      NetworkReach.master => AuthLan(masters: scan.masters, onCreate: _create),
      NetworkReach.none when scan.canHost => AuthLan(masters: const [], onCreate: _create),
      NetworkReach.none => AuthOffline(onRetry: scan.scan)
    };
  }
}

/// The sign in of a paired device without the backend, while its master can take one
/// ([LanStatus.signedOut]); any other state of the connection (connecting aside) is `/lan`'s to
/// show and act on, and so is entering once signed in.
class _MasterGate extends StatefulWidget {
  const _MasterGate();

  @override
  State<_MasterGate> createState() => _MasterGateState();
}

class _MasterGateState extends State<_MasterGate> {
  bool _leaving = false;

  @override
  void initState() {
    super.initState();

    final lan = context.read<LanService>();
    if (lan.status == LanStatus.idle) WidgetsBinding.instance.addPostFrameCallback((_) => lan.open());
  }

  @override
  Widget build(BuildContext context) {
    final status = context.watch<LanService>().status;

    switch (status) {
      case LanStatus.signedOut: return const AuthMaster();
      case LanStatus.idle || LanStatus.connecting: break;
      default:
        if (!_leaving) {
          _leaving = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navis.pushAndClearStack(context, "/lan");
          });
        }
    }

    return const Center(child: Loading());
  }
}
