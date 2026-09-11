import 'package:flutter/material.dart';

import '../sheet_style.dart';

/// The cell of a number that reads **with a symbol behind it**: a measurement
/// with its unit (`1,5 kg`) or a percentage with its sign (`16%`).
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
class UnitCell extends StatelessWidget {
  const UnitCell({
    super.key,
    required this.value,
    required this.style,
    required this.alignment,
    required this.symbol
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

  @override
  Widget build(BuildContext context) {
    final trimmed = value.trim();
    final number = trimmed.isEmpty
      ? null
      : double.tryParse(trimmed.replaceAll(",", "."));

    if (number == null || symbol.isEmpty) {
      return Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: alignment,
        style: style
      );
    }

    return Text.rich(
      TextSpan(children: [
        TextSpan(text: value),
        // The gap travels with the symbol and not loose, so it's painted in its
        // same style (just like in [PriceCell]). The percentage goes attached
        // —`16%`, never `16 %`— and a unit detached, which is how they're
        // written.
        TextSpan(
          text: symbol == "%" ? symbol : " $symbol",
          style: SheetTheme.of(context).symbol
        )
      ]),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: alignment,
      style: style
    );
  }
}
