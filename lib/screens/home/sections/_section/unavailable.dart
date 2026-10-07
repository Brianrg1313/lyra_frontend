import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/toolkit/settings/initial_builder.dart' show hybridService;
import 'package:app/services/capabilities/capability_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/section_message.dart';
import 'package:app/screens/modals/server/online_sign_in/_online_sign_in.dart';

/// What a home section or tab shows when the deployment mode doesn't let it open
/// (see `homeContent`): out of the product in this mode, locked until the
/// internet answers, or until the server is joined to its company online. There is nothing to ask for either way, unlike
/// `NoPermissionSection`. A session on the master alone opens only with an online sign in, which
/// is offered here once the backend answers (`HybridService.canGoOnline`).
class UnavailableSection extends StatelessWidget {
  const UnavailableSection({super.key, required this.capability, this.surface = true});

  final Capability capability;

  /// A tab's body goes inside its page's surface: false draws the bare message.
  final bool surface;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    final message = switch (capability) {
      Capability.needsInternet => ListenableBuilder(
        listenable: hybridService,
        builder: (context, _) => SectionMessage(
          icon: CI.cloud_disconected,
          title: s.section_needs_internet_title,
          subtitle: hybridService.canGoOnline
            ? s.section_needs_sign_in_subtitle
            : hybridService.masterOnly ? s.section_needs_internet_master_subtitle : s.section_needs_internet_subtitle,
          actionLabel: s.server_sign_in_online,
          action: hybridService.canGoOnline ? () => showOnlineSignIn(context) : null
        )
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
