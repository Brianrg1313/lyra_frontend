import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/services/client/client_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/business/employees/own_settings/widgets/own_sign_in_posture.dart';

/// Whose account this is, and how its sign in is guarded, said in one sentence. It is the one
/// thing the panel opens on: an account with a single step is told so, with the way to add the
/// second right there instead of three blocks down.
class OwnHeader extends StatelessWidget {
  const OwnHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final client = context.watch<ClientService>();
    final signedIn = client.isAuthenticated;

    return Padding(
      padding: EdgeInsets.only(top: AppSize.spaceXS, bottom: AppSize.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            ProfilePicture(
              kind: ProfileKind.user,
              url: signedIn ? client.client.picture : null,
              size: AppSize.action * 1.3,
              label: signedIn ? client.client.fullName : null
            ),
            SizedBox(width: AppSize.spaceS),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextInter(signedIn ? client.client.fullName : "", multiplier: 1.5, bold: true, ellipsis: true),
                TextSmall(signedIn ? client.client.email : "", ellipsis: true, selectable: true, color: scheme.text.secondary)
              ]
            ))
          ]),
          // The security service is provided and read only where the cloud is.
          if (CapabilityService().shows("account.security")) const OwnSignInPosture()
        ]
      )
    );
  }
}
