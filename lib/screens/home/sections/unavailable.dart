import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/capabilities/capability_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/section_message.dart';

/// What a home section shows when the deployment mode doesn't let it open
/// (see `homeContent`): out of the product in this mode, or a cloud section
/// waiting for the internet in hybrid. There is nothing to ask for either way,
/// unlike `NoPermissionSection`.
class UnavailableSection extends StatelessWidget {
  const UnavailableSection({super.key, required this.capability});

  final Capability capability;

  @override
  Widget build(BuildContext context) {
    final offline = capability == Capability.needsInternet;

    return Surface(
      padding: EdgeInsets.all(AppSize.padding),
      child: SectionMessage(
        icon: offline ? CI.cloud_disconected : CI.cloud_network,
        title: offline
          ? S.of(context).section_needs_internet_title
          : S.of(context).section_unavailable_title,
        subtitle: offline
          ? S.of(context).section_needs_internet_subtitle
          : S.of(context).section_unavailable_subtitle
      )
    );
  }
}
