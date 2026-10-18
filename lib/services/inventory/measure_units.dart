/// The units a `MEASURE` column is offered in, by magnitude: weight, volume, length.
///
/// They are symbols and not names because the symbol is what the column stores (`UNIT`) and
/// what every row is written with («1,5 kg»): it is not translated. Any other one can still be
/// typed in the menu's create row; this list is only what is one tap away.
library;

enum MeasureMagnitude { weight, volume, length }

class MeasureUnit {
  const MeasureUnit(this.symbol, this.magnitude);

  final String symbol;
  final MeasureMagnitude magnitude;
}

/// In the order they are offered: each magnitude from its smallest unit up, the metric ones
/// before the imperial ones.
const List<MeasureUnit> measureUnits = [
  MeasureUnit("mg", MeasureMagnitude.weight),
  MeasureUnit("g", MeasureMagnitude.weight),
  MeasureUnit("kg", MeasureMagnitude.weight),
  MeasureUnit("oz", MeasureMagnitude.weight),
  MeasureUnit("lb", MeasureMagnitude.weight),
  MeasureUnit("ml", MeasureMagnitude.volume),
  MeasureUnit("l", MeasureMagnitude.volume),
  MeasureUnit("gal", MeasureMagnitude.volume),
  MeasureUnit("mm", MeasureMagnitude.length),
  MeasureUnit("cm", MeasureMagnitude.length),
  MeasureUnit("m", MeasureMagnitude.length),
  MeasureUnit("km", MeasureMagnitude.length),
  MeasureUnit("in", MeasureMagnitude.length),
  MeasureUnit("ft", MeasureMagnitude.length)
];
