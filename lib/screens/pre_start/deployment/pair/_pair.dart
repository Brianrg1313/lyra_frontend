import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/toolkit/lan.dart';
import 'package:app/services/lan/lan_pairing_service.dart';

// WIDGETS
import 'desktop/_body.dart';

/// Pairs this device with a master by its 8-digit code or, on a phone, its QR (plan §5.3). Provides
/// [LanPairingService], which only lives while this page does.
class PairDevice extends PageBuilder {
  const PairDevice({super.key});

  static const routeKey = "deployment_pair";
  static const path = "/deployment/pair";

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    // A browser pairs with the master that served it: nothing to look for.
    create: (_) {
      final pairing = LanPairingService();
      if (lanServingMaster == null) pairing.search();
      return pairing;
    },
    child: const DesktopBody()
  );
}
