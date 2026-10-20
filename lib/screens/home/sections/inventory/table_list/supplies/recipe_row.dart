import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/kitchen/kitchen_product_model.dart';
import 'package:app/services/kitchen/recipe_availability_model.dart';
import 'package:app/services/kitchen/recipe_model.dart';
import 'package:app/services/stock/movements/stock_mover.dart';

// WIDGETS
import 'package:app/screens/home/sections/inventory/table_list/stock_summary/summary_layout.dart';
import 'package:app/screens/home/sections/inventory/table_list/stock_summary/summary_stepper.dart';
import 'package:app/screens/home/sections/inventory/kitchen_format.dart';
import 'package:app/screens/modals/inventory/stock_movement/movement_shape.dart';

/// One supply of a supplies table's list ([SuppliesSection]): its name, how it is made, and in one line what it makes now
/// («3 left — because of the bacon», «12 on the shelf · supplies for 200 more (wick)»). Paused
/// (86) says so in red.
///
/// The strip on its left is the menu cards' traffic light ([recipeLevelColor]), so a list of
/// preparations is scanned for what runs short without reading; a supply bought ready has no
/// light (nothing is made of it) and its stock stands at the right edge, where figures line up,
/// between the stock summary's − and + ([SummaryStepper]) when there is a [mover]: counting a
/// delivery in is done from the list, not by opening each supply.
class RecipeRow extends StatelessWidget {
  const RecipeRow({super.key, required this.product, required this.availability, this.onTap, this.mover});

  final KitchenProduct product;

  /// `null`: no recipe.
  final RecipeAvailability? availability;
  /// Opens its kitchen panel; `null` without `inventory.recipes` (the row only moves stock).
  final void Function()? onTap;

  /// What its − and + move the supply through; without one the stock is only read.
  final StockMover? mover;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);
    final made = availability;
    final stock = product.stock;

    return FeedbackButton(
      action: onTap,
      color: scheme.surfaceOver,
      padding: EdgeInsets.all(AppSize.spaceS),
      child: Row(children: [
        Container(
          width: AppSize.gap * 0.75,
          height: AppSize.action,
          decoration: BoxDecoration(
            color: made == null ? scheme.line : recipeLevelColor(scheme, made),
            borderRadius: BorderRadius.circular(AppSize.gap)
          )
        ),
        SizedBox(width: AppSize.spaceS),
        Expanded(child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Flexible(child: TextMedium(product.label, ellipsis: true, bold: true)),
              if (made != null) ...[
                SizedBox(width: AppSize.spaceS),
                RecipeTag(
                  text: made.mode == RecipeMode.batch ? s.kitchen_mode_batch : s.kitchen_mode_order,
                  color: scheme.accent
                )
              ],
              if (made?.paused ?? false) ...[
                SizedBox(width: AppSize.gap),
                RecipeTag(text: s.kitchen_paused, color: scheme.snackBar.error)
              ]
            ]),
            SizedBox(height: AppSize.gap),
            TextSmall(made == null ? s.kitchen_no_recipe : recipeAvailabilityLine(context, made),
              ellipsis: true, color: scheme.text.secondary)
          ]
        )),
        if (made == null && stock != null) ...[
          SizedBox(width: AppSize.spaceS),
          if (mover == null)
            TextMedium(kitchenQty(context, stock, unit: product.unit), bold: true, textAlign: TextAlign.end)
          else
            SizedBox(
              width: SummaryLayout.numberWidth * 1.3,
              child: SummaryStepper(
                productId: product.id,
                counter: StockCounter.stock,
                stock: stock,
                // The list does not read what is set aside; the backend caps it anyway.
                reserved: 0,
                product: product.label,
                unit: product.unit,
                mover: mover
              )
            )
        ],
        SizedBox(width: AppSize.spaceS),
        Icon(CI.arrow_right, size: AppSize.text, color: scheme.text.secondary)
      ])
    );
  }
}

/// The traffic light of what a recipe makes now: none (or paused) is critical, [kitchenFew] or
/// fewer a warning. A batch reads its shelf, a dish made to order what its supplies allow.
Color recipeLevelColor(SchemeColor scheme, RecipeAvailability made) {
  if (made.paused || made.available <= 0) return scheme.chart.critical;

  return made.available <= kitchenFew ? scheme.chart.warning : scheme.chart.good;
}

/// What a recipe makes now, in words (`cocina-frontend.md` §4).
String recipeAvailabilityLine(BuildContext context, RecipeAvailability made) {
  final s = S.of(context);
  final limit = made.limit?.name ?? "";

  if (made.paused) return s.kitchen_paused_note;

  if (made.mode == RecipeMode.batch) {
    final shelf = s.kitchen_shelf(kitchenQty(context, made.available));
    final capacity = made.capacity;

    if (capacity == null) return shelf;

    final more = limit.isEmpty
      ? s.kitchen_capacity(kitchenQty(context, capacity))
      : s.kitchen_capacity_limit(kitchenQty(context, capacity), limit);

    return "$shelf · $more";
  }

  final left = kitchenQty(context, made.available);

  return limit.isEmpty ? s.kitchen_left(left) : s.kitchen_left_limit(left, limit);
}

/// A short tag beside a name: how it is made, paused.
class RecipeTag extends StatelessWidget {
  const RecipeTag({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: AppSize.gap * 1.5, vertical: AppSize.gap / 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppSize.corner)
    ),
    child: TextSmall(text, color: color, multiplier: 0.9)
  );
}
