import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/services/home/home_service.dart';
import 'package:app/services/kitchen/kitchen_product_model.dart';
import 'package:app/services/kitchen/made_product_model.dart';
import 'package:app/services/kitchen/made_products_service.dart';
import 'package:app/services/permissions/permissions_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/home/sections/_section/more_button.dart';
import 'package:app/screens/home/sections/_section/section_message.dart';
import 'package:app/screens/home/sections/inventory/table_list/inventory_bar.dart';
import 'package:app/screens/modals/inventory/made_product/_made_product.dart';
import 'package:app/screens/modals/supply_chain/recipe/_recipe.dart';

import './made_product_row.dart';

/// A `made` table, as what it is: a list of products, each one a name, a price and what it
/// consumes (`cocina-frontend.md` §2, §3), never a sheet of rows and columns. «New product» and a
/// tap on one open its form ([showMadeProduct]), where what it consumes is picked from the
/// supplies and measured in their unit; how many can be made with them is the backend's.
///
/// Owns the table's [MadeProductsService]; the header search narrows it (`MATCH`). With
/// `supply_chain.recipes` a product also opens its kitchen page (the 86, batches, lost dishes).
class MadeProductsSection extends StatefulWidget {
  const MadeProductsSection({super.key, required this.tableId, required this.parts, this.service});

  final String tableId;
  final InventoryBarParts parts;

  /// An already built one, for tests: not disposed here.
  @visibleForTesting
  final MadeProductsService? service;

  @override
  State<MadeProductsSection> createState() => _MadeProductsSectionState();
}

class _MadeProductsSectionState extends State<MadeProductsSection> {
  late final _service = widget.service ?? MadeProductsService(tableId: widget.tableId);

  late final ValueListenable<String> _query;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _query = context.read<HomeService>().searchQuery..addListener(_onSearch);

    // Loads notify their listeners; deferred to the first frame so a rebuild
    // isn't triggered while the tree is still being mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _service.load(query: _query.value);
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

  bool get _canWrite => PermissionsService().can("supply_chain.recipes.edit");

  Future<void> _open([MadeProduct? product]) => showMadeProduct(context, service: _service, product: product);

  Future<void> _kitchen(MadeProduct product) async {
    final changed = await showRecipePanel(context, product: KitchenProduct(
      id: product.id,
      tableId: widget.tableId,
      name: product.valueOf(_service.fields.name),
      made: true
    ));

    if (changed && mounted) _service.refresh();
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<MadeProductsService>.value(
    value: _service,
    child: Surface(child: Column(children: [
      ListenableBuilder(listenable: _service, builder: (context, _) => InventoryBar(
        parts: widget.parts,
        status: [
          if (_service.status == MadeProductsStatus.ready && _service.total != null) TextSmall(
            S.of(context).made_products_count(_service.total!),
            color: ThemeColor.of(context).text.secondary,
            ellipsis: true
          )
        ],
        actions: [
          if (_canWrite) Button(
            width: null,
            title: S.of(context).made_product_new,
            leftIcon: Icon(CI.plus, color: ThemeColor.of(context).button.text),
            action: _open
          )
        ]
      )),
      Separator.horizontal(),
      Expanded(child: ListenableBuilder(listenable: _service, builder: (context, _) => _body(context)))
    ]))
  );

  Widget _body(BuildContext context) {
    final s = S.of(context);

    switch (_service.status) {
      case MadeProductsStatus.loading:
        return const Center(child: Loading());
      case MadeProductsStatus.error:
        return SectionMessage(
          icon: CI.info,
          title: s.made_products_error_title,
          subtitle: s.made_products_error_subtitle,
          action: () => _service.load(query: _query.value),
          actionLabel: s.product_tables_retry
        );
      case MadeProductsStatus.empty:
        if (_service.isSearching) {
          return SectionMessage(icon: CI.search, title: s.made_products_no_match);
        }

        return SectionMessage(
          icon: CI.fire_sqaure,
          title: s.made_products_empty_title,
          subtitle: s.made_products_empty_subtitle,
          action: _canWrite ? _open : null,
          actionLabel: s.made_product_new,
          actionIcon: CI.plus
        );
      case MadeProductsStatus.ready:
        break;
    }

    final products = _service.products;
    final kitchen = CapabilityService().shows("supply_chain.recipes");

    return ListView.separated(
      padding: EdgeInsets.all(AppSize.padding),
      itemCount: products.length + (_service.hasMore ? 1 : 0),
      separatorBuilder: (context, _) => SizedBox(height: AppSize.gap),
      itemBuilder: (context, index) {
        if (index == products.length) {
          return SectionMoreButton(
            label: s.made_products_more,
            retryLabel: s.product_tables_retry,
            failed: _service.moreFailed,
            onMore: _service.more,
            onRetry: _service.more
          );
        }

        final product = products[index];

        return MadeProductRow(
          key: ValueKey(product.id),
          product: product,
          service: _service,
          onOpen: () => _open(product),
          onKitchen: kitchen ? () => _kitchen(product) : null
        );
      }
    );
  }
}
