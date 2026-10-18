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

/// How each unit is written, by its symbol: what a person types after a number in a measure
/// cell («300 lt», «2 kilos», «5 uds») and the sheet reads as that symbol.
///
/// The empty symbol is **units**: a measure column that declared none counts pieces, so
/// «5 uds» is read as that and not as an unknown unit.
const Map<String, List<String>> _written = {
  "": ["u", "un", "und", "unds", "ud", "uds", "unid", "unidad", "unidades", "unit", "units",
    "pz", "pza", "pzas", "pieza", "piezas", "pc", "pcs", "piece", "pieces"],
  "mg": ["mg", "miligramo", "miligramos", "milligram", "milligrams"],
  "g": ["g", "gr", "grs", "gramo", "gramos", "gram", "grams"],
  "kg": ["kg", "kgs", "kilo", "kilos", "kilogramo", "kilogramos", "kilogram", "kilograms"],
  "oz": ["oz", "onza", "onzas", "ounce", "ounces"],
  "lb": ["lb", "lbs", "libra", "libras", "pound", "pounds"],
  "ml": ["ml", "mililitro", "mililitros", "milliliter", "milliliters", "millilitre", "millilitres"],
  "l": ["l", "lt", "lts", "litro", "litros", "liter", "liters", "litre", "litres"],
  "gal": ["gal", "galon", "galón", "galones", "gallon", "gallons"],
  "mm": ["mm", "milimetro", "milímetro", "milimetros", "milímetros", "millimeter", "millimeters"],
  "cm": ["cm", "centimetro", "centímetro", "centimetros", "centímetros", "centimeter", "centimeters"],
  "m": ["m", "mt", "mts", "metro", "metros", "meter", "meters", "metre", "metres"],
  "km": ["km", "kms", "kilometro", "kilómetro", "kilometros", "kilómetros", "kilometer", "kilometers"],
  "in": ["in", "pulgada", "pulgadas", "inch", "inches"],
  "ft": ["ft", "pie", "pies", "foot", "feet"]
};

final Map<String, String> _symbols = {
  for (final entry in _written.entries)
    for (final word in entry.value) word: entry.key
};

/// The symbol [written] names (`lt` → `l`, `uds` → `""`, units), or `null` when it is no
/// unit the sheet knows. Case does not matter.
String? measureSymbolOf(String written) => _symbols[written.trim().toLowerCase()];

/// A measure as typed: its number and, when one was written after it, the unit's word.
typedef MeasureTyped = ({String number, String unit});

final RegExp _typed = RegExp(r"^\s*([+-]?\d+(?:[.,]\d+)?)\s*(\D*?)\s*$");

/// Splits «300lt», «1,5 kg» or «30» into the number and what follows it (empty when nothing
/// does). `null` when it does not start with a number: «on request» is not a measure.
MeasureTyped? splitMeasure(String text) {
  final match = _typed.firstMatch(text);
  if (match == null) return null;

  return (number: match.group(1)!, unit: match.group(2)!);
}
