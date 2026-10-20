import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/services/home/home_service.dart';
import 'package:app/services/kitchen/kitchen_product_model.dart';
import 'package:app/services/kitchen/kitchen_products_service.dart';
import 'package:app/services/permissions/permissions_service.dart';
import 'package:app/services/preferences/preferences_service.dart';
import 'package:app/services/stock/tables/table_lite_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/more_button.dart';
import 'package:app/screens/home/sections/_section/section_message.dart';
import 'package:app/screens/home/sections/inventory/table_list/inventory_bar.dart';
import 'package:app/screens/modals/kitchen/recipe/_recipe.dart';

import './recipe_row.dart';

/// A supplies table's summary (`cocina-frontend.md` §2): the inventory's view of one while the
/// cells switch is off, in place of the catalogs' `StockSummarySection`.
///
/// Each row is a supply with its stock in its unit, between the − and + that move it, or what
/// its recipe makes now when it is a preparation made by the batch (a sauce). A click opens its
/// kitchen panel — how it is bought, where it is used, its batches — only with
/// `inventory.recipes`: whoever counts the shelf without `kitchen` sees the list and moves its
/// stock, and nothing is measured for them (`POST /recipes/availability` would be refused).
///
/// It owns the list of [table] ([KitchenProductsService]) and the inventory keys it by the
/// table, so picking another one reads it from the start. The header search box searches it
/// (`MATCH`), with the stock summary's breather between typing and reading.
class SuppliesSection extends StatefulWidget {
  const SuppliesSection({super.key, required this.table, required this.parts, this.service});

  final TableLiteModel table;
  final InventoryBarParts parts;

  /// The list's service; null makes its own. A seam for tests.
  final KitchenProductsService? service;

  @override
  State<SuppliesSection> createState() => _SuppliesSectionState();
}

class _SuppliesSectionState extends State<SuppliesSection> {
  /// Whether the person may open a supply's kitchen panel and see what a preparation makes.
  static bool get _kitchen =>
    CapabilityService().shows("inventory.recipes") && PermissionsService().canOpen("inventory.recipes");

  late final KitchenProductsService _service = widget.service
    ?? (_kitchen ? KitchenProductsService() : KitchenProductsService(measure: (_) async => const {}));

  late final ValueListenable<String> _query;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _query = context.read<HomeService>().searchQuery..addListener(_onSearch);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.service != null) return;

      _service.open(widget.table).then((_) {
        if (mounted && _query.value.trim().isNotEmpty) _service.search(_query.value);
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.removeListener(_onSearch);
    if (widget.service == null) _service.dispose();
    super.dispose();
  }

  void _onSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _service.search(_query.value));
  }

  Future<void> _open(KitchenProduct product) async {
    final changed = await showRecipePanel(context, product: product);

    if (changed && mounted) await _service.remeasure([product.id]);
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<KitchenProductsService>.value(
    value: _service,
    child: Builder(builder: (context) {
      final service = context.watch<KitchenProductsService>();
      final counted = service.status == KitchenProductsStatus.ready || service.status == KitchenProductsStatus.empty;

      return Surface(child: Column(children: [
        InventoryBar(parts: widget.parts, status: [
          if (counted) TextSmall(
            S.of(context).stock_summary_count(service.total),
            color: ThemeColor.of(context).text.secondary,
            ellipsis: true
          )
        ]),
        Separator.horizontal(),
        Expanded(child: Padding(
          padding: EdgeInsets.all(AppSize.padding),
          child: _body(context, service)
        ))
      ]));
    })
  );

  Widget _body(BuildContext context, KitchenProductsService service) {
    final s = S.of(context);
    final blank = service.query.isEmpty;

    return switch (service.status) {
      KitchenProductsStatus.idle || KitchenProductsStatus.loading => const Center(child: Loading()),
      KitchenProductsStatus.error => SectionMessage(
        icon: CI.info,
        title: s.kitchen_products_error,
        action: service.load,
        actionLabel: s.knowledge_retry
      ),
      KitchenProductsStatus.empty => SectionMessage(
        icon: CI.warehouse,
        title: blank ? s.kitchen_products_empty : s.kitchen_products_no_match,
        subtitle: blank ? s.kitchen_products_empty_note : null,
        action: blank ? () => PreferencesService().useInventoryView(InventoryView.sheet) : null,
        actionLabel: blank ? s.kitchen_open_sheet : null
      ),
      KitchenProductsStatus.ready => ListView.separated(
        itemCount: service.products.length + (service.hasMore ? 1 : 0),
        separatorBuilder: (_, _) => SizedBox(height: AppSize.gap),
        itemBuilder: (context, index) {
          if (index == service.products.length) {
            return SectionMoreButton(
              label: s.kitchen_products_more,
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
            onTap: _kitchen ? () => _open(product) : null,
            mover: service
          );
        }
      )
    };
  }
}
