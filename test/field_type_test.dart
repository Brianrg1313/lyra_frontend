import 'package:flutter/services.dart' show SystemMouseCursors;
import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/inventory/table_field_type.dart';

void main() {
  test('los dos semanticos encabezan la lista de tipos', () {
    // Son los que la IA lee y busca por significado: los que conviene ver
    // primero al elegir, no dos mas en el medio de una lista de veintitres.
    expect(
      TableFieldType.ordered.take(2),
      [TableFieldType.title, TableFieldType.description]
    );
  });

  test('estan todos los tipos y una sola vez', () {
    final ordered = TableFieldType.ordered;

    expect(ordered.length, TableFieldType.values.length);
    expect(ordered.toSet().length, ordered.length);
  });

  test('detras de los semanticos el orden es el declarado', () {
    expect(
      TableFieldType.ordered.skip(2),
      TableFieldType.values.where((type) => !type.semantic)
    );
  });

  group('los codigos son los del backend', () {
    test('el codigo es el nombre en mayusculas', () {
      // Es lo unico que viaja en el alta y en la lectura de una tabla: si esta
      // lista y la regla `TYPE` del backend se separan, la columna se crea con
      // un tipo que del otro lado no existe.
      for (final type in TableFieldType.values) {
        expect(type.value, type.name.toUpperCase());
      }
    });

    test('se leen todos de vuelta', () {
      for (final type in TableFieldType.values) {
        expect(TableFieldType.from(type.value), type, reason: type.value);
        expect(
          TableFieldType.from(type.value.toLowerCase()),
          type,
          reason: type.value
        );
      }
    });

    test('un tipo desconocido se lee como texto', () {
      // Se sigue viendo y editando la columna en vez de perderla.
      expect(TableFieldType.from("QUANTUM"), TableFieldType.text);
      expect(TableFieldType.from(null), TableFieldType.text);
    });

    test('los dos nombres viejos se siguen leyendo', () {
      // La base los migra sola, pero una instalacion sin migrar tiene que
      // dibujar sus columnas igual.
      expect(TableFieldType.from("SELECT"), TableFieldType.options);
      expect(TableFieldType.from("VECTOR"), TableFieldType.description);
    });
  });

  group('las familias del tipo', () {
    test('el texto que la IA indexa son dos', () {
      expect(
        TableFieldType.values.where((type) => type.semantic),
        [TableFieldType.title, TableFieldType.description]
      );
    });

    test('los que eligen de una lista son dos', () {
      expect(
        TableFieldType.values.where((type) => type.listed),
        [TableFieldType.options, TableFieldType.categories]
      );
    });

    test('solo el de varias etiquetas guarda mas de una', () {
      expect(
        TableFieldType.values.where((type) => type.multiple),
        [TableFieldType.categories]
      );
    });

    test('los que llevan simbolo de columna son tres', () {
      // El porcentaje queda afuera a proposito: ahi la unidad es el tipo.
      expect(
        TableFieldType.values.where((type) => type.united),
        [TableFieldType.price, TableFieldType.currency, TableFieldType.measure]
      );

      expect(TableFieldType.percentage.united, isFalse);
    });
  });

  group('el puntero dice que se hace en la celda', () {
    test('donde se escribe, el de escribir', () {
      // Es lo que se ve antes de tocar, y hasta ahora era el de una planilla:
      // el mismo para la celda que se tipea y para la que despliega algo.
      for (final type in [
        TableFieldType.text,
        TableFieldType.title,
        TableFieldType.description,
        TableFieldType.price,
        TableFieldType.sku,
        TableFieldType.date
      ]) {
        expect(type.cursor, SystemMouseCursors.text, reason: type.value);
      }
    });

    test('donde se toca y se despliega, el de un boton', () {
      // Las celdas que no tienen editor: las dos listas se eligen y una imagen
      // abre su desplegable.
      expect(TableFieldType.options.cursor, SystemMouseCursors.click);
      expect(TableFieldType.categories.cursor, SystemMouseCursors.click);
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
