import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/inventory/sku_generator.dart';

void main() {
  test('el SKU generado tiene 12 simbolos de un alfabeto sin ambiguos', () {
    final sku = nextSku(random: Random(1));

    expect(sku.length, 12);
    expect(RegExp(r'^[2-9A-HJ-NP-Z]+$').hasMatch(sku), isTrue);
  });

  test('la misma semilla arma siempre el mismo SKU', () {
    expect(nextSku(random: Random(7)), nextSku(random: Random(7)));
  });

  test('sin semilla, dos llamadas seguidas no chocan', () {
    expect(nextSku(), isNot(nextSku()));
  });
}
