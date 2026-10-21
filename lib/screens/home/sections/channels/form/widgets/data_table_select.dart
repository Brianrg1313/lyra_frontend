import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/badges/badge_place.dart';
import 'package:app/services/stock/tables/tables_service.dart';

// WIDGETS
import 'package:app/screens/home/badges/badge_mark.dart';
import 'package:app/screens/home/sections/channels/form/state/channel_form_controller.dart';
import 'package:app/screens/home/sections/channels/form/widgets/option_chip.dart';

/// Which product tables. [TablesService] brings them, which is the same cache
/// the products section uses, so normally they are already loaded.
///
/// **Several can be chosen**: a catalog and the combos made of it are two
/// tables one channel sells from. A supplies table is not offered — it is
/// never sold, so no channel reads it (`cocina-frontend.md` §1).
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

    final sold = [
      for (final table in service.tables)
        if (!table.supplies) table
    ];

    if (sold.isEmpty) {
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

    return ValueListenableBuilder<Set<String>>(
      valueListenable: controller.tables,
      builder: (context, selected, _) => OptionChips(children: [
        for (final table in sold) OptionChip(
          icon: CI.list,
          title: table.title,
          selected: selected.contains(table.id),
          multiple: true,
          action: () => controller.toggleTable(table.id)
        )
      ])
    );
  }
}
