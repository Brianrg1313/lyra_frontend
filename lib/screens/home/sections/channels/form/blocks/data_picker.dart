import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/channels/channel_agent_role.dart';
import 'package:app/services/channels/channel_data_source.dart';

// WIDGETS
import 'package:app/screens/home/sections/channels/form/state/channel_form_controller.dart';
import 'package:app/screens/home/sections/channels/form/widgets/form_row.dart';
import 'package:app/screens/home/sections/channels/form/widgets/option_chip.dart';
import 'package:app/screens/home/sections/channels/form/widgets/data_table_select.dart';

/// Where the model gets what it knows from: a product table, a services
/// calendar or a knowledge base.
///
/// It is the block that ties the channel to real business data. A channel
/// without a source answers from memory, which is the same as saying it makes
/// up prices.
///
/// **Which of the three are even offered depends on the agent's role**
/// ([ChannelDataSource.allowedFor]): a seller reads product data (the table
/// today, the calendar once it exists), while support and general agents are
/// not there to sell and only get the knowledge base. Choosing a role that no
/// longer allows the picked source corrects it on its own — see
/// [ChannelFormController.role].
///
/// Of the three, today **only the product table exists**. The other two are
/// shown disabled and with their caption on purpose: the calendar will be for
/// booking appointments and the knowledge base for the model to answer
/// questions or run marketing, and whoever is connecting a channel needs to
/// know that is coming so they do not rebuild it later.
///
/// Once the product table is chosen, **which one** has to be said: the
/// business has several and the channel reads from one. The id is stored, not
/// the name, so renaming the table does not disconnect the channel.
class DataPicker extends StatelessWidget {
  const DataPicker({super.key, required this.controller});

  final ChannelFormController controller;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ChannelAgentRole>(
    valueListenable: controller.role,
    builder: (context, role, _) => ValueListenableBuilder<ChannelDataSource>(
      valueListenable: controller.source,
      builder: (context, selected, _) => ChannelFormRow(
        label: S.of(context).channel_source_title,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OptionChips(children: [
              for (final source in ChannelDataSource.allowedFor(role)) OptionChip(
                icon: source.icon,
                title: source.title(context),
                selected: source == selected,
                enabled: source.available,
                badge: source.available ? null : S.of(context).channel_source_soon,
                action: () => controller.source.value = source
              )
            ]),
            // What the chosen source answers, before saying which table.
            ChannelFormNote(selected.subtitle(context)),
            if (selected.needsTable) Padding(
              padding: EdgeInsets.only(top: AppSize.spaceXS),
              child: DataTableSelect(controller: controller)
            )
          ]
        )
      )
    )
  );
}
