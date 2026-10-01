import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';
import 'package:app/services/capabilities/capability_service.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/stock/tables/table_lite_model.dart';
import 'package:app/services/stock/tables/tables_service.dart';
import 'package:app/services/stock/tables/table_view_service.dart';

// WIDGETS
import 'package:app/screens/modals/inventory/table_settings/_table_settings.dart';

import 'header_actions.dart';
import 'normalize_button.dart';
import 'state/sheet_controller.dart';

/// Top bar: the back-to-listing button, the table's color, its name, and, on
/// the right, the state of the reading and saving of the pending rows.
///
/// The name comes from the structure, which is the one that brings the real
/// one; until it arrives, the one the table listing already had cached is
/// shown and, if it is not there either (entered through a deep link with the
/// listing unloaded), a generic one.
///
/// Of the two services it looks at, from each one it takes **already resolved
/// texts** and not the objects: from the listing, the cached title; from the
/// open table, the name, the description, and the color. Both things are
/// re-read often —the listing on its own, the structure every time a column
/// changes— and with the objects this bar would be repainted by changes that
/// are not its own.
class TableHeader extends StatelessWidget {
  const TableHeader({super.key, required this.tableId});

  final String tableId;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final controller = context.read<SheetController>();

    final cached = context.select<TablesService, String>(
      (tables) => _cachedTitle(tables.tables, tableId)
    );

    // From the listing also comes whether this table is still being imported. It
    // is what explains what is seen: a thousand-row sheet opened ten seconds
    // after importing it is not empty, it is halfway up.
    final stage = context.select<TablesService, TableImportStage?>(
      (tables) => tables.importStage(tableId)
    );

    // From the structure it takes what it shows and not the object: it is
    // re-read whole every time a column changes, and with the object this bar
    // would be repainted by a column title that says nothing about it.
    final (name, description, color) = context
      .select<TableViewService, (String, String, String)>(
        (service) => (
          service.structure.name,
          service.structure.description,
          service.structure.color
        )
      );

    final tint = _tint(color);

    final title = name.isNotEmpty
      ? name
      : cached.isNotEmpty ? cached : S.of(context).product_table_view_title;

    return Padding(
      padding: EdgeInsets.all(AppSize.gap),
      child: Row(children: [
        FeedbackButton(
          action: () => controller.back(context),
          width: AppSize.action,
          height: AppSize.action,
          message: S.of(context).inventory,
          child: Center(child: Icon(
            CI.arrow_left,
            color: scheme.text.primary
          ))
        ),
        SizedBox(width: AppSize.spaceS),
        if (tint != null) ...[
          Container(
            width: AppSize.text * 0.75,
            height: AppSize.text * 0.75,
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle)
          ),
          SizedBox(width: AppSize.gap)
        ],
        Expanded(child: Row(children: [
          Flexible(child: TextMedium(title, bold: true, ellipsis: true)),
          if (description.isNotEmpty) ...[
            SizedBox(width: AppSize.spaceS),
            Flexible(child: TextSmall(
              description,
              ellipsis: true,
              color: scheme.text.secondary
            ))
          ]
        ])),
        if (stage != null) ...[
          SizedBox(width: AppSize.spaceS),
          SizedBox(
            width: AppSize.text * 0.8,
            height: AppSize.text * 0.8,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: scheme.text.secondary
            )
          ),
          SizedBox(width: AppSize.gap),
          TextSmall(_stage(context, stage), color: scheme.text.secondary),
          SizedBox(width: AppSize.gap)
        ],
        const HeaderActions(),
        SizedBox(width: AppSize.gap),
        // Normalize the table: give each column the type that matches what it
        // holds and seed how much of it the agent sees. See [NormalizeButton].
        //
        // It goes before the settings because it is what is pressed **instead**
        // of entering them: both fix the same thing, but one asks to know which
        // column is wrong and the other does not.
        // Re-typing comes with importing: where that isn't offered, neither is this.
        if (CapabilityService().shows("inventory.import")) const NormalizeButton(),
        // The table's settings: everything there is of it except its rows —how
        // many records it has, what columns it is made of, how much the model
        // sees, and which channels read it—.
        //
        // They open to the side and not in another screen: they are the settings
        // of **this** sheet, and with the panel open the sheet keeps being seen
        // next to it. Closing it returns it whole, with its scroll and cursor
        // where they were. See [showTableSettings].
        FeedbackButton(
          action: () => showTableSettings(context, tableId),
          width: AppSize.action,
          height: AppSize.action,
          message: S.of(context).table_settings_title,
          feedbackColor: ThemeColor.of(context).surfaceFeedback,
          child: Center(child: Icon(
            CI.setting,
            color: scheme.text.primary
          ))
        )
      ])
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

  /// Table title according to the cached listing, or empty if it has not loaded
  /// yet.
  static String _cachedTitle(List<TableLiteModel> tables, String id) {
    for (final table in tables) {
      if (table.id == id && table.title.isNotEmpty) return table.title;
    }
    return "";
  }

  /// Table color from the ARGB literal the structure brings (`0xFF2196F3`), or
  /// `null` if it did not come or cannot be read: it is a header adornment and
  /// the screen looks the same without it.
  static Color? _tint(String raw) {
    if (raw.isEmpty) return null;

    final parsed = int.tryParse(raw);
    return parsed == null ? null : Color(parsed);
  }
}
