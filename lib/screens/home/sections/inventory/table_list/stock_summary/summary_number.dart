import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/stock/movements/stock_movement_model.dart' show stockFigure;

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
    this.align = TextAlign.right,
    this.unit = ""
  });

  /// The number, or null when nothing is being counted. A supply's carries decimals.
  final num? value;

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

  /// What the figure is counted in, written attached to it (`300kg`) when the product
  /// declared its own; empty where its column's header says it.
  final String unit;

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
      "${stockFigure(amount)}$unit",
      multiplier: 0.9,
      bold: true,
      ellipsis: true,
      textAlign: align,
      color: alert && amount <= 0 ? scheme.snackBar.error : null
    );
  }
}
