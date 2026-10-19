import 'package:flutter/foundation.dart';
import 'package:app/services/inventory/measure_units.dart';

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

/// The two units a kitchen writes each magnitude in, a smaller and a bigger one.
const Map<MeasureMagnitude, ({String small, String big})> _families = {
  MeasureMagnitude.weight: (small: "g", big: "kg"),
  MeasureMagnitude.volume: (small: "ml", big: "l")
};

/// The units a quantity of an ingredient counted in [unit] can be written in: every unit of its
/// magnitude ([measureUnits]: 300 g or 10 oz of a meat counted in kg, 450 ml of a soda counted in
/// l), anything else only in its own (empty: counted in units). What is written travels
/// multiplied by its [KitchenUnit.factor], in the ingredient's own unit (`cocina-frontend.md` §3).
List<KitchenUnit> kitchenUnitsFor(String unit) {
  final own = measureUnitOf(unit);
  if (own == null) return [KitchenUnit(unit.trim(), 1)];

  return [
    for (final measure in measureUnits)
      if (measure.magnitude == own.magnitude) KitchenUnit(measure.symbol, measure.size / own.size)
  ];
}

/// How [qty] of an ingredient counted in [unit] reads best: below one of a big unit in the
/// small one (0.3 kg is 300 g), a thousand or more of a small one in the big one.
///
/// Only the two a kitchen writes in (g and kg, ml and l): an ingredient counted in anything else
/// reads in its own.
({double qty, KitchenUnit unit}) kitchenBestUnit(double qty, String unit) {
  final own = measureUnitOf(unit);
  final family = own == null ? null : _families[own.magnitude];
  if (own == null || family == null) return (qty: qty, unit: KitchenUnit(unit.trim(), 1));

  final small = KitchenUnit(family.small, measureUnitOf(family.small)!.size / own.size);
  final big = KitchenUnit(family.big, measureUnitOf(family.big)!.size / own.size);
  final inSmall = qty / small.factor;
  final shown = inSmall.abs() >= 1000 || inSmall == 0 ? big : small;

  return (qty: _clean(qty / shown.factor), unit: shown);
}

/// A converted figure without the float noise of the division (0.3 / 0.001 is 299.99999…).
double _clean(double value) => double.parse(value.toStringAsFixed(6));
