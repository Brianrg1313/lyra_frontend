import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/inventory/product_date.dart';
import 'package:app/services/kitchen/kitchen_reports_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';
import 'package:app/screens/home/sections/_section/filter_chip.dart';
import 'package:app/screens/home/sections/_section/section_message.dart';

import './consumption_report.dart';
import './cost_report.dart';
import './variance_report.dart';

/// The reports tab (`cocina-frontend.md` §9): one report at a time — theoretical consumption,
/// variance, cost per dish — over a window of days the person types (both ends optional).
///
/// Variance is read from one count to the next: the natural flow is counting the stock at the
/// close (a `correction`) and opening this from the previous count's day.
class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  late final _from = InputController(key: "FROM", max: 10, initial: _day(context.read<KitchenReportsService>().from));
  late final _to = InputController(key: "TO", max: 10, initial: _day(context.read<KitchenReportsService>().to));
  String _error = "";

  static String? _day(DateTime? at) => at == null
    ? null
    : "${at.day.toString().padLeft(2, "0")}/${at.month.toString().padLeft(2, "0")}/${at.year}";

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final service = context.read<KitchenReportsService>();
      if (service.status == KitchenReportStatus.idle) service.load();
    });
  }

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    super.dispose();
  }

  void _apply() {
    final s = S.of(context);
    final from = _from.text.trim().isEmpty ? null : ProductDate.parse(_from.text)?.at;
    final to = _to.text.trim().isEmpty ? null : ProductDate.parse(_to.text)?.at;

    if ((_from.text.trim().isNotEmpty && from == null) || (_to.text.trim().isNotEmpty && to == null)) {
      return setState(() => _error = s.supply_chain_reports_day_invalid);
    }

    if (from != null && to != null && from.isAfter(to)) {
      return setState(() => _error = s.supply_chain_reports_window_invalid);
    }

    setState(() => _error = "");
    context.read<KitchenReportsService>().window(from: from, to: to);
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<KitchenReportsService>();
    final scheme = ThemeColor.of(context);
    final s = S.of(context);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: AppSize.gap, runSpacing: AppSize.gap, crossAxisAlignment: WrapCrossAlignment.center, children: [
        for (final report in KitchenReport.values) SectionFilterChip(
          title: _title(s, report),
          isActive: service.report == report,
          action: () => service.show(report)
        ),
        SizedBox(width: AppSize.spaceS),
        SizedBox(width: 130, child: Input(
          controller: _from,
          placeholder: s.supply_chain_reports_from,
          formatters: const [DateSeparatorFormatter()],
          buttonSpace: false
        )),
        SizedBox(width: 130, child: Input(
          controller: _to,
          placeholder: s.supply_chain_reports_to,
          formatters: const [DateSeparatorFormatter()],
          buttonSpace: false
        )),
        Button(title: s.supply_chain_reports_apply, width: null, action: _apply)
      ]),
      Padding(
        padding: EdgeInsets.symmetric(vertical: AppSize.spaceXS),
        child: TextSmall(
          _error.isNotEmpty ? _error : _note(s, service.report),
          lines: 2,
          color: _error.isNotEmpty ? scheme.snackBar.error : scheme.text.secondary
        )
      ),
      Expanded(child: _body(context, service))
    ]);
  }

  Widget _body(BuildContext context, KitchenReportsService service) {
    final s = S.of(context);

    return switch (service.status) {
      KitchenReportStatus.idle || KitchenReportStatus.loading => const Center(child: Loading()),
      KitchenReportStatus.error => SectionMessage(
        icon: CI.info,
        title: service.reason == "invalid_field" ? s.supply_chain_reports_window_invalid : s.supply_chain_reports_error,
        action: service.load,
        actionLabel: s.knowledge_retry
      ),
      KitchenReportStatus.empty => SectionMessage(
        icon: CI.chart,
        title: s.supply_chain_reports_empty,
        subtitle: service.report == KitchenReport.cost ? s.supply_chain_cost_empty_note : null
      ),
      KitchenReportStatus.ready => switch (service.report) {
        KitchenReport.consumption => ConsumptionReportView(report: service.consumption),
        KitchenReport.variance => VarianceReportView(rows: service.variance),
        KitchenReport.cost => CostReportView(dishes: service.cost)
      }
    };
  }

  static String _title(S s, KitchenReport report) => switch (report) {
    KitchenReport.consumption => s.supply_chain_reports_consumption,
    KitchenReport.variance => s.supply_chain_reports_variance,
    KitchenReport.cost => s.supply_chain_reports_cost
  };

  static String _note(S s, KitchenReport report) => switch (report) {
    KitchenReport.consumption => s.supply_chain_reports_consumption_note,
    KitchenReport.variance => s.supply_chain_reports_variance_note,
    KitchenReport.cost => s.supply_chain_reports_cost_note
  };
}
