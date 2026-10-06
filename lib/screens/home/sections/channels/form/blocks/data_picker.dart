import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/channels/channel_agent_role.dart';
import 'package:app/services/channels/channel_data_source.dart';
import 'package:app/services/stock/tables/tables_service.dart';
import 'package:app/services/badges/badge_place.dart';
import 'package:app/screens/home/badges/badge_mark.dart';

// WIDGETS
import 'package:core/form.dart';

import '../widgets/form_block.dart';
import '../widgets/option_card.dart';
import '../widgets/option_grid.dart';
import '../state/channel_form_controller.dart';

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
  Widget build(BuildContext context) => FormBlock(
    title: S.of(context).channel_source_title,
    subtitle: S.of(context).channel_source_subtitle,
    child: ValueListenableBuilder<ChannelAgentRole>(
      valueListenable: controller.role,
      builder: (context, role, _) => ValueListenableBuilder<ChannelDataSource>(
        valueListenable: controller.source,
        builder: (context, selected, _) {
          final options = ChannelDataSource.allowedFor(role);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OptionGrid(children: [
                for (final source in options) OptionCard(
                  icon: source.icon,
                  title: source.title(context),
                  subtitle: source.subtitle(context),
                  selected: source == selected,
                  enabled: source.available,
                  badge: source.available
                    ? null
                    : S.of(context).channel_source_soon,
                  action: () => controller.source.value = source
                )
              ]),
              if (selected.needsTable) _TableSelect(controller: controller)
            ]
          );
        }
      )
    )
  );
}

/// Which product table. [TablesService] brings them, which is the same cache
/// the products section uses, so normally they are already loaded.
///
/// If the business has none it is said, instead of showing an empty dropdown:
/// what needs to be done is create a table, and that is not solved from this
/// form.
class _TableSelect extends StatelessWidget {
  const _TableSelect({required this.controller});

  final ChannelFormController controller;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<TablesService>();

    if (service.status == TablesStatus.loading ||
        service.status == TablesStatus.idle) {
      return Padding(
        padding: EdgeInsets.only(top: AppSize.spaceXS),
        child: const Center(child: Loading())
      );
    }

    if (service.tables.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: AppSize.spaceXS),
        child: Row(children: [
          // The company-wide alert behind it (no catalog yet), on the icon.
          BadgeCorner(
            place: BadgePlace.tableField,
            dot: true,
            outside: true,
            child: Icon(
              CI.info,
              size: AppSize.text * 1.2,
              color: ThemeColor.of(context).icon
            )
          ),
          SizedBox(width: AppSize.spaceS),
          Expanded(child: TextSmall(
            S.of(context).channel_source_no_tables,
            lines: 2,
            ellipsis: true,
            color: ThemeColor.of(context).text.secondary
          ))
        ])
      );
    }

    return SelectInput(
      title: S.of(context).channel_source_table_select,
      placeholder: S.of(context).channel_source_table_placeholder,
      emptyText: S.of(context).channel_source_table_empty,
      controller: controller.table,
      leftIcon: Icon(CI.list, color: ThemeColor.of(context).icon),
      options: [
        for (final table in service.tables)
          SelectOption(
            value: table.id,
            placeholder: table.title,
            // The description helps distinguish two tables with similar names,
            // which is the case where one hesitates.
            subtitle: table.description.isEmpty ? null : table.description,
            icon: CI.list
          )
      ]
    );
  }
}
