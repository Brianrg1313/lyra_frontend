import 'package:flutter/material.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/lan/hybrid_service.dart';
import 'package:app/services/lan/lan_service.dart';
import 'package:app/toolkit/deployment.dart';

// WIDGETS
import 'package:app/screens/home/sections/local_server/widgets/server_away.dart';

import './server_ready.dart';

/// The `local_server` home section, wherever a master can be (plan §4 admin screens, D16). With
/// the server's session ([ServerReady]); online without it, [ServerAway]: the server that
/// doesn't answer, or creating one on this computer.
class LocalServerSection extends StatelessWidget {
  const LocalServerSection({super.key});

  @override
  Widget build(BuildContext context) {
    final ready = context.select<LanService, bool>((lan) => lan.status == LanStatus.ready);
    context.watch<HybridService>();

    return ready && Deployment.mode != DeploymentMode.cloud ? const ServerReady() : const ServerAway();
  }
}
