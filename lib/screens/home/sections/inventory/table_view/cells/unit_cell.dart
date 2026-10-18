import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/home/sections/inventory/table_view/sheet_style.dart';
import 'package:app/screens/home/sections/inventory/table_view/sheet_theme.dart';

/// The cell of a number that reads **with a symbol behind it**: a measurement
/// with its unit (`1,5kg`) or a percentage with its sign (`16%`).
///
/// It's [PriceCell]'s sibling for what isn't money, and it has to be another
/// one for two reasons: the symbol always goes on the right —no unit is written
/// in front of the number— and the value gets no formatting. A price is
/// punctuated as its currency punctuates it (two decimals, thousands separator);
/// a measurement has no fixed decimals, so it shows as it was written:
/// rounding `1,5` to `1,50` would invent a precision nobody declared.
///
/// The two weights paint as such, just like in a price: the number in the
/// datum's color and the symbol in gray ([SheetStyle.symbol]). So the column
/// reads as a column of numbers —which is how one measurement compares to
/// another— and the symbol, repeated in every row, stays in the background.
///
/// The symbol is only drawn if the value **is** a number. A cell with
/// "consult" or "on request" shows as is: putting `kg` behind it would
/// affirm that there's a weight there.
///
/// The symbol goes attached to the number (`30l`, `16%`): it is read as one word,
/// and the cell is narrow.
///
/// A measure's button at its right ([onPickUnit]) changes the unit of **the
/// whole column**, like a date's calendar button: a column is counted in one
/// unit, so a row in grams and the next in kilos would stop comparing at a
/// glance. A measure that declared none counts units ([counts]): `5u`.
class UnitCell extends StatelessWidget {
  const UnitCell({
    super.key,
    required this.value,
    required this.style,
    required this.alignment,
    required this.symbol,
    this.counts = false,
    this.row = 0,
    this.onPickUnit
  });

  /// The number as stored (or as just typed in the
  /// row's draft).
  final String value;

  /// Style of the number. The cell decides it, since it knows if the field is typed.
  final TextStyle style;

  final TextAlign alignment;

  /// What's written behind the number: the column's unit in a measurement
  /// (`kg`, `ml`, `cm`), the sign in a percentage. Empty in a measurement that
  /// hasn't declared its own yet, and there the cell is the bare number.
  final String symbol;

  /// Whether an empty [symbol] reads as units (a measure's default) instead of
  /// as the bare number.
  final bool counts;

  /// Which row of the sheet it's in: it decides the button's fill (see
  /// [SheetStyle.frameFill]).
  final int row;

  /// Opens the column's units anchored to the button (the context it is
  /// given). `null` where the unit can't be changed, and there the symbol is
  /// plain text.
  final ValueChanged<BuildContext>? onPickUnit;

  @override
  Widget build(BuildContext context) {
    final trimmed = value.trim();
    final number = trimmed.isEmpty
      ? null
      : double.tryParse(trimmed.replaceAll(",", "."));
    final shown = symbol.isEmpty && counts
      ? S.of(context).product_table_view_unit_count_symbol
      : symbol;

    final text = number == null || shown.isEmpty
      ? Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignment,
          style: style
        )
      : Text.rich(
          TextSpan(children: [
            TextSpan(text: trimmed),
            // In its own style, gray behind the number, just like in [PriceCell].
            TextSpan(text: shown, style: SheetTheme.of(context).symbol)
          ]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignment,
          style: style
        );

    if (number == null || onPickUnit == null) return text;

    return Row(children: [
      Expanded(child: text),
      SizedBox(width: AppSize.gap * .5),
      _button(context)
    ]);
  }

  /// The column's units, as a ruler at the right of the number.
  Widget _button(BuildContext context) {
    final sheet = SheetTheme.of(context);

    // A bit taller than a letter, like the date's and the SKU's buttons: it
    // reads as a button without weighing like a toolbar one.
    final size = AppSize.text * 1.8;

    return Tooltip(
      message: S.of(context).product_table_view_unit_hint,
      child: Builder(builder: (anchor) => FeedbackButton(
        message: S.of(context).product_table_view_unit,
        height: size,
        width: size,
        radius: sheet.frameRadius,
        color: sheet.frameFill(row: row),
        action: () => onPickUnit!(anchor),
        child: Center(child: Icon(
          Icons.straighten,
          size: AppSize.text,
          color: sheet.scheme.text.primary
        ))
      ))
    );
  }
}
