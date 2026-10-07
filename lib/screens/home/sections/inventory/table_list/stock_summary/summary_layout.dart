import 'package:flutter/widgets.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/inventory/table_field_type.dart';
import 'package:app/services/stock/summary/stock_summary_model.dart';

/// How the width of a stock summary row is distributed.
///
/// The summary arrives as a table —the photo, the columns the company left, and
/// the three numbers— but here it isn't drawn as a spreadsheet: it's a list
/// below the tables grid, on the same scroll, so it can't have its own
/// horizontal scroll nor draggable columns. What it does is **distribute
/// whatever width there is**: the photo, the numbers and the short columns
/// ([widthOf]: a price, a code, a date) measure what their values measure, and the
/// texts take the rest, each in proportion to how wide they were left in the
/// spreadsheet.
///
/// That's also why **columns are left over**. A table can have ten columns in
/// the summary and on a phone not even two fit: the first ones are shown, which
/// are the ones the company put up front when arranging them, and the rest are
/// seen by opening the table. It's better to show fewer readable columns than
/// all of them cut to three letters.
class SummaryLayout {
  const SummaryLayout._({
    required this.image,
    required this.fields,
    required this.numbers
  });

  /// The photo column, or null if this response doesn't bring it.
  final StockSummaryColumn? image;

  /// The table's own columns that fit, in the order the company arranged them.
  final List<StockSummaryColumn> fields;

  /// The numbers that close the row (`stock`, `reserved`, `performance`), the
  /// ones that fit.
  final List<StockSummaryColumn> numbers;

  /// How much a row measures: the photo plus its air, above and below. Set by
  /// the photo's height and not the text, which is the tallest thing a row
  /// carries.
  static double get rowHeight => AppSize.action + AppSize.gap * 2;

  /// The air of the column header. **Deliberately uneven**: more below than
  /// above.
  ///
  /// Stuck at the very top, the header is the only thing between the action bar
  /// and the rows passing below, and with just the air of a small-text row it
  /// looks like too thin a strip. The bottom one is the one that needs
  /// enlarging: it's what separates it from the first row.
  ///
  /// Its sides are a row's ([rowPadding]): with less width than the rows, the
  /// header ran out of room before them and its titles sat off their columns.
  static EdgeInsets get headerPadding => EdgeInsets.fromLTRB(
    rowPadding.left, AppSize.gap,
    rowPadding.right, AppSize.spaceXS
  );

  /// The air on the sides of a row, and of the header ([headerPadding]).
  static EdgeInsets get rowPadding => EdgeInsets.symmetric(horizontal: AppSize.gap);

  /// How much the title row occupies, with its air and without the bottom line.
  ///
  /// The header **plants itself at this height** instead of measuring what its
  /// letters occupy: a number that imposes itself is the same with any font, so
  /// the header never comes out squashed over the rows.
  static double get headerTitles => AppSize.text * 1.4 + headerPadding.vertical;

  /// How much the whole header measures: the title row and the line that
  /// separates it from the first row.
  static double get headerHeight => headerTitles + 1;

  /// The thumbnail's side, which is also its column's width.
  static double get imageSize => AppSize.action;

  /// What a numbers column measures. It's fixed and the same for all three:
  /// they're for comparing top to bottom, and with different widths the figures
  /// wouldn't stay aligned between columns.
  ///
  /// It measures more than a figure because two of the three aren't just a
  /// figure: stock and reserved carry on their sides the buttons they're moved
  /// with (see `SummaryStepper`). Performance, which isn't touched yet, takes
  /// the same width anyway: it's what keeps the three columns aligned.
  static double get numberWidth => AppSize.action * 2.6;

  /// The side of each of a counter's two buttons. Square and the height of a
  /// text row: two fit in a row that measures what a thumbnail measures, and
  /// they leave the middle of the column for the figure, which is what you come
  /// to read.
  static double get stepSize => AppSize.text * 1.9;

  /// The air between one column and the next.
  static double get gap => AppSize.spaceS;

  /// The width of a column whose values have a length of their own, or null for a text,
  /// which takes its share of what is left ([flexOf]).
  ///
  /// A price is two to twelve figures with its symbol, a code a dozen characters and a
  /// date always the same: given a share like a name's, they were drawn as a few figures
  /// lost in a wide column while the name beside them was being cut. Measured in the
  /// text's size, so they keep fitting what they hold at any font size; a value longer
  /// than its column (a twenty-character code) is cut like any other.
  static double? widthOf(StockSummaryColumn column) => switch (column.type) {
    TableFieldType.boolean => AppSize.text * 4.5,
    TableFieldType.number ||
    TableFieldType.decimal ||
    TableFieldType.counter ||
    TableFieldType.discount ||
    TableFieldType.percentage => AppSize.text * 6,
    TableFieldType.price ||
    TableFieldType.currency ||
    TableFieldType.measure => AppSize.text * 8,
    TableFieldType.date => AppSize.text * 7.5,
    TableFieldType.datetime => AppSize.text * 9.5,
    TableFieldType.sku ||
    TableFieldType.barcode ||
    TableFieldType.phone => AppSize.text * 10,
    _ => null
  };

  /// Whether a column's values are figures, which go against the right edge of their
  /// column (the header's title too) so they compare top to bottom unit under unit.
  static bool alignsRight(StockSummaryColumn column) => switch (column.type) {
    TableFieldType.number ||
    TableFieldType.decimal ||
    TableFieldType.counter ||
    TableFieldType.discount ||
    TableFieldType.percentage ||
    TableFieldType.price ||
    TableFieldType.currency ||
    TableFieldType.measure => true,
    _ => false
  };

  /// The least a text column is drawn at: under it a name says nothing, and the
  /// column is better left out ([SummaryLayout.of]).
  static double get minFlexible => AppSize.text * 6;

  /// Whether any of [fields] takes a share of the leftover width. Without one the
  /// leftover is air before the numbers, so they don't shift to the middle.
  bool get hasFlexible => fields.any((column) => widthOf(column) == null);

  /// How much a text column takes of the middle of the leftover width.
  ///
  /// It's the width it was left at in the spreadsheet, which already says which
  /// is a description and which a code. A column nobody touched is worth what a
  /// normal column is, and the clipping of the extremes keeps one that someone
  /// dragged to the other side of the screen from eating the rest.
  static int flexOf(StockSummaryColumn column) =>
    (column.width ?? 160).round().clamp(80, 320);

  /// Distributes [columns] according to the window's width, and to [width] (what a
  /// row has inside its [rowPadding]) when given.
  ///
  /// The window says how many columns are worth showing; [width] which of those
  /// fit. The short columns measure what they measure, so a few codes and prices
  /// can ask for more than there is: the last of the table's columns are left out
  /// first, then the last numbers (stock stays), then the photo. Shrinking them
  /// instead would cut every value to fit none.
  factory SummaryLayout.of(BuildContext context, List<StockSummaryColumn> columns, {double? width}) {
    final device = Responsive.of(context);

    StockSummaryColumn? image;
    final fields = <StockSummaryColumn>[];
    final numbers = <StockSummaryColumn>[];

    for (final column in columns) {
      if (column.isImage) {
        image = column;
      } else if (column.isNumber) {
        numbers.add(column);
      } else {
        fields.add(column);
      }
    }

    // How many fit on each side. On the phone remains the minimum with which a
    // row still says something: which product it is and how much is left.
    final (int maxFields, int maxNumbers) = device.isPhone
      ? (1, 1)
      : device.isTablet
        ? (2, 2)
        : (4, 3);

    final layout = SummaryLayout._(
      image: image,
      fields: fields.take(maxFields).toList(),
      numbers: numbers.take(maxNumbers).toList()
    );

    return width == null ? layout : layout._fitting(width);
  }

  /// What the line asks for at the least: the fixed columns at their width, the
  /// texts at [minFlexible], and the air between them all.
  double get _least {
    var least = 0.0;

    if (image != null) least += imageSize + gap;
    for (final column in fields) {
      least += (widthOf(column) ?? minFlexible) + gap;
    }

    least += numbers.length * numberWidth;
    if (numbers.length > 1) least += (numbers.length - 1) * gap;

    return least;
  }

  /// This layout without the columns that don't fit in [width], in the order
  /// [SummaryLayout.of] says.
  SummaryLayout _fitting(double width) {
    var fitted = this;

    while (fitted._least > width) {
      if (fitted.fields.isNotEmpty) {
        fitted = SummaryLayout._(
          image: fitted.image,
          fields: fitted.fields.sublist(0, fitted.fields.length - 1),
          numbers: fitted.numbers
        );
      } else if (fitted.numbers.length > 1) {
        fitted = SummaryLayout._(
          image: fitted.image,
          fields: fitted.fields,
          numbers: fitted.numbers.sublist(0, fitted.numbers.length - 1)
        );
      } else if (fitted.image != null) {
        fitted = SummaryLayout._(image: null, fields: fitted.fields, numbers: fitted.numbers);
      } else {
        break;
      }
    }

    return fitted;
  }
}
