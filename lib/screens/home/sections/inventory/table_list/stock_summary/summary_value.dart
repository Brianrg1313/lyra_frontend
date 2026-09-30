import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/catalog/currency_catalog_service.dart';
import 'package:app/services/catalog/currency_model.dart';
import 'package:app/services/inventory/product_date.dart';
import 'package:app/services/inventory/table_field_options.dart';
import 'package:app/services/inventory/table_field_type.dart';
import 'package:app/services/stock/summary/stock_summary_model.dart';

/// What's written in a summary cell that isn't the photo nor one of the three
/// numbers: a company column.
///
/// It's written as it's read, not as it's stored: a price carries the symbol of
/// the currency the company charges with and a date is written (`Feb 12, 2026`)
/// instead of how the database stores it (`2026-02-12`), which is a string of
/// hyphens you have to decipher number by number. The rest shows as is: as
/// long as the data isn't what it says it is, formatting it would be asserting
/// something unknown.
///
/// The empty doesn't disappear: a dash is seen. A blank cell in the middle of a
/// row reads as the row being cut off, and this list has columns that
/// legitimately aren't loaded in all products.
class SummaryValue extends StatelessWidget {
  const SummaryValue({
    super.key,
    required this.column,
    required this.raw,
    required this.currency
  });

  final StockSummaryColumn column;

  /// The value as it came. It's received unconverted because not every value is
  /// a text: an options list or a gallery isn't read with `toString()`.
  final dynamic raw;

  /// The currency the company charges with. It arrives already resolved from
  /// the panel and isn't read here: it's the same for all rows and subscribing
  /// each cell to the catalog would be paying hundreds of subscriptions for a
  /// single piece of data.
  final CurrencyModel currency;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    // A multi-label cell is stored as a list, so its text isn't the
    // `toString()` of what came (`[a, b]`) but its labels written on one line.
    // It's the only one not read as direct text.
    final value = column.type.multiple
      ? fieldLabelsText(raw)
      : raw?.toString().trim() ?? "";

    if (value.isEmpty) {
      return TextSmall("—", color: scheme.text.secondary);
    }

    return TextSmall(
      _written(context, value),
      ellipsis: true,
      // The text the AI indexes by meaning goes with the brand color, just
      // like in the spreadsheet (see [SheetStyle.semanticValue]): it's the only
      // thing of the row you can search for by describing it. The rest go with
      // the usual text color.
      color: column.type.semantic ? scheme.primary : null
    );
  }

  /// The value already written for reading.
  ///
  /// Money is written with the column's currency when it declared one, and with
  /// the company's when it didn't: it's the same rule as in the spreadsheet
  /// (see [PriceCell]), because it's the same data read on two screens.
  String _written(BuildContext context, String value) => switch (column.type) {
    TableFieldType.price || TableFieldType.currency =>
      _money(context).label(value) ?? value,
    TableFieldType.discount || TableFieldType.percentage => "$value%",
    TableFieldType.measure =>
      column.unit.isEmpty ? value : "$value ${column.unit}",
    TableFieldType.date || TableFieldType.datetime => _date(context, value),
    _ => value
  };

  /// Which currency this column is written with. Its own if it declared one;
  /// if not, the one that arrives resolved from the panel, which is the
  /// company's.
  CurrencyModel _money(BuildContext context) => column.unit.isEmpty
    ? currency
    : context.read<CurrencyCatalogService>().resolve(column.unit);

  /// The date written in the app's language, or as it was stored if what's in
  /// the cell isn't a date (a freshly imported table can have anything in a
  /// column).
  String _date(BuildContext context, String value) {
    final date = ProductDate.parse(value);
    if (date == null) return value;

    return date.short(Localizations.localeOf(context).toString());
  }
}

/// One of the three numbers that close a row: what's left, what's set aside,
/// and how well it sells.
///
/// They're right-aligned and bold because they're for **comparing top to
/// bottom**: the column is read as a strip of figures and the units land one
/// below the other.
///
/// Null and zero are opposite answers and look different. Zero is "nothing is
/// left" and is painted red, which is the only thing of this list you have to
/// look at today; null is "no one is counting it" —the table has no stock
/// column, or the indicator isn't measured yet— and is seen as a dimmed dash,
/// which isn't an alarm.
class SummaryNumber extends StatelessWidget {
  const SummaryNumber({
    super.key,
    required this.value,
    this.alert = false,
    this.align = TextAlign.right
  });

  /// The number, or null when nothing is being counted.
  final int? value;

  /// If this column's zero is something to warn about. It is in stock —zero is
  /// that nothing is left to sell— and not in reserved, where zero is normal.
  final bool alert;

  /// Which side of its column the figure rests on.
  ///
  /// To the right when the column is just the number, which is how a strip of
  /// figures is compared top to bottom; to the middle when it carries buttons
  /// on its sides (see `SummaryStepper`), where the right edge is no longer the
  /// column's edge but a button's.
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final amount = value;

    if (amount == null) {
      return TextSmall(
        "—",
        color: scheme.text.secondary,
        textAlign: align
      );
    }

    return TextMedium(
      amount.toString(),
      multiplier: 0.9,
      bold: true,
      ellipsis: true,
      textAlign: align,
      color: alert && amount <= 0 ? scheme.snackBar.error : null
    );
  }
}

/// The product's thumbnail, which is how a person recognizes it.
///
/// The thumbnail is drawn and not the photo: the backend renders a 320px one on
/// upload ([kProductImageWidth]) and this measures what an icon measures.
/// Asking for the big one would be downloading megabytes per row to draw a
/// little square.
///
/// A product without a photo —or a photo that no longer resolves— doesn't leave
/// a hole: the same box with the section's icon is seen, so the strip of photos
/// stays an even strip.
class SummaryPicture extends StatelessWidget {
  const SummaryPicture({super.key, required this.row});

  final StockSummaryRow row;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final cover = row.cover;
    final radius = AppSize.cornerInset(AppSize.gap);

    return Surface(
      width: double.infinity,
      height: double.infinity,
      radius: radius,
      color: scheme.surface,
      child: cover == null
        ? _empty(scheme)
        : ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Image.network(
              cover.thumbnail,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stack) => _empty(scheme)
            )
          )
    );
  }

  Widget _empty(SchemeColor scheme) => Center(child: Icon(
    CI.shop,
    size: AppSize.text * 1.1,
    color: scheme.text.secondary
  ));
}
