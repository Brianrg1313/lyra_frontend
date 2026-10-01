import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/lan/network_scan_service.dart';
import 'package:app/services/sign_in/sign_in_service.dart';

// WIDGETS
import 'package:app/screens/pre_start/deployment/master/desktop/_body.dart' as master;
import 'desktop/_body.dart';
import 'auth_lan.dart';
import 'auth_offline.dart';

/// Single entry for signing in and signing up: the person only types the
/// email, and `email/verify` decides which of the two flows follows.
///
/// What is drawn depends on the network ([NetworkScanService], plan §7.4):
/// the backend answers → the cloud's form, as always; it doesn't but a master
/// is on the LAN → [AuthLan] signs in to it; neither → [AuthLan] creates the
/// master on this computer, or [AuthOffline] where none can run (web, phones).
class Authentication extends PageBuilder {
  const Authentication({super.key, this.scan});

  /// Makes the scan. Injected by the tests.
  final NetworkScanService Function()? scan;

  @override
  Widget build(BuildContext context) => MultiProvider(
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

    return switch (scan.reach) {
      NetworkReach.searching => const Center(child: Loading()),
      NetworkReach.online => const DesktopBody(),
      NetworkReach.master => AuthLan(masters: scan.masters, onCreate: _create),
      NetworkReach.none when scan.canHost => AuthLan(masters: const [], onCreate: _create),
      NetworkReach.none => AuthOffline(onRetry: scan.scan)
    };
  }
}
