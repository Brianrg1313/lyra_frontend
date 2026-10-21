import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/home/sections/_sections.dart';
import 'package:app/screens/home/sections/dashboard/widgets/usage_bar.dart';
import './summary_card.dart';

/// **The home's summary**, beside the assistant: what a glance should tell
/// (today's sales, what waits, who is in, what the subscription has used and
/// what is running out), each card opening the section it summarises.
///
/// **Placeholder**: every figure is [_Sample]'s, and the header says so. Each
/// card is fed by its service once the reads exist (sales board, chats,
/// presence, shipments, billing usage, stock summary).
class SummaryPanel extends StatelessWidget {
  const SummaryPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final money = ChartFormat.currency(compact: false, decimals: 2);

    void open(HomeSection section) => Navis.navigate(section.path);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(AppSize.gap, AppSize.spaceXS, AppSize.gap, AppSize.spaceXS),
          child: Row(children: [
            Expanded(child: TextMedium(s.dashboard_summary_title, multiplier: 1.4, bold: true, ellipsis: true)),
            TextSmall(s.dashboard_summary_sample, color: scheme.text.secondary)
          ])
        ),
        Expanded(child: ScrollableWidget(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StatTile(
              label: s.dashboard_sales_today,
              value: _Sample.salesToday,
              format: money,
              delta: _Sample.salesDelta,
              deltaLabel: s.dashboard_vs_last_week,
              trend: _Sample.salesTrend,
              icon: CI.sale,
              onTap: () => open(HomeSection.sales)
            ),
            SizedBox(height: AppSize.gap),
            _Pair(
              SummaryTile(
                icon: CI.chat,
                value: "${_Sample.newMessages}",
                label: s.dashboard_new_messages,
                color: scheme.chart.at(1),
                onTap: () => open(HomeSection.messages)
              ),
              SummaryTile(
                icon: CI.employee,
                value: "${_Sample.online}",
                label: s.dashboard_online_employees,
                caption: s.dashboard_online_of(_Sample.people),
                color: scheme.chart.good,
                live: true,
                onTap: () => open(HomeSection.employees)
              )
            ),
            SizedBox(height: AppSize.gap),
            _Pair(
              SummaryTile(
                icon: CI.delivery,
                value: "${_Sample.deliveries}",
                label: s.dashboard_pending_deliveries,
                color: scheme.chart.at(3),
                onTap: () => open(HomeSection.deliveries)
              ),
              SummaryTile(
                icon: CI.receipt,
                value: "${_Sample.salesInProcess}",
                label: s.dashboard_open_sales,
                color: scheme.chart.at(4),
                onTap: () => open(HomeSection.sales)
              )
            ),
            SizedBox(height: AppSize.gap),
            SummaryCard(
              icon: CI.wallet,
              title: s.dashboard_subscription_title,
              trailing: s.dashboard_subscription_renews(_Sample.renewsIn),
              child: Column(children: [
                _Usage(label: s.dashboard_usage_ai, used: money(_Sample.creditsUsed), total: money(_Sample.creditsTotal), fraction: _Sample.creditsUsed / _Sample.creditsTotal),
                _Usage(label: s.dashboard_usage_conversations, used: "${_Sample.conversationsUsed}", total: "${_Sample.conversationsTotal}", fraction: _Sample.conversationsUsed / _Sample.conversationsTotal),
                _Usage(label: s.dashboard_usage_storage, used: "${_Sample.storageUsed} GB", total: "${_Sample.storageTotal} GB", fraction: _Sample.storageUsed / _Sample.storageTotal)
              ])
            ),
            SizedBox(height: AppSize.gap),
            SummaryCard(
              icon: CI.inventory,
              title: s.dashboard_low_stock_title,
              onMore: () => open(HomeSection.inventory),
              child: Column(children: [
                _Stock(name: s.dashboard_sample_product_1, left: 4, of: 50),
                _Stock(name: s.dashboard_sample_product_2, left: 9, of: 50),
                _Stock(name: s.dashboard_sample_product_3, left: 15, of: 50)
              ])
            )
          ]
        ))
      ]
    );
  }
}

/// Example figures, all in one place so wiring the real reads is a matter of
/// replacing this class.
abstract final class _Sample {
  static const double salesToday = 1284.5;
  static const double salesDelta = 12.4;
  static const List<double> salesTrend = [120, 180, 160, 240, 310, 280, 360, 420];
  static const int newMessages = 23;
  static const int online = 4;
  static const int people = 12;
  static const int deliveries = 8;
  static const int salesInProcess = 5;
  static const int renewsIn = 11;
  static const double creditsUsed = 34.2;
  static const double creditsTotal = 50;
  static const int conversationsUsed = 412;
  static const int conversationsTotal = 1000;
  static const double storageUsed = 2.1;
  static const double storageTotal = 5;
}

/// Two tiles side by side, the same height.
class _Pair extends StatelessWidget {
  const _Pair(this.left, this.right);

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: left),
      SizedBox(width: AppSize.gap),
      Expanded(child: right)
    ]
  );
}

/// What a plan has used: the bar fills as it is spent and warms up near the
/// limit.
class _Usage extends StatelessWidget {
  const _Usage({required this.label, required this.used, required this.total, required this.fraction});

  final String label;
  final String used;
  final String total;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return UsageBar(
      label: label,
      caption: S.of(context).dashboard_usage_of(used, total),
      value: fraction,
      color: fraction >= 0.9
        ? scheme.chart.critical
        : fraction >= 0.7 ? scheme.chart.warning : scheme.primary
    );
  }
}

/// A product running out: what is left against its usual stock.
class _Stock extends StatelessWidget {
  const _Stock({required this.name, required this.left, required this.of});

  final String name;
  final int left;
  final int of;

  @override
  Widget build(BuildContext context) {
    final chart = ThemeColor.of(context).chart;
    final fraction = left / of;

    return UsageBar(
      label: name,
      caption: S.of(context).dashboard_units_left(left),
      value: fraction,
      color: fraction < 0.15 ? chart.critical : chart.warning
    );
  }
}
