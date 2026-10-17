import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/kitchen/kitchen_report_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/supply_chain/kitchen_format.dart';

/// What the product earns, beside its price: the price as it is being typed, less what making it
/// costs at the average price paid for its supplies (`POST /recipes/cost`, `cocina-frontend.md`
/// §9). Nothing to fill: it is read, and it moves with the price.
///
/// The cost is the saved recipe's, so a new product has none yet; a supply never bought with a
/// cost is left out and named, since the figure is then a floor.
class MadeProfit extends StatelessWidget {
  const MadeProfit({super.key, required this.price, required this.cost, required this.saved});

  /// The price field's text.
  final TextEditingController price;

  /// `null` while it is read, or when it can't be told.
  final DishCost? cost;

  /// Whether the product exists: a new one has no recipe to cost.
  final bool saved;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: price,
    builder: (context, _) => _build(context)
  );

  Widget _build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);
    final cost = this.cost;

    // A cost of nothing with nothing priced says nothing yet.
    if (cost == null || (!cost.complete && cost.cost == 0)) {
      return TextSmall(saved ? s.made_product_profit_none : s.made_product_profit_new, lines: 3, color: scheme.text.secondary);
    }

    final amount = kitchenParse(price.text) ?? 0;
    final gain = amount - cost.cost;
    final missing = [
      for (final line in cost.lines)
        if (line.unitCost == null) line.name.isEmpty ? line.productId : line.name
    ];

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
      TextSmall(s.made_product_profit_cost(kitchenMoney(cost.cost)), color: scheme.text.secondary),
      if (missing.isNotEmpty) TextSmall(s.made_product_profit_incomplete(missing.join(", ")), lines: 2, color: scheme.text.secondary)
    ]);
  }
}
