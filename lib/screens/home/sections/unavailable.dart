import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/capabilities/capability_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/section_message.dart';

/// What a home section or tab shows when the deployment mode doesn't let it open
/// (see `homeContent`): out of the product in this mode, locked until the
/// internet answers, or until the server is joined to its company online. There is nothing to ask for either way, unlike
/// `NoPermissionSection`.
class UnavailableSection extends StatelessWidget {
  const UnavailableSection({super.key, required this.capability, this.surface = true});

  final Capability capability;

  /// A tab's body goes inside its page's surface: false draws the bare message.
  final bool surface;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    final message = switch (capability) {
      Capability.needsInternet => SectionMessage(
        icon: CI.cloud_disconected,
        title: s.section_needs_internet_title,
        subtitle: s.section_needs_internet_subtitle
      ),
      Capability.needsLink => SectionMessage(
        icon: CI.cloud_network,
        title: s.section_needs_link_title,
        subtitle: s.section_needs_link_subtitle
      ),
      _ => SectionMessage(
        icon: CI.cloud_network,
        title: s.section_unavailable_title,
        subtitle: s.section_unavailable_subtitle
      )
    };

    if (!surface) return message;

    return Surface(padding: EdgeInsets.all(AppSize.padding), child: message);
  }
}
