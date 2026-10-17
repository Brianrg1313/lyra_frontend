import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/kitchen/kitchen_product_model.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/services/kitchen/kitchen_products_service.dart';
import 'package:app/services/stock/tables/table_lite_model.dart';
import 'package:app/services/stock/tables/tables_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';
import 'package:app/screens/home/sections/_section/more_button.dart';
import 'package:app/screens/home/sections/_section/section_message.dart';
import 'package:app/screens/home/sections/inventory/table_list/inventory_bar.dart';
import 'package:app/screens/home/sections/inventory/table_list/table_selector.dart';
import 'package:app/screens/home/sections/inventory/table_list/view_toggle.dart';
import 'package:app/screens/home/sections/inventory/table_view/_table_view.dart';
import 'package:app/screens/modals/inventory/create_table/_create_table.dart';
import 'package:app/screens/modals/supply_chain/recipe/_recipe.dart';

import './recipe_row.dart';

/// The supplies tab: one supplies table's rows (`cocina-frontend.md` §2.1), each with its stock
/// in its unit, or what its recipe makes when it is a preparation made by the batch (a sauce),
/// and the panel of one of them on a click — how it is bought, where it is used, its batches.
///
/// **Supplies tables only**: what is sold is the inventory section's, which opens a dish's
/// recipe from its own rows. With none the tab offers to create the first («New table» makes
/// supplies here, never asked).
///
/// **The supplies are written in the sheet** (the inventory's [TableViewSection], here for a
/// supplies table): the cells switch swaps the list for it, and a table with no rows opens on
/// it, since the inventory never lists a supplies table and there is no other place to fill
/// one. Back on the list, its rows are read again (the sheet wrote them).
class RecipesTab extends StatefulWidget {
  const RecipesTab({super.key});

  @override
  State<RecipesTab> createState() => _RecipesTabState();
}

class _RecipesTabState extends State<RecipesTab> {
  /// Owned by its input, which disposes it: it belongs to no form. The sheet unmounts that
  /// input, so the list coming back makes a new one ([_listed]) with the search it had.
  InputController _query = InputController.search(key: "KITCHEN_PRODUCTS_SEARCH");

  /// Whether the last build drew the list, whose input still holds [_query].
  bool _listed = true;

  /// The cells switch, per opened table: `null` until touched, which opens a table with no
  /// rows on the sheet ([_sheet]).
  bool? _sheetPicked;

  /// Whether [table] shows as the sheet: the switch's, else whether it has nothing to list.
  bool _sheet(TableLiteModel table) => _sheetPicked ?? table.records == 0;

  /// Swaps the view; the list rereads the table, whose rows the sheet may have written.
  void _switch(bool sheet) {
    setState(() => _sheetPicked = sheet);

    final service = context.read<KitchenProductsService>();
    if (!sheet) service.load(tableId: service.table?.id);
  }

  void _select(TableLiteModel table) {
    setState(() => _sheetPicked = null);
    context.read<KitchenProductsService>().open(table);
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final service = context.read<KitchenProductsService>();
      if (service.status == KitchenProductsStatus.idle) service.load();
    });
  }

  /// A supplies table through the create modal, which answers its id: it opens here, and the
  /// app's list (the inventory's, which leaves it out) reads it again.
  Future<void> _create() async {
    final id = await showModal(
      context: context,
      title: S.of(context).supply_chain_table_create,
      builder: (BuildContext context) => const CreateTableModal(supplies: true)
    );

    if (!mounted || id is! String) return;

    setState(() => _sheetPicked = null);
    unawaited(context.read<TablesService>().load(context.read<BusinessService>().active.id, force: true));

    await context.read<KitchenProductsService>().load(tableId: id);
  }

  Future<void> _open(KitchenProduct product) async {
    final service = context.read<KitchenProductsService>();

    final changed = await showRecipePanel(context, product: product);

    if (changed && mounted) await service.remeasure([product.id]);
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<KitchenProductsService>();
    final s = S.of(context);
    final table = service.table;

    if (table != null && _sheet(table)) {
      _listed = false;

      return TableViewSection(
        key: ValueKey("supplies_sheet_${table.id}"),
        tableId: table.id,
        parts: InventoryBarParts(
          selector: TableSelector(tables: service.tables, table: table, onSelect: _select),
          controls: [InventoryViewToggle(sheet: true, onSwitch: _switch)],
          actions: [_createButton(context)]
        )
      );
    }

    if (!_listed) {
      _query = InputController.search(key: "KITCHEN_PRODUCTS_SEARCH", initial: service.query);
      _listed = true;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (table != null) Row(children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: TableSelector(tables: service.tables, table: table, onSelect: _select)
          ),
          SizedBox(width: AppSize.gap),
          InventoryViewToggle(sheet: false, onSwitch: _switch),
          SizedBox(width: AppSize.spaceS),
          Expanded(child: SearchInput(
            controller: _query,
            placeholder: s.supply_chain_products_search,
            onSearch: service.search
          )),
          SizedBox(width: AppSize.spaceS),
          _createButton(context)
        ]),
        if (table != null) Padding(
          padding: EdgeInsets.symmetric(vertical: AppSize.spaceXS),
          child: TextSmall(
            s.supply_chain_table_supplies_note,
            lines: 2,
            color: ThemeColor.of(context).text.secondary
          )
        ),
        Expanded(child: _body(context, service))
      ]
    );
  }

  Widget _createButton(BuildContext context) => Button(
    width: null,
    title: S.of(context).create_table,
    leftIcon: Icon(CI.plus, color: ThemeColor.of(context).button.text),
    action: _create
  );

  Widget _body(BuildContext context, KitchenProductsService service) {
    final s = S.of(context);
    final blank = service.table != null && service.query.isEmpty;

    return switch (service.status) {
      KitchenProductsStatus.idle || KitchenProductsStatus.loading => const Center(child: Loading()),
      KitchenProductsStatus.error => SectionMessage(
        icon: CI.info,
        title: s.supply_chain_products_error,
        action: () => service.load(tableId: service.table?.id),
        actionLabel: s.knowledge_retry
      ),
      KitchenProductsStatus.empty => SectionMessage(
        icon: CI.warehouse,
        title: service.table == null
          ? s.supply_chain_no_tables
          : service.query.isEmpty ? s.supply_chain_products_empty : s.supply_chain_products_no_match,
        subtitle: service.table == null ? s.supply_chain_no_tables_note
          : blank ? s.supply_chain_products_empty_note : null,
        action: service.table == null ? _create
          : blank ? () => _switch(true) : null,
        actionLabel: service.table == null ? s.supply_chain_table_create
          : blank ? s.supply_chain_open_sheet : null
      ),
      KitchenProductsStatus.ready => ListView.separated(
        itemCount: service.products.length + (service.hasMore ? 1 : 0),
        separatorBuilder: (_, _) => SizedBox(height: AppSize.gap),
        itemBuilder: (context, index) {
          if (index == service.products.length) {
            return SectionMoreButton(
              label: s.supply_chain_products_more,
              retryLabel: s.knowledge_retry,
              failed: false,
              onMore: service.more,
              onRetry: service.more
            );
          }

          final product = service.products[index];

          return RecipeRow(
            product: product,
            availability: service.availabilityOf(product.id),
            onTap: () => _open(product)
          );
        }
      )
    };
  }
}
