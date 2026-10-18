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
///
/// Each row carries its percent as a [VarianceBar] on one shared scale (the largest one in the
/// window): read top to bottom, the report is where the supply went missing, and how much more
/// one went than the next, before any figure is read.
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
      (title: "", flex: 3),
      (title: s.supply_chain_reports_actual, flex: 2),
      (title: s.supply_chain_reports_theoretical, flex: 2),
      (title: s.supply_chain_reports_variance_column, flex: 2),
      (title: "%", flex: 1)
    ];
    final detail = <ReportColumn>[(title: "", flex: 6), (title: "", flex: 2)];

    final scale = widget.rows
      .where((row) => row.counted && row.percent != null)
      .fold<double>(0, (largest, row) => row.percent!.abs() > largest ? row.percent!.abs() : largest);

    String qty(double value) => kitchenQty(context, value);

    return ListView(children: [
      ReportHeader(columns: columns),
      for (final row in widget.rows) Padding(
        padding: EdgeInsets.only(bottom: AppSize.gap / 2),
        child: ReportRow(
          columns: columns,
          muted: !row.counted,
          trailing: row.counted ? null : RecipeTag(text: s.supply_chain_reports_not_counted, color: scheme.text.secondary),
          graphics: {1: VarianceBar(percent: row.counted ? row.percent : null, scale: scale)},
          cells: [
            row.name.isEmpty ? row.productId : row.name,
            "",
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

/// A supply's variance on a line centred on zero: to the right ([ChartScheme.divergingHigh]) what
/// went missing that nobody recorded, to the left ([ChartScheme.divergingLow]) what is left over
/// beyond what the records explain (a delivery not entered, a miscount). [scale] is the largest
/// percent of the report, the full half; with no [percent] (no count, nothing theoretical) only
/// the zero line is drawn, never an empty bar that reads as 0 %.
///
/// It grows from zero when the report arrives, so a new window shows what moved.
class VarianceBar extends StatelessWidget {
  const VarianceBar({super.key, required this.percent, required this.scale});

  final double? percent;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final chart = ThemeColor.of(context).chart;
    final value = percent;
    final share = value == null || scale <= 0 ? 0.0 : (value.abs() / scale).clamp(0.0, 1.0);
    final color = (value ?? 0) >= 0 ? chart.divergingHigh : chart.divergingLow;
    final height = AppSize.gap * 1.5;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS),
      child: SizedBox(height: height, child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: share),
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        builder: (context, grown, _) => Row(children: [
          Expanded(child: Align(
            alignment: Alignment.centerRight,
            child: FractionallySizedBox(widthFactor: (value ?? 0) < 0 ? grown : 0, child: _bar(color, height, left: true))
          )),
          Container(width: 1, height: height, color: chart.axis),
          Expanded(child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(widthFactor: (value ?? 0) >= 0 ? grown : 0, child: _bar(color, height, left: false))
          ))
        ])
      ))
    );
  }

  /// Square at the zero line, rounded at its end: the end is the figure.
  Widget _bar(Color color, double height, {required bool left}) {
    final round = Radius.circular(height / 2);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.horizontal(left: left ? round : Radius.zero, right: left ? Radius.zero : round)
      )
    );
  }
}
