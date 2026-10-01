import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/capabilities/capability_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/section_message.dart';

/// What a home section or tab shows when the deployment mode doesn't let it open
/// (see `homeContent`): out of the product in this mode, or locked until the
/// internet answers. There is nothing to ask for either way, unlike
/// `NoPermissionSection`.
class UnavailableSection extends StatelessWidget {
  const UnavailableSection({super.key, required this.capability, this.surface = true});

  final Capability capability;

  /// A tab's body goes inside its page's surface: false draws the bare message.
  final bool surface;

  @override
  Widget build(BuildContext context) {
    final offline = capability == Capability.needsInternet;

    final message = SectionMessage(
        icon: offline ? CI.cloud_disconected : CI.cloud_network,
        title: offline
          ? S.of(context).section_needs_internet_title
          : S.of(context).section_unavailable_title,
        subtitle: offline
          ? S.of(context).section_needs_internet_subtitle
          : S.of(context).section_unavailable_subtitle
    );

    if (!surface) return message;

    return Surface(padding: EdgeInsets.all(AppSize.padding), child: message);
  }
}
