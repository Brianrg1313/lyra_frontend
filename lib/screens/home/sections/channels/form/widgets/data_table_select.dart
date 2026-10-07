import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/badges/badge_place.dart';
import 'package:app/services/stock/tables/tables_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/badges/badge_mark.dart';
import 'package:app/screens/home/sections/channels/form/state/channel_form_controller.dart';

/// Which product table. [TablesService] brings them, which is the same cache
/// the products section uses, so normally they are already loaded.
///
/// If the business has none it is said, instead of showing an empty dropdown:
/// what needs to be done is create a table, and that is not solved from this
/// form.
class DataTableSelect extends StatelessWidget {
  const DataTableSelect({super.key, required this.controller});

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
