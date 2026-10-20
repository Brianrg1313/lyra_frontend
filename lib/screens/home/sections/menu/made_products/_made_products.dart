import 'dart:async';
import 'dart:math';

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
import 'package:app/screens/modals/kitchen/recipe/_recipe.dart';

import './made_product_card.dart';
import './made_product_new_card.dart';

/// A `made` table, as what it is: a menu, a grid of cards, each one a photo, a name, a price and
/// what it consumes (`cocina-frontend.md` §2, §3), never a sheet of rows and columns. «New product» and a
/// tap on one open its form ([showMadeProduct]), where what it consumes is picked from the
/// supplies and measured in their unit; how many can be made with them is the backend's.
///
/// Owns the table's [MadeProductsService]; the header search narrows it (`MATCH`). With
/// `inventory.recipes` a product also opens its kitchen page (the 86, batches, lost dishes).
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

  bool get _canWrite => PermissionsService().can("inventory.recipes.edit");

  /// The backend deletes a record with `products.delete`, apart from writing one.
  bool get _canDelete => PermissionsService().can("products.delete");

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

  /// What a right click or a long press on [product]'s card offers. Duplicating needs what it
  /// consumes, read with the page: a copy without it would be sold without consuming.
  List<ContextEntry> _entries(MadeProduct product) {
    final s = S.of(context);
    final name = product.valueOf(_service.fields.name);

    return [
      ContextHeader(name.isEmpty ? s.made_product_unnamed : name),
      if (_canWrite) ...[
        ContextItem(label: s.edit, icon: CI.edit, onSelected: () => _open(product)),
        ContextItem(
          label: s.made_product_duplicate,
          icon: CI.copy,
          enabled: product.consumes != null,
          onSelected: () => _duplicate(product)
        )
      ],
      if (_canDelete) ...[
        const ContextSeparator(),
        ContextItem(label: s.made_product_delete, icon: CI.trash, danger: true, onSelected: () => _delete(product))
      ]
    ];
  }

  Future<void> _duplicate(MadeProduct product) async {
    final s = S.of(context);
    final name = product.valueOf(_service.fields.name);
    final done = await _service.duplicate(
      context,
      product,
      name: s.made_product_copy_name(name.isEmpty ? s.made_product_unnamed : name)
    );

    if (done && mounted) FloatFlag.of(context).message(s.made_product_duplicated);
  }

  Future<void> _delete(MadeProduct product) async {
    final s = S.of(context);
    final name = product.valueOf(_service.fields.name);
    final confirmed = await showAlertModal(
      context: context,
      title: s.made_product_delete_title,
      message: s.made_product_delete_message(name.isEmpty ? s.made_product_unnamed : name),
      confirmText: s.made_product_delete,
      cancelText: s.cancel
    );

    if (!confirmed || !mounted) return;

    final done = await _service.remove(context, product);
    if (done && mounted) FloatFlag.of(context).message(s.made_product_deleted);
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
    final kitchen = CapabilityService().shows("inventory.recipes");
    final tiles = <Widget>[
      if (_canWrite) MadeProductNewCard(onCreate: _open),
      for (final product in products) ContextMenuRegion(
        key: ValueKey(product.id),
        entries: (_) => _entries(product),
        child: MadeProductCard(
          product: product,
          service: _service,
          onOpen: () => _open(product),
          onKitchen: kitchen ? () => _kitchen(product) : null
        )
      )
    ];

    return LayoutBuilder(builder: (context, box) {
      final gap = AppSize.spaceS;
      final columns = max(1, ((box.maxWidth - AppSize.padding * 2 + gap) / (MadeProductCard.extent + gap)).floor());
      final rows = (tiles.length / columns).ceil();

      return ListView.separated(
        padding: EdgeInsets.all(AppSize.padding),
        itemCount: rows + (_service.hasMore ? 1 : 0),
        separatorBuilder: (context, _) => SizedBox(height: gap),
        itemBuilder: (context, row) {
          if (row == rows) {
            return SectionMoreButton(
              label: s.made_products_more,
              retryLabel: s.product_tables_retry,
              failed: _service.moreFailed,
              onMore: _service.more,
              onRetry: _service.more
            );
          }

          // A row of cards as tall as its tallest, so every price lines up at the foot.
          return IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (var column = 0; column < columns; column++) ...[
              if (column > 0) SizedBox(width: gap),
              Expanded(child: row * columns + column < tiles.length ? tiles[row * columns + column] : const SizedBox())
            ]
          ]));
        }
      );
    });
  }
}
