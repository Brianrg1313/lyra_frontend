import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/kitchen/kitchen_product_model.dart';
import 'package:app/services/kitchen/kitchen_products_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/_section/more_button.dart';
import 'package:app/screens/home/sections/_section/section_message.dart';
import 'package:app/screens/home/sections/inventory/table_list/table_selector.dart';
import 'package:app/screens/modals/supply_chain/recipe/_recipe.dart';

import './recipe_row.dart';

/// The recipes tab: one table's products, each with what its recipe makes now (or that it has
/// none), and the panel of one of them on a click — its recipe, its 86, batches, lost dishes and
/// how it is bought.
///
/// A table of supplies lists too: a preparation made by the batch (a sauce) can live there, and
/// its presentations are edited from its panel.
class RecipesTab extends StatefulWidget {
  const RecipesTab({super.key});

  @override
  State<RecipesTab> createState() => _RecipesTabState();
}

class _RecipesTabState extends State<RecipesTab> {
  /// Owned by its input, which disposes it: it belongs to no form.
  final _query = InputController.search(key: "KITCHEN_PRODUCTS_SEARCH");

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final service = context.read<KitchenProductsService>();
      if (service.status == KitchenProductsStatus.idle) service.load();
    });
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (table != null) Row(children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: TableSelector(tables: service.tables, table: table, onSelect: service.open)
          ),
          SizedBox(width: AppSize.spaceS),
          Expanded(child: SearchInput(
            controller: _query,
            placeholder: s.supply_chain_products_search,
            onSearch: service.search
          ))
        ]),
        if (table != null) Padding(
          padding: EdgeInsets.symmetric(vertical: AppSize.spaceXS),
          child: TextSmall(
            table.supplies ? s.supply_chain_table_supplies_note : s.supply_chain_table_catalog_note,
            lines: 2,
            color: ThemeColor.of(context).text.secondary
          )
        ),
        Expanded(child: _body(context, service))
      ]
    );
  }

  Widget _body(BuildContext context, KitchenProductsService service) {
    final s = S.of(context);

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
        subtitle: service.table == null ? s.supply_chain_no_tables_note : null
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
