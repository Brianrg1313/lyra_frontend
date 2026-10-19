/// The units a `MEASURE` column is offered in, by magnitude: weight, volume, length.
///
/// They are symbols and not names because the symbol is what the column stores (`UNIT`) and
/// what every row is written with («1,5 kg»): it is not translated. Any other one can still be
/// typed in the menu's create row; this list is only what is one tap away.
///
/// Each one also says its size ([MeasureUnit.size]), so a figure can follow its unit
/// ([measureFactor]): the backend's `model:/inventory/measures.js` holds the same table and is
/// what converts; this one is what decides whether the sheet offers to.
library;

enum MeasureMagnitude { weight, volume, length }

class MeasureUnit {
  const MeasureUnit(this.symbol, this.magnitude, this.size);

  final String symbol;
  final MeasureMagnitude magnitude;

  /// How many of its magnitude's base (g, ml, mm) one of it is.
  final double size;
}

/// In the order they are offered: each magnitude from its smallest unit up, the metric ones
/// before the imperial ones.
const List<MeasureUnit> measureUnits = [
  MeasureUnit("mg", MeasureMagnitude.weight, 0.001),
  MeasureUnit("g", MeasureMagnitude.weight, 1),
  MeasureUnit("kg", MeasureMagnitude.weight, 1000),
  MeasureUnit("oz", MeasureMagnitude.weight, 28.349523125),
  MeasureUnit("lb", MeasureMagnitude.weight, 453.59237),
  MeasureUnit("ml", MeasureMagnitude.volume, 1),
  MeasureUnit("l", MeasureMagnitude.volume, 1000),
  MeasureUnit("gal", MeasureMagnitude.volume, 3785.411784),
  MeasureUnit("mm", MeasureMagnitude.length, 1),
  MeasureUnit("cm", MeasureMagnitude.length, 10),
  MeasureUnit("m", MeasureMagnitude.length, 1000),
  MeasureUnit("km", MeasureMagnitude.length, 1000000),
  MeasureUnit("in", MeasureMagnitude.length, 25.4),
  MeasureUnit("ft", MeasureMagnitude.length, 304.8)
];

/// The unit [symbol] names, read as written (`lt` is `l`), or `null` for units (`""`, `u`) and
/// for any word the sheet does not know.
MeasureUnit? measureUnitOf(String symbol) {
  final known = measureSymbolOf(symbol);
  if (known == null || known.isEmpty) return null;

  return measureUnits.firstWhere((unit) => unit.symbol == known);
}

/// How many of [to] one [from] is (kg → g: 1000), or `null` when no figure can follow the
/// change: they measure different things (units are no number of litres) or either is a word
/// the sheet does not know. The same unit, however written, is 1: there is nothing to convert.
double? measureFactor(String from, String to) {
  if (from.trim().toLowerCase() == to.trim().toLowerCase()) return 1;

  final a = measureSymbolOf(from);
  final b = measureSymbolOf(to);
  if (a == null || b == null) return null;
  if (a == b) return 1;

  final left = measureUnitOf(a);
  final right = measureUnitOf(b);

  // Units and units are 1 above; units and a weight are not one magnitude.
  if (left == null || right == null || left.magnitude != right.magnitude) return null;

  return left.size / right.size;
}

/// [value] in another unit, without the float a division leaves behind (0.3 / 0.001 is
/// 299.99999…): twelve significant digits, as the backend keeps it.
double measureConvert(num value, double factor) => double.parse((value * factor).toStringAsPrecision(12));

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
String? measureSymbolOf(String written) {
  final word = written.trim().toLowerCase();
  return word.isEmpty ? "" : _symbols[word];
}

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
