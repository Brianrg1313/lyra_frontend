import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/channels/channel_agent_role.dart';

// WIDGETS
import 'package:app/screens/home/sections/channels/form/state/channel_form_controller.dart';
import 'package:app/screens/home/sections/channels/form/widgets/form_row.dart';
import 'package:app/screens/home/sections/channels/form/widgets/option_chip.dart';

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
  Widget build(BuildContext context) => ValueListenableBuilder<ChannelAgentRole>(
    valueListenable: controller.role,
    builder: (context, selected, _) => ChannelFormRow(
      label: S.of(context).channel_role_title,
      note: selected.subtitle(context),
      child: OptionChips(children: [
        for (final role in ChannelAgentRole.values) OptionChip(
          icon: role.icon,
          title: role.title(context),
          selected: role == selected,
          action: () => controller.role.value = role
        )
      ])
    )
  );
}
