import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/toolkit/deployment.dart';
import 'package:app/services/lan/lan_service.dart';
import 'package:app/services/local_server/local_server_service.dart';

// WIDGETS
import 'package:core/button.dart';

/// The LAN under the cloud sign in (plan §7.4, decision D9): nothing is chosen up front, so a
/// business without a subscription starts here too. "This computer is the server" only where
/// the engine ships (desktop builds with `lyra_node`): web and mobile can never be a master.
///
/// Drawn only where [Deployment.lanEnabled]; a browser on a master's page never reaches the
/// sign in, its page has no cloud.
class AuthLocal extends StatelessWidget {
  const AuthLocal({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final canServe = context.read<LanService>().server.supported;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          TextSmall(S.of(context).auth_local_or, color: scheme.subtitle),
          SizedBox(width: AppSize.spaceS),
          Expanded(child: Separator.horizontal(thickness: 1, color: scheme.surfaceFeedback))
        ]),
        Padding(
          padding: EdgeInsets.only(top: AppSize.gap, bottom: AppSize.spaceS),
          child: TextSmall(S.of(context).auth_local_hint, lines: 4, color: scheme.subtitle)
        ),
        if (canServe) ...[
          Button(
            title: S.of(context).auth_local_master,
            leftIcon: Icon(CI.network, size: AppSize.text, color: scheme.icon),
            action: () => _serve(context)
          ),
          SizedBox(height: AppSize.spaceXS)
        ],
        Button(
          title: S.of(context).auth_local_client,
          leftIcon: Icon(CI.wifi, size: AppSize.text, color: scheme.icon),
          action: () => Navis.push(context, "/deployment/pair")
        )
      ]
    );
  }

  /// A computer that already is a master (it left the LAN, or lost the app's certificate) goes
  /// straight to its server: setting up again would be refused (`already_set_up`).
  static Future<void> _serve(BuildContext context) async {
    final server = context.read<LanService>().server;

    if (await server.refresh() == LocalServerStatus.notSetUp) {
      if (context.mounted) Navis.push(context, "/deployment/master");
      return;
    }

    Deployment.attach(DeploymentRole.master);
    if (context.mounted) Navis.pushAndClearStack(context, "/lan");
  }
}
