import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/client/client_service.dart';

import 'connection_dot.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    required this.isExpanded,
    super.key,
  });

  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final client = context.watch<ClientService>();

    // Signing out empties the client once home is left, but a route leaving
    // with a transition can still be painted then.
    if (!client.isAuthenticated) return const SizedBox.shrink();

    return Padding(
    padding: EdgeInsets.all(AppSize.spaceXS),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The connection's state hangs off the picture's bottom-right corner.
        Stack(clipBehavior: Clip.none, children: [ProfilePicture(
          kind: ProfileKind.user,
          url: client.picture,
          size: AppSize.action,
          label: client.fullName
        ),
        Positioned(right: -AppSize.gap / 2, bottom: -AppSize.gap / 2, child: const ConnectionDot())]),
        // The spacing goes inside the Expanded so it can shrink to 0 while
        // the side bar animates its width; as a fixed SizedBox it would cause
        // overflow during the first frames of the expansion.
        if (isExpanded) Expanded(child: Padding(
          padding: EdgeInsets.only(left: AppSize.spaceXS),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextLarge(client.fullName, ellipsis: true, multiplier: 1.5),
              TextSmall(client.email, ellipsis: true)
            ])))
      ])
    );
  }
}
