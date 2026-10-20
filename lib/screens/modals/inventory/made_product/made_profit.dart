import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/kitchen/kitchen_report_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/supply_chain/kitchen_format.dart';

/// What the product earns, beside its price: the price as it is being typed, less what making it
/// costs from what each supply costs (`POST /recipes/cost`, `cocina-frontend.md` §9). Nothing to
/// fill: it is read, and it moves with the price and with the recipe as it is written.
///
/// The cost is the recipe's as typed (the form costs it, [RecipeEditor] names the supplies with
/// no price under its lines); with one of them, the figure is a floor.
class MadeProfit extends StatelessWidget {
  const MadeProfit({super.key, required this.price, required this.cost, required this.lines});

  /// The price field's text.
  final TextEditingController price;

  /// `null` while it is read, or when it can't be told.
  final DishCost? cost;

  /// Whether the recipe has a line to cost.
  final bool lines;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: price,
    builder: (context, _) => _build(context)
  );

  Widget _build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);
    final cost = this.cost;

    if (!lines) return TextSmall(s.made_product_profit_new, lines: 3, color: scheme.text.secondary);

    // A cost of nothing with nothing priced says nothing yet.
    if (cost == null || (!cost.complete && cost.cost == 0)) {
      return TextSmall(s.made_product_profit_none, lines: 3, color: scheme.text.secondary);
    }

    final amount = kitchenParse(price.text) ?? 0;
    final gain = amount - cost.cost;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Wrap(crossAxisAlignment: WrapCrossAlignment.end, spacing: AppSize.gap, children: [
        TextMedium(
          gain < 0 ? s.made_product_profit_loss(kitchenMoney(-gain)) : s.made_product_profit_gain(kitchenMoney(gain)),
          bold: true,
          color: gain < 0 ? scheme.snackBar.error : scheme.primary
        ),
        if (amount > 0) TextSmall(s.made_product_profit_margin(kitchenPercent(context, gain / amount * 100)), color: scheme.text.secondary)
      ]),
      SizedBox(height: AppSize.gap / 2),
      TextSmall(
        cost.complete ? s.made_product_profit_cost(kitchenMoney(cost.cost)) : s.made_product_profit_cost_floor(kitchenMoney(cost.cost)),
        color: scheme.text.secondary
      )
    ]);
  }
}
