import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// The register's face: every figure of the summary is set in it, the one
/// trait the sheet is recognised by.
const TextFont _figures = TextFont.bebas;

/// Today's sales, the sheet's lead: the amount as large as the panel allows,
/// how it compares, and the day's curve under it.
class SummarySales extends StatelessWidget {
  const SummarySales({
    super.key,
    required this.value,
    required this.delta,
    required this.trend,
    this.onTap
  });

  /// Already formatted as money.
  final String value;

  /// Change against the same day last week, in percent.
  final double delta;
  final List<double> trend;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final up = delta >= 0;
    final tint = up ? scheme.chart.good : scheme.chart.critical;

    return FeedbackButton(
      action: onTap,
      radius: AppSize.cornerInset(AppSize.gap),
      padding: EdgeInsets.all(AppSize.spaceS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextMedium(s.dashboard_sales_today, color: scheme.text.secondary),
          TextMedium(value, font: _figures, multiplier: 5, ellipsis: true),
          Row(children: [
            Icon(up ? CI.arrow_top : CI.arrow_down, size: AppSize.text * 0.8, color: tint),
            TextSmall("${up ? "+" : ""}${ChartFormat.separated(delta, decimals: 1)}%", color: tint, bold: true),
            SizedBox(width: AppSize.gap),
            Flexible(child: TextSmall(s.dashboard_vs_last_week, color: scheme.text.secondary, ellipsis: true))
          ]),
          SizedBox(height: AppSize.spaceS),
          Sparkline(values: trend, height: AppSize.picture, color: scheme.text.primary)
        ]
      )
    );
  }
}

/// One count of what waits or is happening: the figure in front, what it
/// counts beside it. [live] marks something happening now (people online).
class SummaryCount extends StatelessWidget {
  const SummaryCount({
    super.key,
    required this.value,
    required this.label,
    this.caption,
    this.live = false,
    this.onTap
  });

  final int value;
  final String label;
  final String? caption;
  final bool live;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return FeedbackButton(
      action: onTap,
      radius: AppSize.cornerInset(AppSize.gap),
      padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS, vertical: AppSize.gap),
      child: Row(children: [
        // A column at least this wide: the labels start together, and a long
        // figure pushes them instead of overflowing.
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: AppSize.picture * 1.2),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            TextMedium("$value", font: _figures, multiplier: 2.6),
            if (live) Padding(
              padding: EdgeInsets.only(left: AppSize.gap),
              child: Container(
                width: AppSize.gap * 1.4,
                height: AppSize.gap * 1.4,
                decoration: BoxDecoration(color: scheme.chart.good, shape: BoxShape.circle)
              )
            ),
            SizedBox(width: AppSize.spaceXS)
          ])
        ),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextMedium(label, ellipsis: true),
            if (caption != null) TextSmall(caption!, color: scheme.text.secondary, ellipsis: true)
          ]
        )),
        Icon(CI.arrow_right, size: AppSize.text, color: scheme.text.secondary)
      ])
    );
  }
}

/// A titled part of the sheet: its title, a note or "View all" on the right
/// ([note], [onMore]), then its rows.
class SummaryBlock extends StatelessWidget {
  const SummaryBlock({
    super.key,
    required this.title,
    required this.children,
    this.note,
    this.onMore
  });

  final String title;
  final List<Widget> children;

  /// Beside the title (when it renews).
  final String? note;

  /// Opens the section the block summarises.
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS, vertical: AppSize.gap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: AppSize.button,
            child: Row(children: [
              Expanded(child: TextMedium(title, bold: true, ellipsis: true)),
              if (note != null) TextSmall(note!, color: scheme.text.secondary),
              if (onMore != null) FeedbackButton(
                action: onMore,
                radius: AppSize.cornerInset(AppSize.gap),
                padding: EdgeInsets.symmetric(horizontal: AppSize.gap * 1.4, vertical: AppSize.gap),
                child: TextSmall(S.of(context).dashboard_view_all, color: scheme.text.primary, bold: true)
              )
            ])
          ),
          ...children
        ]
      )
    );
  }
}

/// Between the sheet's parts.
class SummaryRule extends StatelessWidget {
  const SummaryRule({super.key});

  @override
  Widget build(BuildContext context) => Separator.horizontal(
    margin: EdgeInsets.symmetric(horizontal: AppSize.spaceS, vertical: AppSize.spaceXS)
  );
}
