import 'package:flutter/widgets.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:intl/intl.dart';

// SERVICES
import 'package:app/services/catalog/currency_catalog_service.dart';

/// How the figures, the dates and above all the **waits** of the sales section
/// are written.
///
/// It lives apart from the widgets for the same reason the money section's does:
/// the table, the filter bar, the handover panel and the sale's own detail all
/// write the same values, and a screen that says one thing in a row and another
/// in a panel is read as two different numbers.
///
/// The amounts follow the money section's rule —written the way whoever charges
/// them writes them, from the currency's own catalog row— and the dates the
/// opposite one: they go in the language being read, because they are not data
/// of the company, they are when something happened.

/// An amount with its currency, or nothing at all.
///
/// **Null is not zero here.** A conversation the assistant is holding has not
/// been priced, and writing `$0.00` over it would claim the sale is worth
/// nothing; the empty string is what the table draws its dash for.
String saleAmountLabel(double? value, String currency) => value == null
  ? ""
  : CurrencyCatalogService().resolve(currency).label(value.toString()) ??
      value.toStringAsFixed(2);

/// A count of units, with its thousands separator.
String saleCountLabel(BuildContext context, int value) =>
  NumberFormat.decimalPattern(_locale(context)).format(value);

/// The day and the time something happened, in local time.
String saleDateLabel(BuildContext context, DateTime? at) {
  if (at == null) return "";

  final locale = _locale(context);
  final local = at.toLocal();

  return "${DateFormat.yMMMd(locale).format(local)}"
    " · ${DateFormat.jm(locale).format(local)}";
}

/// **How long this sale has been standing where it is.**
///
/// It is the one figure this screen is really read by, and it is written as a
/// wait and not as a timestamp on purpose: a board answers "how long has that
/// customer been waiting for their box", and `14:32` makes every reader do the
/// subtraction themselves. Past a day it falls back to days, which is already
/// bad news and does not need minutes on it.
///
/// A negative gap —a clock a few seconds ahead of the server's— reads as just
/// now rather than as a wait in the future.
String saleWaitLabel(BuildContext context, DateTime? since) {
  if (since == null) return "";

  final minutes = DateTime.now().difference(since.toLocal()).inMinutes;

  if (minutes < 1) return S.of(context).sales_wait_now;
  if (minutes < 60) return S.of(context).sales_wait_minutes(minutes);

  final hours = minutes ~/ 60;

  if (hours < 24) return S.of(context).sales_wait_hours(hours);

  return S.of(context).sales_wait_days(hours ~/ 24);
}

/// The language the numbers and dates are ordered and translated in. It comes
/// out of the loaded localizations, so the screen writes itself in the language
/// it is being looked at in.
String _locale(BuildContext context) =>
  Localizations.localeOf(context).toString();
