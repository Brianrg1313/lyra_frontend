import 'package:flutter/foundation.dart';

/// A unit a line's quantity can be written in, and how many of the ingredient's own unit one
/// of it is ([factor]): with meat counted in kg, `g` is 0.001.
@immutable
class KitchenUnit {
  const KitchenUnit(this.symbol, this.factor);

  final String symbol;
  final double factor;

  @override
  bool operator ==(Object other) => other is KitchenUnit && other.symbol == symbol && other.factor == factor;

  @override
  int get hashCode => Object.hash(symbol, factor);
}

/// The two measures a kitchen writes in a smaller and a bigger unit, by the smaller one.
const Map<String, ({String small, String big})> _families = {
  "g": (small: "g", big: "kg"),
  "ml": (small: "ml", big: "l")
};

/// How a table writes each unit, read as one of [_families] (its smaller unit, and how many of
/// it the written one is).
const Map<String, (String, double)> _aliases = {
  "g": ("g", 1), "gr": ("g", 1), "grs": ("g", 1), "gram": ("g", 1), "grams": ("g", 1),
  "gramo": ("g", 1), "gramos": ("g", 1),
  "kg": ("g", 1000), "kgs": ("g", 1000), "kilo": ("g", 1000), "kilos": ("g", 1000),
  "kilogram": ("g", 1000), "kilograms": ("g", 1000), "kilogramo": ("g", 1000), "kilogramos": ("g", 1000),
  "ml": ("ml", 1), "mililitro": ("ml", 1), "mililitros": ("ml", 1), "milliliter": ("ml", 1),
  "milliliters": ("ml", 1), "millilitre": ("ml", 1), "millilitres": ("ml", 1),
  "l": ("ml", 1000), "lt": ("ml", 1000), "lts": ("ml", 1000), "litro": ("ml", 1000), "litros": ("ml", 1000),
  "liter": ("ml", 1000), "liters": ("ml", 1000), "litre": ("ml", 1000), "litres": ("ml", 1000)
};

/// The units a quantity of an ingredient counted in [unit] can be written in: a weight or a
/// volume in its smaller and bigger unit (300 g of a meat counted in kg), anything else only in
/// its own (empty: counted in units). The backend only takes the ingredient's own unit
/// (`cocina-frontend.md` §3), so what is written travels multiplied by its [KitchenUnit.factor].
List<KitchenUnit> kitchenUnitsFor(String unit) {
  final own = _aliases[unit.trim().toLowerCase()];
  if (own == null) return [KitchenUnit(unit.trim(), 1)];

  final (small, size) = own;
  final family = _families[small]!;

  return [KitchenUnit(family.small, 1 / size), KitchenUnit(family.big, 1000 / size)];
}

/// How [qty] of an ingredient counted in [unit] reads best: below one of a big unit in the
/// small one (0.3 kg is 300 g), a thousand or more of a small one in the big one.
({double qty, KitchenUnit unit}) kitchenBestUnit(double qty, String unit) {
  final units = kitchenUnitsFor(unit);
  if (units.length == 1) return (qty: qty, unit: units.single);

  final small = units.first;
  final big = units.last;
  final inSmall = qty / small.factor;
  final shown = inSmall.abs() >= 1000 || inSmall == 0 ? big : small;

  return (qty: _clean(qty / shown.factor), unit: shown);
}

/// A converted figure without the float noise of the division (0.3 / 0.001 is 299.99999…).
double _clean(double value) => double.parse(value.toStringAsFixed(6));
