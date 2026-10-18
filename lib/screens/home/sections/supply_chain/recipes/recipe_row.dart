import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/kitchen/kitchen_product_model.dart';
import 'package:app/services/kitchen/recipe_availability_model.dart';
import 'package:app/services/kitchen/recipe_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/supply_chain/kitchen_format.dart';

/// One product of the recipes tab: its name, how it is made, and in one line what it makes now
/// («3 left — because of the bacon», «12 on the shelf · supplies for 200 more (wick)»). Paused
/// (86) says so in red.
///
/// The strip on its left is the menu cards' traffic light ([recipeLevelColor]), so a list of
/// preparations is scanned for what runs short without reading; a supply bought ready has no
/// light (nothing is made of it) and its stock stands at the right edge, where figures line up.
class RecipeRow extends StatelessWidget {
  const RecipeRow({super.key, required this.product, required this.availability, required this.onTap});

  final KitchenProduct product;

  /// `null`: no recipe.
  final RecipeAvailability? availability;
  final void Function() onTap;

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
                  text: made.mode == RecipeMode.batch ? s.supply_chain_mode_batch : s.supply_chain_mode_order,
                  color: scheme.accent
                )
              ],
              if (made?.paused ?? false) ...[
                SizedBox(width: AppSize.gap),
                RecipeTag(text: s.supply_chain_paused, color: scheme.snackBar.error)
              ]
            ]),
            SizedBox(height: AppSize.gap),
            TextSmall(made == null ? s.supply_chain_no_recipe : recipeAvailabilityLine(context, made),
              ellipsis: true, color: scheme.text.secondary)
          ]
        )),
        if (made == null && stock != null) ...[
          SizedBox(width: AppSize.spaceS),
          TextMedium(kitchenQty(context, stock, unit: product.unit), bold: true, textAlign: TextAlign.end)
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

  if (made.paused) return s.supply_chain_paused_note;

  if (made.mode == RecipeMode.batch) {
    final shelf = s.supply_chain_shelf(kitchenQty(context, made.available));
    final capacity = made.capacity;

    if (capacity == null) return shelf;

    final more = limit.isEmpty
      ? s.supply_chain_capacity(kitchenQty(context, capacity))
      : s.supply_chain_capacity_limit(kitchenQty(context, capacity), limit);

    return "$shelf · $more";
  }

  final left = kitchenQty(context, made.available);

  return limit.isEmpty ? s.supply_chain_left(left) : s.supply_chain_left_limit(left, limit);
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
