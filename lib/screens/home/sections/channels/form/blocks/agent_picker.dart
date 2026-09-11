import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/channels/channel_agent_role.dart';

import '../widgets/form_block.dart';
import '../widgets/option_card.dart';
import '../widgets/option_grid.dart';
import '../state/channel_form_controller.dart';

/// What the agent answering the channel does: sell, give support or handle
/// things in general.
///
/// It is a single choice and it changes how the model behaves end to end —the
/// tone, where it takes the conversation, what it does when it does not know
/// something—, not what data it sees: that is decided by the data block.
///
/// It only listens to `role`: choosing a role repaints neither the
/// credentials nor the rest of the form.
class AgentPicker extends StatelessWidget {
  const AgentPicker({super.key, required this.controller});

  final ChannelFormController controller;

  @override
  Widget build(BuildContext context) => FormBlock(
    title: S.of(context).channel_role_title,
    subtitle: S.of(context).channel_role_subtitle,
    child: ValueListenableBuilder<ChannelAgentRole>(
      valueListenable: controller.role,
      builder: (context, selected, _) => OptionGrid(children: [
        for (final role in ChannelAgentRole.values) OptionCard(
          icon: role.icon,
          title: role.title(context),
          subtitle: role.subtitle(context),
          selected: role == selected,
          action: () => controller.role.value = role
        )
      ])
    )
  );
}
