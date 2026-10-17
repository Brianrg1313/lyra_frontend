import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/kitchen/kitchen_report_model.dart';
import 'package:app/services/kitchen/recipe_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/supply_chain/kitchen_format.dart';
import 'package:app/screens/home/sections/supply_chain/recipes/recipe_row.dart';

import './report_table.dart';

/// Cost per dish: what making each one costs at the average price paid for its supplies, in
/// every branch (the last 90 days unless a window says otherwise). A dish with a supply never
/// bought with a cost is marked incomplete — its figure is a floor — and that line says it has
/// no price. Modifiers are not in it.
class CostReportView extends StatefulWidget {
  const CostReportView({super.key, required this.dishes});

  final List<DishCost> dishes;

  @override
  State<CostReportView> createState() => _CostReportViewState();
}

class _CostReportViewState extends State<CostReportView> {
  final Set<String> _open = {};

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);
    final columns = <ReportColumn>[
      (title: s.supply_chain_reports_dish, flex: 5),
      (title: s.supply_chain_reports_cost_column, flex: 2)
    ];
    final lines = <ReportColumn>[
      (title: "", flex: 3),
      (title: "", flex: 2),
      (title: "", flex: 2),
      (title: "", flex: 2)
    ];

    return ListView(children: [
      ReportHeader(columns: columns),
      for (final dish in widget.dishes) Padding(
        padding: EdgeInsets.only(bottom: AppSize.gap / 2),
        child: ReportRow(
          columns: columns,
          cells: [dish.name.isEmpty ? dish.productId : dish.name, kitchenMoney(dish.cost)],
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            RecipeTag(
              text: dish.mode == RecipeMode.batch ? s.supply_chain_mode_batch : s.supply_chain_mode_order,
              color: scheme.text.secondary
            ),
            if (!dish.complete) ...[
              SizedBox(width: AppSize.gap),
              RecipeTag(text: s.supply_chain_reports_incomplete, color: scheme.snackBar.alert)
            ]
          ]),
          open: _open.contains(dish.productId),
          onTap: dish.lines.isEmpty ? null : () => setState(() {
            if (!_open.remove(dish.productId)) _open.add(dish.productId);
          }),
          details: [
            for (final line in dish.lines) ReportDetail(
              columns: lines,
              color: line.unitCost == null ? scheme.snackBar.alert : null,
              cells: [
                line.name.isEmpty ? line.productId : line.name,
                kitchenQty(context, line.qty),
                line.unitCost == null ? s.supply_chain_reports_no_price : s.supply_chain_reports_each(kitchenMoney(line.unitCost!)),
                line.cost == null ? "—" : kitchenMoney(line.cost!)
              ]
            )
          ]
        )
      )
    ]);
  }
}
