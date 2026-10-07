import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/account/account_security_service.dart';
import 'package:app/services/account/two_factor_model.dart';
import 'package:app/services/client/client_service.dart';

// WIDGETS
import 'package:app/screens/modals/business/two_factor/_two_factor.dart';

import './own_link.dart';

class OwnSignInPosture extends StatelessWidget {
  const OwnSignInPosture({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final service = context.watch<AccountSecurityService>();

    // Said only once known: a guess while it loads would flash the wrong colour.
    if (service.status != AccountSecurityStatus.ready) return const SizedBox.shrink();

    final method = service.twoFactor.method;
    final color = method == null ? scheme.chart.warning : scheme.chart.good;
    final text = switch (method) {
      TwoFactorMethod.app => s.account_posture_app,
      TwoFactorMethod.email => s.account_posture_email,
      null => s.account_posture_off
    };

    return Padding(
      padding: EdgeInsets.only(top: AppSize.spaceS),
      child: Container(
        padding: EdgeInsets.all(AppSize.spaceXS),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSize.cornerInset(AppSize.gap))
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(method == null ? CI.safe_password : CI.check, size: AppSize.text * 1.2, color: color),
            SizedBox(width: AppSize.spaceXS),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextSmall(text, lines: 3),
                if (method == null) ...[
                  SizedBox(height: AppSize.gap),
                  OwnLink(
                    label: s.account_posture_turn_on,
                    action: () {
                      final client = context.read<ClientService>();
                      showTwoFactorSetup(context, service: service, email: client.isAuthenticated ? client.client.email : "");
                    }
                  )
                ]
              ]
            ))
          ]
        )
      )
    );
  }
}
