import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/stock/summary/stock_summary_model.dart';

import './summary_layout.dart';
import './summary_line.dart';

/// The summary's header: what each column is called.
///
/// The names are the ones the company gave them, also the numbers': a table
/// calls its stock column "Quantity" and that's the word whoever loaded it
/// expects to read. The only ones this app writes are those without any column
/// behind them —reserved and performance, which the inventory carries and not
/// the table—, and that's why the backend sends them blank.
///
/// **A title orders its column** ([onSort]): a click from the largest value down,
/// the next one from the smallest up, a third one back to no order (the most
/// expensive is what's looked for first). The column the rows are ordered by ([sort]) says
/// so with an arrow beside its title. Columns with nothing to order by
/// ([StockSummaryColumn.sortable]) are plain titles.
class SummaryHeader extends StatelessWidget {
  const SummaryHeader({
    super.key,
    required this.layout,
    this.sort,
    this.onSort
  });

  final SummaryLayout layout;

  /// The order the rows are in, or null for the backend's own.
  final StockSummarySort? sort;

  /// Orders by the column of that key; null leaves every title still.
  final ValueChanged<String>? onSort;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: SummaryLayout.headerTitles,
    child: SummaryLine(
      padding: SummaryLayout.headerPadding,
      layout: layout,
      field: (column) => _title(
        column,
        column.name,
        SummaryLayout.alignsRight(column) ? TextAlign.right : TextAlign.left
      ),
      number: (column) => _title(
        column,
        _label(context, column),
        // The two counters that are touched carry the figure in the middle,
        // between their buttons, so their title does too: leaned to the right
        // it would sit on the add button and not on what it names.
        column.isStock || column.isReserved ? TextAlign.center : TextAlign.right
      )
    )
  );

  Widget _title(StockSummaryColumn column, String label, TextAlign align) =>
    _SortTitle(
      label: label,
      align: align,
      descending: sort?.key == column.key ? sort!.descending : null,
      onTap: onSort == null || !column.sortable ? null : () => onSort!(column.key)
    );

  /// What a numbers column is called: what the company wrote, or what that
  /// column is when there's nothing of its own behind it.
  String _label(BuildContext context, StockSummaryColumn column) {
    if (column.name.isNotEmpty) return column.name;

    return switch (column.key) {
      StockSummaryColumn.stockKey => S.of(context).stock_summary_stock,
      StockSummaryColumn.reservedKey => S.of(context).stock_summary_reserved,
      StockSummaryColumn.performanceKey =>
        S.of(context).stock_summary_performance,
      _ => ""
    };
  }
}

/// A column's title in the header, which orders the column when it can ([onTap]).
///
/// The arrow goes **beside** the title and not in place of anything: it says which
/// way the rows go (up: smallest first) and is the only mark of which column they
/// are ordered by. A long title gives way to it, not the other way round.
class _SortTitle extends StatelessWidget {
  const _SortTitle({
    required this.label,
    required this.align,
    this.descending,
    this.onTap
  });

  final String label;
  final TextAlign align;

  /// Which way the rows go by this column, or null if they aren't ordered by it.
  final bool? descending;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final active = descending != null;

    final title = Row(
      mainAxisAlignment: switch (align) {
        TextAlign.right => MainAxisAlignment.end,
        TextAlign.center => MainAxisAlignment.center,
        _ => MainAxisAlignment.start
      },
      children: [
        Flexible(child: TextSmall(
          label,
          ellipsis: true,
          textAlign: align,
          color: active ? scheme.text.primary : scheme.text.secondary
        )),
        if (active) ...[
          SizedBox(width: AppSize.spaceXS),
          Icon(
            descending! ? CI.arrow_down : CI.arrow_top,
            size: AppSize.text * 0.8,
            color: scheme.text.primary
          )
        ]
      ]
    );

    if (onTap == null) return title;

    return FocusableWidget(
      action: onTap,
      mouseCursor: SystemMouseCursors.click,
      child: title
    );
  }
}
