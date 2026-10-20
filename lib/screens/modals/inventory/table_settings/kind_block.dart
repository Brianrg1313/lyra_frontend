import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/stock/tables/table_detail_model.dart';
import 'package:app/services/stock/tables/table_detail_service.dart';
import 'package:app/services/stock/tables/table_lite_model.dart';
import 'package:app/services/stock/tables/tables_service.dart';

// WIDGETS
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// Whether an inventory table **sells**: products (the register, the catalog
/// and the AI offer them) or supplies (only spent by recipes, counted with
/// decimals). The same table turns either way with its rows as they are
/// (`cocina-frontend.md` §2): a parts shop that starts building PCs on the menu
/// keeps selling its parts, and one that only wants them for its builds turns
/// them off here instead of rebuilding the table.
///
/// It asks first, saying what changes, because a switch reaches every channel
/// that sells. The backend refuses it while something stops it —units held, a
/// fraction going to products, a recipe, modifiers— and the banner says which.
///
/// Not drawn for a menu table, which never switches.
class TableKindBlock extends StatelessWidget {
  const TableKindBlock({super.key, required this.detail});

  final TableDetailModel detail;

  Future<void> _toggle(BuildContext context) async {
    final selling = detail.kind == TableKind.catalog;
    final s = S.of(context);

    final confirmed = await showAlertModal(
      context: context,
      title: selling ? s.table_kind_to_supplies_title : s.table_kind_to_catalog_title,
      message: selling ? s.table_kind_to_supplies_message(detail.name) : s.table_kind_to_catalog_message(detail.name),
      confirmText: selling ? s.table_kind_to_supplies : s.table_kind_to_catalog,
      cancelText: s.cancel
    );

    if (!confirmed || !context.mounted) return;

    final tables = context.read<TablesService>();

    await context.read<TableDetailService>().switchKind(
      context,
      selling ? TableKind.supplies : TableKind.catalog,
      onSwitched: tables.reload
    );
  }

  @override
  Widget build(BuildContext context) {
    final selling = detail.kind == TableKind.catalog;
    final busy = context.select<TableDetailService, bool>((service) => service.isReloading);

    return SettingsBlock(
      title: S.of(context).table_kind_title,
      subtitle: S.of(context).table_kind_subtitle,
      child: SettingsList(rows: [
        SettingsRow(
          icon: selling ? Icons.sell_outlined : Icons.blender_outlined,
          label: S.of(context).table_kind_label,
          hint: selling ? S.of(context).table_kind_catalog_hint : S.of(context).table_kind_supplies_hint,
          child: SettingsToggle(
            value: selling,
            label: selling ? S.of(context).table_kind_catalog : S.of(context).table_kind_supplies,
            toggle: busy ? () {} : () => _toggle(context)
          )
        )
      ])
    );
  }
}
