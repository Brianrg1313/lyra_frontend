/// A yes / no cell reads what the engine stores and what an import wrote, and writes only
/// `true` / `false`; only a catalog table offers a `STOCK` column.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/inventory/field_boolean.dart';
import 'package:app/services/stock/tables/table_lite_model.dart';

void main() {
  test('the engine\'s boolean and its numbers are read as such', () {
    expect(fieldBoolean(true), isTrue);
    expect(fieldBoolean(false), isFalse);
    expect(fieldBoolean(1), isTrue);
    expect(fieldBoolean(0), isFalse);
  });

  test('a written yes or no is read whatever its case or accent', () {
    for (final yes in ["true", "TRUE", "1", "Sí", "si", "Yes", "x"]) {
      expect(fieldBoolean(yes), isTrue, reason: yes);
    }
    for (final no in ["false", "0", "No", "NO", "falso"]) {
      expect(fieldBoolean(no), isFalse, reason: no);
    }
  });

  test('empty or anything else is neither, not a «no»', () {
    // An unchecked box would claim a «no» nobody wrote.
    expect(fieldBoolean(null), isNull);
    expect(fieldBoolean(""), isNull);
    expect(fieldBoolean("maybe"), isNull);
    expect(fieldBoolean(2), isNull);
  });

  test('a flipped cell travels as true or false', () {
    expect(fieldBooleanValue(true), "true");
    expect(fieldBooleanValue(false), "false");
  });

  test('only a catalog holds a stock column', () {
    expect(TableKind.catalog.stocked, isTrue);
    expect(TableKind.made.stocked, isFalse);
    expect(TableKind.supplies.stocked, isFalse);
  });
}
