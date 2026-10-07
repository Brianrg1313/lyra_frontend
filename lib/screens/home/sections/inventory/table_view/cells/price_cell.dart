import 'package:flutter/material.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';
import 'package:app/services/catalog/currency_catalog_service.dart';
import 'package:app/services/catalog/currency_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/inventory/table_view/sheet_theme.dart';

/// The cell of a money field —a price or any other amount—, out of
/// editing.
///
/// A price isn't a number: it's a number **in a currency**, and the currency
/// isn't in the datum. It comes from two places, in this order: from the
/// column, when the field declared its own ([unit]), and otherwise from the
/// company that charges (see [BusinessService.currencyCode]) —and how that
/// currency is written isn't here either, but in the platform catalog
/// ([CurrencyCatalogService])—. That the column wins is what allows a table with
/// the sale price in one currency and the cost in another, which is the case for
/// which the backend put a unit on the column. That's why this cell is the only
/// one that looks outside the sheet, and why it's a widget of its own: the two
/// subscriptions live here and not in [SheetCellView], where the text cells
/// —which are almost all of them— would also pay for them without ever using them.
///
/// What's written are two things of different weight and they're painted as
/// such: the amount in the datum's color and the symbol in gray, on whichever
/// side corresponds (`$22,23`, `22,23€`). So the column reads as a column of
/// numbers —which is how one price compares to another— and the symbol stays in
/// the background, repeated in every row without stealing the eye from the value.
///
/// A value that isn't an amount shows just as it was stored and without a
/// symbol: while the datum isn't a number, putting a currency on it would affirm
/// something that isn't known.
class PriceCell extends StatelessWidget {
  const PriceCell({
    super.key,
    required this.value,
    required this.style,
    required this.alignment,
    this.unit = ""
  });

  /// The price as stored (or as just typed in the
  /// row's draft).
  final String value;

  /// Style of the amount. The cell decides it, since it knows if the field is typed.
  final TextStyle style;

  final TextAlign alignment;

  /// The currency code the column declared (`USD`, `VES`), or empty when it
  /// declared none and the company's rules.
  final String unit;

  @override
  Widget build(BuildContext context) {
    // Two subscriptions and not one: the company says **in which currency** it
    // charges and the catalog says **how it's written**. Changing company notifies
    // the first and rereading the catalog the second, and the cell has to repaint
    // with either of the two. The company's is always requested —and not only
    // when needed— because a conditional subscription would change the cell's
    // dependencies depending on which column it's in.
    final business = context.select<BusinessService, String>(
      (business) => business.currencyCode
    );

    // The column's wins: it's the one that says what **this**
    // number is written in, and the company's is just the default answer for a
    // column that never declared its own.
    final code = unit.isNotEmpty ? unit : business;

    final currency = context.select<CurrencyCatalogService, CurrencyModel>(
      (catalog) => catalog.resolve(code)
    );

    final amount = currency.amount(value);

    // What isn't an amount (an empty cell, a "consult") shows just as it was
    // stored: putting a currency on it would affirm something that isn't known.
    if (amount == null) {
      return Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: alignment,
        style: style
      );
    }

    // The gap between the symbol and the amount travels with the symbol (and not as
    // a loose space) so it's painted in its same style: the currency decides it,
    // not the cell.
    final symbol = TextSpan(
      text: currency.leading
        ? "${currency.symbol}${currency.gap}"
        : "${currency.gap}${currency.symbol}",
      style: SheetTheme.of(context).symbol
    );

    return Text.rich(
      TextSpan(children: [
        if (currency.leading) symbol,
        TextSpan(text: amount),
        if (!currency.leading) symbol
      ]),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: alignment,
      style: style
    );
  }
}
