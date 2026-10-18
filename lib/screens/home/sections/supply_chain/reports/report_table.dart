import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// One column of a kitchen report: its title and how much of the row's width it takes. The
/// first one is the name, left; the rest are figures, right.
typedef ReportColumn = ({String title, int flex});

/// The header of a report's rows, with the same geometry as [ReportRow].
class ReportHeader extends StatelessWidget {
  const ReportHeader({super.key, required this.columns});

  final List<ReportColumn> columns;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS, vertical: AppSize.gap),
    child: Row(children: [
      for (final (index, column) in columns.indexed) Expanded(
        flex: column.flex,
        child: TextSmall(
          column.title,
          bold: true,
          ellipsis: true,
          textAlign: index == 0 ? TextAlign.start : TextAlign.end,
          color: ThemeColor.of(context).text.secondary
        )
      )
    ])
  );
}

/// One row of a report: [cells] laid out on [columns]; [muted] greys it (a supply with no count).
/// With [onTap] it unfolds [details] under it. A column in [graphics] is drawn by its widget
/// instead of its text (the variance's bar).
class ReportRow extends StatelessWidget {
  const ReportRow({
    super.key,
    required this.columns,
    required this.cells,
    this.muted = false,
    this.onTap,
    this.open = false,
    this.details = const [],
    this.trailing,
    this.graphics = const {}
  });

  final List<ReportColumn> columns;
  final List<String> cells;
  final bool muted;
  final void Function()? onTap;
  final bool open;
  final List<Widget> details;

  /// Beside the name: a tag.
  final Widget? trailing;

  /// By column index.
  final Map<int, Widget> graphics;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final color = muted ? scheme.text.secondary : null;

    final row = Row(children: [
      for (final (index, column) in columns.indexed) Expanded(
        flex: column.flex,
        child: graphics[index] ?? (index == 0
          ? Row(children: [
              if (onTap != null) Icon(open ? CI.arrow_down : CI.arrow_right, size: AppSize.text, color: scheme.text.secondary),
              if (onTap != null) SizedBox(width: AppSize.gap),
              Flexible(child: TextSmall(index < cells.length ? cells[index] : "", ellipsis: true, bold: true, color: color)),
              if (trailing != null) ...[SizedBox(width: AppSize.gap), trailing!]
            ])
          : TextSmall(index < cells.length ? cells[index] : "", ellipsis: true, textAlign: TextAlign.end, color: color))
      )
    ]);

    final padding = EdgeInsets.symmetric(horizontal: AppSize.spaceS, vertical: AppSize.spaceXS);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (onTap == null)
        Surface.over(padding: padding, child: row)
      else
        FeedbackButton(action: onTap!, color: scheme.surfaceOver, padding: padding, child: row),
      if (open) ...details
    ]);
  }
}

/// A row under an unfolded one: indented, lighter.
class ReportDetail extends StatelessWidget {
  const ReportDetail({super.key, required this.columns, required this.cells, this.color});

  final List<ReportColumn> columns;
  final List<String> cells;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(AppSize.spaceL, AppSize.gap, AppSize.spaceS, AppSize.gap),
    child: Row(children: [
      for (final (index, column) in columns.indexed) Expanded(
        flex: column.flex,
        child: TextSmall(
          index < cells.length ? cells[index] : "",
          ellipsis: true,
          textAlign: index == 0 ? TextAlign.start : TextAlign.end,
          color: color ?? ThemeColor.of(context).text.secondary
        )
      )
    ])
  );
}
