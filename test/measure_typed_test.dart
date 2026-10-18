/// A unit typed after a measure's number is read as the column's symbol, units included.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/inventory/measure_units.dart';

void main() {
  test('a number and the word after it are split, with or without a space', () {
    expect(splitMeasure("300lt"), (number: "300", unit: "lt"));
    expect(splitMeasure(" 1,5 kg "), (number: "1,5", unit: "kg"));
    expect(splitMeasure("30"), (number: "30", unit: ""));
  });

  test('what does not start with a number is no measure', () {
    expect(splitMeasure("on request"), isNull);
    expect(splitMeasure(""), isNull);
  });

  test('a unit is read however it is written, whatever its case', () {
    expect(measureSymbolOf("lt"), "l");
    expect(measureSymbolOf("Litros"), "l");
    expect(measureSymbolOf("KILOS"), "kg");
    expect(measureSymbolOf("mts"), "m");
  });

  test('units are the empty symbol, and an unknown word is none', () {
    expect(measureSymbolOf("uds"), "");
    expect(measureSymbolOf("unidades"), "");
    expect(measureSymbolOf("cajas"), isNull);
  });

  test('every offered unit reads as itself', () {
    for (final unit in measureUnits) {
      expect(measureSymbolOf(unit.symbol), unit.symbol, reason: unit.symbol);
    }
  });
}
