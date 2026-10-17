import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/kitchen/kitchen_report_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/supply_chain/kitchen_format.dart';

import './report_table.dart';

/// Theoretical consumption: one row per supply (used, the part of it that is the recipes' waste,
/// what went into lost dishes), unfolding into the dishes and batches that spent it; then the
/// batches made and what was lost of them.
class ConsumptionReportView extends StatefulWidget {
  const ConsumptionReportView({super.key, required this.report});

  final ConsumptionReport report;

  @override
  State<ConsumptionReportView> createState() => _ConsumptionReportViewState();
}

class _ConsumptionReportViewState extends State<ConsumptionReportView> {
  final Set<String> _open = {};

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final columns = <ReportColumn>[
      (title: s.supply_chain_reports_supply, flex: 4),
      (title: s.supply_chain_reports_used, flex: 2),
      (title: s.supply_chain_reports_waste, flex: 2),
      (title: s.supply_chain_reports_spoiled, flex: 2)
    ];
    final batches = <ReportColumn>[
      (title: s.supply_chain_reports_batch, flex: 4),
      (title: s.supply_chain_reports_produced, flex: 2),
      (title: s.supply_chain_reports_lost, flex: 2)
    ];
    final report = widget.report;

    String qty(double value) => kitchenQty(context, value);

    return ListView(children: [
      if (report.supplies.isNotEmpty) ReportHeader(columns: columns),
      for (final supply in report.supplies) Padding(
        padding: EdgeInsets.only(bottom: AppSize.gap / 2),
        child: ReportRow(
          columns: columns,
          cells: [supply.name.isEmpty ? supply.productId : supply.name, qty(supply.used), qty(supply.waste), qty(supply.spoiled)],
          open: _open.contains(supply.productId),
          onTap: supply.dishes.isEmpty ? null : () => setState(() {
            if (!_open.remove(supply.productId)) _open.add(supply.productId);
          }),
          details: [
            for (final dish in supply.dishes) ReportDetail(
              columns: columns,
              cells: [dish.name.isEmpty ? dish.productId : dish.name, qty(dish.used), qty(dish.waste), qty(dish.spoiled)]
            )
          ]
        )
      ),
      if (report.batches.isNotEmpty) ...[
        SizedBox(height: AppSize.spaceS),
        ReportHeader(columns: batches),
        for (final batch in report.batches) Padding(
          padding: EdgeInsets.only(bottom: AppSize.gap / 2),
          child: ReportRow(
            columns: batches,
            cells: [batch.name.isEmpty ? batch.productId : batch.name, qty(batch.produced), qty(batch.lost)]
          )
        )
      ]
    ]);
  }
}
