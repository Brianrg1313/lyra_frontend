import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';
import 'package:app/services/capabilities/capability_service.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/stock/tables/tables_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/inventory/table_list/inventory_bar.dart';

import 'header_actions.dart';
import 'normalize_button.dart';

/// The section's bar over the sheet: the table selector and its controls (the
/// section's), then what this sheet is doing —an import still landing, a read, a
/// search count ([HeaderActions])— and the normalize action.
///
/// From the listing it takes **an already resolved value** and not the list: whether
/// this table is still being imported. The listing is re-read often, and with the
/// object this bar would be repainted by changes that are not its own.
class TableHeader extends StatelessWidget {
  const TableHeader({
    super.key,
    required this.tableId,
    required this.parts,
    this.status = const []
  });

  final String tableId;
  final InventoryBarParts parts;
  final List<Widget> status;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    // Whether this table is still being imported. It is what explains what is
    // seen: a thousand-row sheet opened ten seconds after importing it is not
    // empty, it is halfway up.
    final stage = context.select<TablesService, TableImportStage?>(
      (tables) => tables.importStage(tableId)
    );

    return InventoryBar(
      parts: parts,
      status: [
        ...status,
        if (stage != null) Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: AppSize.text * 0.8,
              height: AppSize.text * 0.8,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.text.secondary
              )
            ),
            SizedBox(width: AppSize.gap),
            Flexible(child: TextSmall(
              _stage(context, stage),
              color: scheme.text.secondary,
              ellipsis: true
            ))
          ]
        ),
        const HeaderActions()
      ],
      actions: [
        // Normalize the table: give each column the type that matches what it
        // holds and seed how much of it the agent sees. See [NormalizeButton].
        // Re-typing comes with importing: where that isn't offered, neither is this.
        if (CapabilityService().shows("inventory.import")) const NormalizeButton()
      ]
    );
  }

  /// What the table is missing, while it is being imported.
  ///
  /// It carries its own spinner and does not rely on the [HeaderActions] one:
  /// that one announces this screen's reads, and during the first stage —the
  /// backend typing the columns— nothing travels from here, so it would be
  /// still just when it is most needed to say the table is not finished.
  static String _stage(BuildContext context, TableImportStage stage) =>
    switch (stage) {
      TableImportStage.preparing => S.of(context).import_table_preparing,
      TableImportStage.loading => S.of(context).import_table_loading
    };
}
