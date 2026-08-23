import 'package:flutter/services.dart' show SystemMouseCursors;
import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/inventory/table_field_type.dart';

void main() {
  test('smart text encabeza la lista de tipos', () {
    // Es el tipo que la IA lee y busca por significado: el que conviene ver
    // primero al elegir, no uno mas al final de la lista.
    expect(TableFieldType.ordered.first, TableFieldType.vector);
  });

  test('estan todos los tipos y una sola vez', () {
    final ordered = TableFieldType.ordered;

    expect(ordered.length, TableFieldType.values.length);
    expect(ordered.toSet().length, ordered.length);
  });

  test('detras de smart text el orden es el declarado', () {
    expect(
      TableFieldType.ordered.skip(1),
      TableFieldType.values.where((type) => type != TableFieldType.vector)
    );
  });

  group('el puntero dice que se hace en la celda', () {
    test('donde se escribe, el de escribir', () {
      // Es lo que se ve antes de tocar, y hasta ahora era el de una planilla:
      // el mismo para la celda que se tipea y para la que despliega algo.
      for (final type in [
        TableFieldType.text,
        TableFieldType.vector,
        TableFieldType.price,
        TableFieldType.sku,
        TableFieldType.date
      ]) {
        expect(type.cursor, SystemMouseCursors.text, reason: type.value);
      }
    });

    test('donde se toca y se despliega, el de un boton', () {
      // Las dos celdas que no tienen editor: una lista se elige y una imagen
      // abre su desplegable.
      expect(TableFieldType.select.cursor, SystemMouseCursors.click);
      expect(TableFieldType.image.cursor, SystemMouseCursors.click);
    });

    test('es la misma pregunta que decide si hay editor', () {
      for (final type in TableFieldType.values) {
        expect(
          type.cursor,
          type.picker ? SystemMouseCursors.click : SystemMouseCursors.text,
          reason: type.value
        );
      }
    });
  });
}
