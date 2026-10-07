import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/catalog/currency_model.dart';
import 'package:app/services/stock/summary/stock_summary_model.dart';

// WIDGETS
import 'package:app/screens/modals/inventory/stock_movement/movement_shape.dart';

import 'summary_layout.dart';
import 'summary_stepper.dart';
import 'summary_value.dart';

/// The summary's header: what each column is called.
///
/// The names are the ones the company gave them, also the numbers': a table
/// calls its stock column "Quantity" and that's the word whoever loaded it
/// expects to read. The only ones this app writes are those without any column
/// behind them —reserved and performance, which the inventory carries and not
/// the table—, and that's why the backend sends them blank.
///
/// **A title orders its column** ([onSort]): a click from the smallest value up,
/// the next one the other way. The column the rows are ordered by ([sort]) says
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

/// A row of the summary: a product.
///
/// It's read left to right as one looks for a product: the photo, with what
/// it's recognized by; the columns with which the company describes it; and at
/// the end the numbers, which are the question this list answers.
///
/// **The row isn't touched; its numbers are.** Stock and reserved carry their
/// two buttons (see [SummaryStepper]) and are the only thing of the row that
/// responds: what brings someone here is looking at how much is left and
/// correcting it on the spot, not opening the product. That the whole row were
/// a button, besides, left every movement one pixel away from going to another
/// screen.
class SummaryProductRow extends StatelessWidget {
  const SummaryProductRow({
    super.key,
    required this.row,
    required this.layout,
    required this.currency,
    this.zebra = false
  });

  final StockSummaryRow row;
  final SummaryLayout layout;

  /// If this row goes on the zebra's painted band.
  ///
  /// The list decides it by position, not the row by what it brings: the zebra
  /// is there to follow a long row left to right without switching lines, and
  /// for that it has to alternate evenly.
  final bool zebra;

  /// The company's currency, already resolved. It comes down from the panel so
  /// all rows read it with a single subscription.
  final CurrencyModel currency;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Container(
      // The zebra, with the two colors the scheme has for that: any row goes
      // over `table.background` —which is the same background the section rests
      // on, so it doesn't look like a box— and the one next to it over
      // `table.even`, which exists precisely to distinguish it from its
      // neighbors. It's the same zebra as the spreadsheet (see `SheetStyle`):
      // opening a product's table shouldn't change the list's look.
      height: SummaryLayout.rowHeight,
      padding: EdgeInsets.symmetric(horizontal: AppSize.gap),
      decoration: BoxDecoration(
        color: zebra ? scheme.table.even : scheme.table.background,
        borderRadius: BorderRadius.circular(AppSize.corner)
      ),
      child: SummaryLine(
        layout: layout,
        image: SummaryPicture(row: row),
        field: (column) => SummaryValue(
          column: column,
          raw: row[column.key],
          currency: currency
        ),
        number: _number
      )
    );
  }

  /// One of the three numbers columns.
  ///
  /// The two inventory ones are drawn with their buttons; performance, which
  /// isn't measured yet, is a figure and nothing more.
  ///
  /// The buttons need **both** numbers —a reservation's cap is set by stock,
  /// not by what's already reserved— so a row missing either falls to the bare
  /// figure. It doesn't happen today: the summary answers both counters in any
  /// table, whether or not it has a stock column.
  Widget _number(StockSummaryColumn column) {
    final stock = row.stock;
    final reserved = row.reserved;

    final counter = switch (column.key) {
      StockSummaryColumn.stockKey => StockCounter.stock,
      StockSummaryColumn.reservedKey => StockCounter.reserved,
      _ => null
    };

    if (counter == null || stock == null || reserved == null) {
      return SummaryNumber(
        value: switch (column.key) {
          StockSummaryColumn.stockKey => stock,
          StockSummaryColumn.reservedKey => reserved,
          // Performance isn't measured yet: the column is there, the value
          // isn't.
          _ => null
        },
        // Only stock alerts on zero: it's what can't be sold. Zero reserved is
        // normal in almost all products.
        alert: column.isStock
      );
    }

    return SummaryStepper(
      productId: row.id,
      counter: counter,
      stock: stock,
      reserved: reserved
    );
  }
}

/// The skeleton of a summary row, which is the same for the header and for the
/// products: if both weren't drawn with the same distribution, each title would
/// land over the wrong column.
///
/// The text columns share the leftover width in proportion to how wide they
/// were left in the spreadsheet ([SummaryLayout.flexOf]); the photo, the numbers
/// and the short columns ([SummaryLayout.widthOf]) measure their own.
class SummaryLine extends StatelessWidget {
  const SummaryLine({
    super.key,
    required this.layout,
    required this.field,
    required this.number,
    this.image,
    this.padding
  });

  final SummaryLayout layout;

  /// What goes in the photo column, or null if nothing goes. The header leaves
  /// it empty: a photos column doesn't need to be told what it is.
  final Widget? image;

  final Widget Function(StockSummaryColumn column) field;
  final Widget Function(StockSummaryColumn column) number;

  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(width: SummaryLayout.gap);

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Row(children: [
        if (layout.image != null) ...[
          SizedBox(
            width: SummaryLayout.imageSize,
            // Square only when there's a photo to put. In the header this
            // column is nothing but a reserved place so the titles land on the
            // column they name, and giving it a photo's height there would
            // stretch the header to the height of a whole row —or, with a
            // smaller declared height, squash it to half.
            height: image == null ? null : SummaryLayout.imageSize,
            child: image
          ),
          gap
        ],
        for (final column in layout.fields) ...[
          if (SummaryLayout.widthOf(column) case final width?)
            SizedBox(width: width, child: field(column))
          else
            Expanded(flex: SummaryLayout.flexOf(column), child: field(column)),
          gap
        ],
        // A table can have no text column in the summary (none chosen yet, or
        // only short ones like a price and a code): the leftover is filled by the
        // air, so the numbers don't shift to the middle.
        if (!layout.hasFlexible) const Spacer(),
        for (final column in layout.numbers) ...[
          SizedBox(width: SummaryLayout.numberWidth, child: number(column)),
          if (column != layout.numbers.last) gap
        ]
      ])
    );
  }
}
