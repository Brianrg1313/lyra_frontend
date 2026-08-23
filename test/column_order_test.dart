import 'package:flutter_test/flutter_test.dart';

import 'package:app/screens/home/sections/inventory/table_view/state/sheet_order.dart';
import 'package:app/services/stock/tables/table_structure_model.dart';

/// Los campos de una tabla, nombrados por su id para leer de un vistazo como
/// quedaron ordenados.
List<TableFieldModel> _fields(List<String> ids) =>
  [for (final id in ids) TableFieldModel(id: id, name: id.toUpperCase())];

List<String> _ids(List<TableFieldModel> fields) =>
  [for (final field in fields) field.id];

void main() {
  group('el orden que eligio el usuario', () {
    test('sin orden propio manda la estructura', () {
      // Es el caso de siempre: mientras no se haya arrastrado nada, no hay nada
      // que reordenar y se devuelve la misma lista, sin copiarla.
      final fields = _fields(["a", "b", "c"]);

      expect(identical(fieldsInOrder(fields, const []), fields), isTrue);
    });

    test('los campos se ponen en el orden guardado', () {
      final fields = _fields(["a", "b", "c"]);

      expect(_ids(fieldsInOrder(fields, ["c", "a", "b"])), ["c", "a", "b"]);
    });

    test('un campo nuevo va al final', () {
      // Una columna recien creada nace al final de la tabla, asi que ese es su
      // lugar aunque el orden guardado no la conozca. No corre a las demas.
      final fields = _fields(["a", "b", "nueva"]);

      expect(
        _ids(fieldsInOrder(fields, ["c", "b", "a"])),
        ["b", "a", "nueva"]
      );
    });

    test('un campo que ya no esta se ignora', () {
      // La columna se elimino desde otra pantalla (o desde otro cliente): el
      // orden guardado la sigue nombrando y no pasa nada.
      final fields = _fields(["a", "c"]);

      expect(_ids(fieldsInOrder(fields, ["c", "b", "a"])), ["c", "a"]);
    });

    test('un campo sin id no se ordena', () {
      // Sin FIELD_ID no hay con que emparejarlo, asi que queda al final en vez
      // de colarse en cualquier lado.
      final fields = _fields(["a", "", "b"]);

      expect(_ids(fieldsInOrder(fields, ["b", "a"])), ["b", "a", ""]);
    });

    test('una tabla de una sola columna no se reordena', () {
      final fields = _fields(["a"]);

      expect(identical(fieldsInOrder(fields, ["a"]), fields), isTrue);
    });
  });

  group('mover una columna', () {
    const order = ["a", "b", "c", "d"];

    test('hacia la derecha cae detras del borde', () {
      // El borde 3 es el hueco entre "c" y "d": sacar "a" corre todo un lugar,
      // asi que termina justo detras de "c".
      expect(movedOrder(order, from: 0, to: 3), ["b", "c", "a", "d"]);
    });

    test('hacia la izquierda cae delante del borde', () {
      expect(movedOrder(order, from: 3, to: 1), ["a", "d", "b", "c"]);
    });

    test('al principio y al final', () {
      expect(movedOrder(order, from: 2, to: 0), ["c", "a", "b", "d"]);
      expect(movedOrder(order, from: 0, to: 4), ["b", "c", "d", "a"]);
    });

    test('soltarla donde estaba no la mueve', () {
      // Los dos bordes que rodean a la columna la dejan igual, y se devuelve la
      // misma lista para que quien llama no gaste un repintado en nada.
      expect(identical(movedOrder(order, from: 1, to: 1), order), isTrue);
      expect(identical(movedOrder(order, from: 1, to: 2), order), isTrue);
    });

    test('un borde o una columna que no existen no mueven nada', () {
      expect(identical(movedOrder(order, from: -1, to: 2), order), isTrue);
      expect(identical(movedOrder(order, from: 9, to: 2), order), isTrue);
      expect(identical(movedOrder(order, from: 0, to: 9), order), isTrue);
    });
  });

  group('donde cae la columna que se suelta', () {
    // Cuatro columnas de 100 y detras una libre, que no recibe nada.
    const edges = [0.0, 100.0, 200.0, 300.0, 400.0, 500.0];

    test('la linea salta al pasar el medio de la vecina', () {
      expect(dropEdgeAt(edges, 49, columns: 4), 0);
      expect(dropEdgeAt(edges, 51, columns: 4), 1);
      expect(dropEdgeAt(edges, 149, columns: 4), 1);
      expect(dropEdgeAt(edges, 151, columns: 4), 2);
    });

    test('detras de la ultima columna cae al final', () {
      expect(dropEdgeAt(edges, 380, columns: 4), 4);
    });

    test('sobre las columnas libres tampoco pasa del final', () {
      // Detras de los campos estan las libres: no son columnas de la tabla, asi
      // que soltar ahi es soltar al final.
      expect(dropEdgeAt(edges, 460, columns: 4), 4);
      expect(dropEdgeAt(edges, 9999, columns: 4), 4);
    });

    test('antes de la primera cae al principio', () {
      expect(dropEdgeAt(edges, -50, columns: 4), 0);
    });
  });

  group('de donde lee cada columna', () {
    test('sin mover nada, cada una lee de su lugar', () {
      final fields = _fields(["a", "b", "c"]);

      expect(slotsOf(fields, fields, free: 2), [0, 1, 2, 3, 4]);
    });

    test('moverlas cambia por donde leen, no los datos', () {
      // Es todo lo que cuesta arrastrar una columna en una tabla de cientos de
      // miles de registros: tres enteros de lugar.
      final fields = _fields(["a", "b", "c"]);
      final ordered = fieldsInOrder(fields, ["c", "a", "b"]);

      expect(slotsOf(fields, ordered, free: 2), [2, 0, 1, 3, 4]);
    });

    test('las libres del final leen de detras de todos los campos', () {
      // Es el lugar que les tocaria si se crearan, que es lo que hace que lo
      // escrito en una siga ahi cuando la columna pasa a ser un campo.
      final fields = _fields(["a", "b"]);

      expect(slotsOf(fields, fields, free: 2), [0, 1, 2, 3]);
    });

    test('una tabla sin campos es todo columnas libres', () {
      expect(slotsOf(const [], const [], free: 2), [0, 1]);
    });
  });
}
