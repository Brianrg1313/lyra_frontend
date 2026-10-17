import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/stock/summary/stock_summary_model.dart';

import './summary_layout.dart';
import './summary_line.dart';
import './summary_sort_title.dart';

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
    SummarySortTitle(
      label: label,
      align: align,
      descending: sort?.key == column.key ? sort!.descending : null,
      onTap: onSort == null || !column.sortable ? null : () => onSort!(column.key)
    );

  /// What a numbers column is called: what the company wrote, or what that
  /// column is when there's nothing of its own behind it. The stock says what
  /// it is counted in, when its column declares it: «Stock (kg)».
  String _label(BuildContext context, StockSummaryColumn column) {
    final name = _name(context, column);

    return column.isStock && column.unit.isNotEmpty ? "$name (${column.unit})" : name;
  }

  String _name(BuildContext context, StockSummaryColumn column) {
    if (column.name.isNotEmpty) return column.name;

    return switch (column.key) {
      StockSummaryColumn.stockKey => S.of(context).stock_summary_stock,
      StockSummaryColumn.reservedKey => S.of(context).stock_summary_reserved,
      StockSummaryColumn.transitKey => S.of(context).stock_summary_transit,
      StockSummaryColumn.performanceKey =>
        S.of(context).stock_summary_performance,
      _ => ""
    };
  }
}
