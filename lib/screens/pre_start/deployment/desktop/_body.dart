import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/toolkit/deployment.dart';
import 'package:app/services/lan/lan_service.dart';
import 'package:app/services/local_server/local_server_service.dart';

// WIDGETS
import 'package:app/screens/pre_start/welcome/widgets/welcome_choice.dart';
import '../widgets/deployment_frame.dart';

/// A computer that already is a master (it left LAN mode, or lost the app's certificate)
/// goes straight to its server: setting up again would be refused (`already_set_up`).
Future<void> _serve(BuildContext context) async {
  final server = context.read<LanService>().server;

  if (await server.refresh() == LocalServerStatus.notSetUp) {
    if (context.mounted) Navis.push(context, "/deployment/master");
    return;
  }

  Deployment.choose(DeploymentMode.local, role: DeploymentRole.master);
  if (context.mounted) Navis.pushAndClearStack(context, "/lan");
}

/// The three ways to use Lyra. "This computer is the server" only where the engine ships
/// (desktop builds with `lyra_node`): web and mobile can never be a master (plan §3).
class DesktopBody extends StatelessWidget {
  const DesktopBody({super.key});

  @override
  Widget build(BuildContext context) {
    final canServe = context.read<LanService>().server.supported;

    return DeploymentFrame(
      title: S.of(context).lan_choose_title,
      subtitle: S.of(context).lan_choose_subtitle,
      children: [
        WelcomeChoice(
          icon: CI.cloud_connected,
          title: S.of(context).lan_choose_cloud,
          subtitle: S.of(context).lan_choose_cloud_subtitle,
          action: () {
            Deployment.choose(DeploymentMode.cloud);
            Navis.pushAndClearStack(context, "/login");
          }
        ),
        if (canServe) ...[
          SizedBox(height: AppSize.spaceS),
          WelcomeChoice(
            icon: CI.network,
            title: S.of(context).lan_choose_master,
            subtitle: S.of(context).lan_choose_master_subtitle,
            action: () => _serve(context)
          )
        ],
        SizedBox(height: AppSize.spaceS),
        WelcomeChoice(
          icon: CI.wifi,
          title: S.of(context).lan_choose_client,
          subtitle: S.of(context).lan_choose_client_subtitle,
          action: () => Navis.push(context, "/deployment/pair")
        )
      ]
    );
  }
}
