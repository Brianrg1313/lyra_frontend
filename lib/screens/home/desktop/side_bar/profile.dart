import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/client/client_service.dart';

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

    final picture = client.picture;

    return Padding(
    padding: EdgeInsets.all(AppSize.spaceXS),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: AppSize.action,
          height: AppSize.action,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSize.action),
            border: Border(
              top: BorderSide(color: Colors.white.withAlpha(40)),
              left: BorderSide(color: Colors.white.withAlpha(40))
            ),
            // The gradient stays in the background: it shows while the image
            // loads and also when the client has no picture.
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withAlpha(50),
                Colors.white.withAlpha(0)
              ]),
            image: picture != null && picture.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(picture),
                  fit: BoxFit.cover)
              : null
          )
        ),
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
