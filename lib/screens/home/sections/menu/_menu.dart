import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';
import 'package:app/services/preferences/preferences_service.dart';
import 'package:app/services/stock/tables/table_lite_model.dart';
import 'package:app/services/stock/tables/tables_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/home/sections/_section/section_message.dart';
import 'package:app/screens/home/sections/inventory/table_list/inventory_bar.dart';
import 'package:app/screens/home/sections/inventory/table_list/table_options.dart';
import 'package:app/screens/home/sections/inventory/table_list/table_selector.dart';
import 'package:app/screens/modals/inventory/create_table/_create_table.dart';

import './made_products/_made_products.dart';

/// The menu: what the company makes from its supplies and sells (a burger, a combo, a candle),
/// **one `made` table at a time** (`cocina-frontend.md` §2, §3).
///
/// Its own section, apart from the inventory's products and supplies: a made product is
/// written as a form with what it consumes, never as a sheet's row. The tables are the inventory's (`TablesService`, the same grants): only the kind
/// tells them apart, so the bar's selector, options and create are the inventory's, and a made
/// table is never listed there.
///
/// Which table opens: the one last open here in this company, else the first. None → the
/// offer to create the first one.
class MenuSection extends StatefulWidget {
  const MenuSection({super.key});

  @override
  State<MenuSection> createState() => _MenuSectionState();
}

class _MenuSectionState extends State<MenuSection> {
  /// A pick or a just created one; resolved against the list on each build ([_open]).
  String? _picked;

  @override
  void initState() {
    super.initState();

    // Loads notify their listeners; deferred to the first frame so a rebuild
    // isn't triggered while the tree is still being mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  /// The service caches per company: an inventory already opened answers at once.
  void _load({bool force = false}) => context.read<TablesService>().load(
    context.read<BusinessService>().active.id,
    force: force
  );

  /// The table that opens, among [tables] (never empty).
  TableLiteModel _open(List<TableLiteModel> tables) {
    final remembered = PreferencesService().recall(RememberedSelection.menu);

    for (final id in [_picked, remembered]) {
      for (final table in tables) {
        if (id != null && table.id == id) return table;
      }
    }

    return tables.first;
  }

  void _select(String id) {
    setState(() => _picked = id);
    PreferencesService().remember(RememberedSelection.menu, id);
  }

  Future<void> _create() async {
    final id = await showModal(
      context: context,
      title: S.of(context).menu_create,
      builder: (BuildContext context) => const CreateTableModal(kind: TableKind.made)
    );

    if (!mounted || id is! String) return;

    _select(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<TablesService>();
    final s = S.of(context);
    final tables = [
      for (final table in service.tables)
        if (table.made) table
    ];

    // A reload keeps the tables it had in view: only a first read covers the section.
    if (tables.isEmpty) {
      return Surface(child: switch (service.tables.isNotEmpty ? TablesStatus.empty : service.status) {
        TablesStatus.error => SectionMessage(
          icon: CI.info,
          title: s.product_tables_error_title,
          subtitle: s.product_tables_error_subtitle,
          action: () => _load(force: true),
          actionLabel: s.product_tables_retry
        ),
        TablesStatus.empty => SectionMessage(
          icon: CI.fire_sqaure,
          title: s.menu_empty_title,
          subtitle: s.menu_empty_subtitle,
          action: _create,
          actionLabel: s.menu_create
        ),
        _ => const Center(child: Loading())
      });
    }

    final table = _open(tables);

    return MadeProductsSection(
      key: ValueKey("made_${table.id}"),
      tableId: table.id,
      parts: InventoryBarParts(
        selector: TableSelector(
          tables: tables,
          table: table,
          onSelect: (table) => _select(table.id)
        ),
        controls: const [],
        actions: [
          TableOptionsButton(table: table, transfers: false),
          Button(
            width: null,
            title: s.menu_create,
            leftIcon: Icon(CI.plus, color: ThemeColor.of(context).button.text),
            action: _create
          )
        ]
      )
    );
  }
}
