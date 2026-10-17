import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/kitchen/kitchen_report_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/supply_chain/kitchen_format.dart';
import 'package:app/screens/home/sections/supply_chain/recipes/recipe_row.dart';

import './report_table.dart';

/// Variance, the largest first: what really left (opening + received − sent − closing) against
/// what the recipes, the direct sales and the recorded losses explain. Positive is missing
/// supply nobody recorded. A supply with no count in the window is grey and says so: its 0 is
/// not a 0 %. Unfolding a row shows how its figure is made.
class VarianceReportView extends StatefulWidget {
  const VarianceReportView({super.key, required this.rows});

  final List<VarianceRow> rows;

  @override
  State<VarianceReportView> createState() => _VarianceReportViewState();
}

class _VarianceReportViewState extends State<VarianceReportView> {
  final Set<String> _open = {};

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);
    final columns = <ReportColumn>[
      (title: s.supply_chain_reports_supply, flex: 4),
      (title: s.supply_chain_reports_actual, flex: 2),
      (title: s.supply_chain_reports_theoretical, flex: 2),
      (title: s.supply_chain_reports_variance_column, flex: 2),
      (title: "%", flex: 1)
    ];
    final detail = <ReportColumn>[(title: "", flex: 6), (title: "", flex: 2)];

    String qty(double value) => kitchenQty(context, value);

    return ListView(children: [
      ReportHeader(columns: columns),
      for (final row in widget.rows) Padding(
        padding: EdgeInsets.only(bottom: AppSize.gap / 2),
        child: ReportRow(
          columns: columns,
          muted: !row.counted,
          trailing: row.counted ? null : RecipeTag(text: s.supply_chain_reports_not_counted, color: scheme.text.secondary),
          cells: [
            row.name.isEmpty ? row.productId : row.name,
            qty(row.actual),
            qty(row.theoretical),
            row.counted ? qty(row.variance) : "—",
            row.counted && row.percent != null ? kitchenPercent(context, row.percent!) : "—"
          ],
          open: _open.contains(row.productId),
          onTap: () => setState(() {
            if (!_open.remove(row.productId)) _open.add(row.productId);
          }),
          details: [
            for (final (label, value) in [
              (s.supply_chain_reports_opening, row.opening),
              (s.supply_chain_reports_received, row.received),
              (s.supply_chain_reports_sent, row.sent),
              (s.supply_chain_reports_closing, row.closing),
              (s.supply_chain_reports_sold, row.sold),
              (s.supply_chain_reports_lost, row.lost)
            ]) ReportDetail(columns: detail, cells: [label, qty(value)])
          ]
        )
      )
    ]);
  }
}
