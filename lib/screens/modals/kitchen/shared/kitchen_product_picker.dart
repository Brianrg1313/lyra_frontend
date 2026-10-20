import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/kitchen/kitchen_product_model.dart';
import 'package:app/services/kitchen/kitchen_product_search.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/inventory/kitchen_format.dart';

/// A search over every table that hands back the product picked: a recipe's ingredient, an
/// option's extra, a product that offers a group. [exclude] are not offered (already there).
///
/// The search lives as long as the picker (a panel, above the section's providers).
class KitchenProductPicker extends StatefulWidget {
  const KitchenProductPicker({
    super.key,
    required this.placeholder,
    required this.onPick,
    this.exclude = const {},
    this.supplies = true,
    this.catalog = true
  });

  final String placeholder;
  final void Function(KitchenProduct product) onPick;

  /// Product ids not offered.
  final Set<String> exclude;
  final bool supplies;
  final bool catalog;

  @override
  State<KitchenProductPicker> createState() => _KitchenProductPickerState();
}

class _KitchenProductPickerState extends State<KitchenProductPicker> {
  late final _search = KitchenProductSearch(supplies: widget.supplies, catalog: widget.catalog);

  /// Owned by its input, which disposes it.
  final _query = InputController.search(key: "KITCHEN_PRODUCT_PICK");

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Hands [product] over and empties the search, ready for the next one: it is picked like an
  /// autocomplete, one after the other.
  void _pick(KitchenProduct product) {
    widget.onPick(product);
    _query.textController.clear();
    _search.search("");
    _query.focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SearchInput(controller: _query, placeholder: widget.placeholder, onSearch: _search.search),
      ListenableBuilder(listenable: _search, builder: (context, _) => _results(context))
    ]
  );

  Widget _results(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);

    switch (_search.status) {
      case KitchenProductSearchStatus.idle:
        return const SizedBox.shrink();
      case KitchenProductSearchStatus.loading:
        return Padding(padding: EdgeInsets.all(AppSize.spaceS), child: const Center(child: Loading()));
      case KitchenProductSearchStatus.error:
        return KitchenNote(text: s.kitchen_pick_error);
      case KitchenProductSearchStatus.ready:
        final results = [for (final product in _search.results) if (!widget.exclude.contains(product.id)) product];

        if (results.isEmpty) return KitchenNote(text: s.kitchen_pick_empty);

        return Padding(
          padding: EdgeInsets.only(top: AppSize.gap),
          child: Column(children: [
            for (final product in results) Padding(
              padding: EdgeInsets.only(bottom: AppSize.gap / 2),
              child: FeedbackButton(
                action: () => _pick(product),
                color: scheme.surfaceOver,
                padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS, vertical: AppSize.spaceXS),
                child: Row(children: [
                  Icon(product.supplies ? CI.warehouse : CI.product, size: AppSize.text, color: scheme.icon),
                  SizedBox(width: AppSize.gap),
                  Expanded(child: TextSmall(product.label, ellipsis: true)),
                  if (product.stock != null) ...[
                    SizedBox(width: AppSize.gap),
                    TextSmall(kitchenQty(context, product.stock!, unit: product.unit), color: scheme.text.secondary)
                  ],
                  SizedBox(width: AppSize.gap),
                  TextSmall(
                    _search.tableOf(product)?.title ?? "",
                    ellipsis: true,
                    color: scheme.text.secondary
                  ),
                  SizedBox(width: AppSize.gap),
                  Icon(CI.plus, size: AppSize.text, color: scheme.icon)
                ])
              )
            )
          ])
        );
    }
  }
}

/// A secondary line of help or of what went wrong, in the kitchen's panels.
class KitchenNote extends StatelessWidget {
  const KitchenNote({super.key, required this.text, this.color, this.padding});

  final String text;
  final Color? color;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding ?? EdgeInsets.symmetric(vertical: AppSize.gap),
    child: TextSmall(text, lines: 4, color: color ?? ThemeColor.of(context).text.secondary)
  );
}
