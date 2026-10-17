import 'package:flutter/widgets.dart';

// PACKAGES
import 'package:intl/intl.dart';

// SERVICES
import 'package:app/toolkit/settings/initial_builder.dart' show businessService;

/// How the supply chain writes its figures. Every quantity, amount and day of the section and
/// of its panels goes through here, so `0,0333 kg` reads the same in a recipe and in a report.

String _locale(BuildContext context) => Localizations.localeOf(context).toString();

/// A quantity in a product's own unit: up to six decimals (a supply is counted in millionths),
/// none written when it has none (`2`, `0.2`, `0.0333`), with [unit] after it when known.
String kitchenQty(BuildContext context, double value, {String unit = ""}) {
  final text = (NumberFormat.decimalPattern(_locale(context))..maximumFractionDigits = 6).format(value);

  return unit.isEmpty ? text : "$text $unit";
}

/// An amount in the company's currency (`$1.00`). The kitchen's costs and a modifier's price
/// have no currency of their own: they are the company's.
String kitchenMoney(double value) =>
  businessService.currency.label(value.toString()) ?? value.toStringAsFixed(2);

/// A percent as typed and shown (`10 %`, `12.5 %`).
String kitchenPercent(BuildContext context, double value) =>
  "${(NumberFormat.decimalPattern(_locale(context))..maximumFractionDigits = 1).format(value)} %";

/// A day, short (`Oct 16, 2026`).
String kitchenDay(BuildContext context, DateTime at) => DateFormat.yMMMd(_locale(context)).format(at);

/// A number as a person types it: either decimal mark, no grouping. `null` when it is not one.
double? kitchenParse(String text) {
  final clean = text.trim().replaceAll(" ", "").replaceAll(",", ".");
  if (clean.isEmpty) return null;

  return double.tryParse(clean);
}

/// How a number is put back in a field to edit: the shortest exact text, a dot as the mark.
String kitchenField(double value) {
  if (value == value.roundToDouble()) return value.round().toString();

  final text = value.toStringAsFixed(6);

  return text.replaceFirst(RegExp(r"0+$"), "").replaceFirst(RegExp(r"\.$"), "");
}
