import 'package:flutter/widgets.dart';

// PACKAGES
import 'package:intl/intl.dart';

// SERVICES
import 'package:app/services/catalog/currency_catalog_service.dart';

/// How the figures and the dates of the money section are written.
///
/// It lives apart from the widgets because the four tabs use it and the answer
/// has to be the same in all of them: a screen that says `Bs. 1.240,00` in the
/// summary and `1240` in the history is read as two different numbers.
///
/// **The amount is written the way whoever charges it writes it**, not the way
/// whoever is looking writes it: the symbol, its side, the decimals and the
/// grouping all come from the currency's own catalog row (see `CurrencyModel`),
/// so a Venezuelan price list is not rewritten as `Bs. 1,234.50` because the app
/// happens to be in English. The dates are the opposite and go in the language
/// being read: they are not data of the company, they are when something
/// happened.

/// An amount with its currency, written whole (`$1,204.30`).
///
/// [currency] is the code the response carried. It is resolved against the
/// catalog, which always answers something: a currency that is no longer
/// offered is written with its own code rather than with somebody else's
/// symbol, because drawing `$` over an amount in bolivars is lying about the
/// data.
String moneyLabel(double value, String currency) =>
  CurrencyCatalogService().resolve(currency).label(value.toString()) ??
    value.toStringAsFixed(2);

/// A count of movements with its thousands separator. A busy month is tens of
/// thousands of rows and `18432` is not read at a glance.
String moneyCount(BuildContext context, int value) =>
  NumberFormat.decimalPattern(_locale(context)).format(value);

/// The day and the time something happened.
///
/// It goes with the time and not only the day because the dates of this section
/// are looked at to tell **this morning's movement from last night's**, which a
/// bare day cannot do.
///
/// It is moved to local time before writing it: the backend sends UTC, and a
/// payment recorded at nine in the morning that reads as noon looks like an
/// error.
String moneyDateLabel(BuildContext context, DateTime? at) {
  if (at == null) return "";

  final locale = _locale(context);
  final local = at.toLocal();

  return "${DateFormat.yMMMd(locale).format(local)}"
    " · ${DateFormat.jm(locale).format(local)}";
}

/// Only the day, for where the hour adds nothing: the window a summary covers,
/// the day a credit ticket was sold.
String moneyDayLabel(BuildContext context, DateTime? at) =>
  at == null ? "" : DateFormat.yMMMd(_locale(context)).format(at.toLocal());

/// The language the numbers and dates are ordered and translated in.
///
/// It comes out of the loaded localizations and not from a constant: `intl`
/// brings the month names and the separators with the data
/// `GlobalMaterialLocalizations` leaves, so the screen writes itself in the
/// language it is being looked at in.
String _locale(BuildContext context) =>
  Localizations.localeOf(context).toString();

/// An amount that can be smaller than the currency's own smallest unit.
///
/// It exists for what the bot costs, billed per token: a week of a quiet
/// shop is fractions of a cent, and [moneyLabel] —which writes what the
/// currency writes, two decimals for dollars— would report it as `$0.00`. A
/// spend that happened must not be written as nothing, so anything under a cent
/// keeps four decimals and everything else is written like every other figure
/// of the section, so the two agree wherever both can be read.
String moneyFineLabel(double value, String currency) {
  if (value <= 0 || value >= 0.01) return moneyLabel(value, currency);

  return CurrencyCatalogService()
    .resolve(currency)
    .write(NumberFormat.decimalPatternDigits(decimalDigits: 4).format(value));
}
