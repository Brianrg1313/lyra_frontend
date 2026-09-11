import 'package:flutter/widgets.dart';

// PACKAGES
import 'package:intl/intl.dart';

/// How the figures and dates of the table settings are written.
///
/// It lives apart from the widgets because the four blocks and the two answers
/// use it and the answer has to be the same in all of them: a table that says
/// "12,480 records" above and "12480" below is read as two different data
/// points.

/// The language with which the numbers and dates are ordered and translated.
///
/// It comes out of the loaded localizations and not from a constant: the names
/// of the months and the thousands separator are brought by `intl` with the
/// data that `GlobalMaterialLocalizations` leaves, so the screen writes itself
/// in the language in which it is looked at.
String _locale(BuildContext context) =>
  Localizations.localeOf(context).toString();

/// A quantity with its thousands separator: a table of hundreds of thousands
/// of rows is precisely the normal case, and `184320` is not read at a glance.
String settingsNumber(BuildContext context, int value) =>
  NumberFormat.decimalPattern(_locale(context)).format(value);

/// A full date: the day in words and the time of the clock of the language.
///
/// It goes with the time and not only the day because the three dates of this
/// screen are looked at to know **what happened today** —when the last data
/// point came in, when the last column was touched—, and a bare day does not
/// distinguish this morning's from last night's.
///
/// It is converted to local time before writing it: the backend sends them in
/// UTC, and a table reloaded at nine in the morning that says it was at noon
/// is read as an error.
String settingsDate(BuildContext context, DateTime? at) {
  if (at == null) return "";

  final locale = _locale(context);
  final local = at.toLocal();

  return "${DateFormat.yMMMd(locale).format(local)}"
    " · ${DateFormat.jm(locale).format(local)}";
}