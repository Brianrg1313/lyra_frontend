import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/catalog/currency_catalog_service.dart';
import 'package:app/services/kitchen/kitchen_units.dart';
import 'package:app/services/kitchen/made_product_model.dart';
import 'package:app/services/kitchen/made_products_service.dart';
import 'package:app/services/kitchen/recipe_model.dart';
import 'package:app/toolkit/settings/initial_builder.dart' show businessService;

// WIDGETS
import 'package:app/screens/home/sections/supply_chain/kitchen_format.dart';
import 'package:app/screens/home/sections/supply_chain/recipes/recipe_row.dart';

/// One made product in its table's list: its name and what it consumes («Meat 300 g · Bread ×1»)
/// on the left, its price and how many can be sold now on the right (`cocina-frontend.md` §3:
/// «Disponibles: N» and the ingredients, never a stock to write). A tap opens its form;
/// [onKitchen], when given, its kitchen page (the 86, batches, lost dishes).
class MadeProductRow extends StatelessWidget {
  const MadeProductRow({
    super.key,
    required this.product,
    required this.service,
    required this.onOpen,
    this.onKitchen
  });

  final MadeProduct product;
  final MadeProductsService service;
  final void Function() onOpen;
  final void Function()? onKitchen;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);
    final name = product.valueOf(service.fields.name);
    final consumes = product.consumes;
    final availability = consumes?.availability;
    final out = availability != null && (availability.paused || availability.available <= 0);

    return FeedbackButton(
      action: onOpen,
      color: scheme.surfaceOver,
      padding: EdgeInsets.symmetric(horizontal: AppSize.padding, vertical: AppSize.spaceS),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(child: TextMedium(name.isEmpty ? s.made_product_unnamed : name, bold: true, ellipsis: true)),
            if (consumes?.recipe.mode == RecipeMode.batch) ...[
              SizedBox(width: AppSize.gap),
              RecipeTag(text: s.supply_chain_mode_batch, color: scheme.accent)
            ]
          ]),
          SizedBox(height: AppSize.gap),
          if (consumes == null || consumes.recipe.lines.isEmpty)
            TextSmall(s.made_product_consumes_none, color: scheme.text.secondary)
          else
            Wrap(spacing: AppSize.gap, runSpacing: AppSize.gap / 2, children: [
              for (final line in consumes.recipe.lines) _LineChip(line: line, unit: service.unitOf(line.productId))
            ])
        ])),
        SizedBox(width: AppSize.spaceM),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          TextMedium(_price(product.valueOf(service.fields.price)), bold: true),
          SizedBox(height: AppSize.gap),
          if (availability != null) TextSmall(
            recipeAvailabilityLine(context, availability),
            color: out ? scheme.snackBar.error : scheme.text.secondary
          )
        ]),
        if (onKitchen != null) ...[
          SizedBox(width: AppSize.spaceS),
          FocusableWidget(
            action: onKitchen,
            message: s.made_product_kitchen,
            child: Padding(
              padding: EdgeInsets.all(AppSize.gap),
              child: Icon(CI.fire_sqaure, size: AppSize.text * 1.2, color: scheme.icon)
            )
          )
        ]
      ])
    );
  }

  /// In the column's currency, or the company's; what isn't an amount as it is.
  String _price(String value) {
    if (value.isEmpty) return "";

    final unit = service.fields.price?.unit ?? "";

    return CurrencyCatalogService().resolve(unit.isEmpty ? businessService.currencyCode : unit).label(value) ?? value;
  }
}

/// One thing a product consumes, in the unit it reads best in (0.3 kg of meat is 300 g).
class _LineChip extends StatelessWidget {
  const _LineChip({required this.line, required this.unit});

  final RecipeLine line;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final best = kitchenBestUnit(line.qty, unit);
    final qty = best.unit.symbol.isEmpty
      ? S.of(context).made_product_line_times(kitchenQty(context, best.qty))
      : kitchenQty(context, best.qty, unit: best.unit.symbol);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSize.gap * 1.5, vertical: AppSize.gap / 2),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppSize.corner)
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        TextSmall(line.name.isEmpty ? line.productId : line.name, multiplier: 0.9),
        SizedBox(width: AppSize.gap),
        TextSmall(qty, multiplier: 0.9, bold: true, color: line.negotiable ? scheme.text.secondary : null)
      ])
    );
  }
}
