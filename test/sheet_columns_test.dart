import 'package:flutter_test/flutter_test.dart';

import 'package:app/screens/home/sections/inventory/table_view/state/sheet_columns.dart';
import 'package:app/services/stock/tables/table_view_service.dart';

/// Las columnas de una tabla recien abierta: sin campos todavia, solo las libres
/// del final. Es lo que se ve mientras la estructura viaja, y tambien lo que
/// queda para siempre en una tabla a la que nunca se le creo un campo.
SheetColumns _columns() => SheetColumns(TableViewService());

/// Los titulos de las columnas, para leer de un vistazo como quedo la planilla
/// ("" es una columna en blanco).
List<String> _titles(SheetColumns columns) =>
  [for (int i = 0; i < columns.length; i++) columns.nameOf(i)];

void main() {
  test('una tabla sin campos igual tiene donde escribir', () {
    // No es un callejon sin salida: las columnas libres del final son las que
    // dejan crear el primer campo escribiendo su titulo encima.
    final columns = _columns();

    expect(_titles(columns), ["", ""]);
    expect(columns.fieldCount, 0);
    expect(columns.canEditAt(0), isTrue);
  });

  test('escribir en la ultima libre hace aparecer otra detras', () {
    final columns = _columns();

    expect(columns.writeFree(0, "Precio"), isTrue);
    expect(_titles(columns), ["Precio", "", ""]);
  });

  test('cambiar el texto sin ganar ni perder columnas no avisa', () {
    // Cada tecla pasa por aca. Avisar por una letra que no cambia la forma de la
    // planilla seria repintar la fila de campos en cada pulsacion; lo que se
    // escribe ya lo esta mostrando el editor de esa celda.
    final columns = _columns();
    columns.writeFree(0, "P");

    int notices = 0;
    columns.addListener(() => notices += 1);

    expect(columns.writeFree(0, "Pre"), isFalse);
    expect(columns.writeFree(0, "Precio"), isFalse);
    expect(notices, 0);
  });

  test('vaciar el titulo se lleva la columna que sobra', () {
    final columns = _columns();
    columns.writeFree(0, "Precio");

    expect(columns.writeFree(0, ""), isTrue);
    expect(_titles(columns), ["", ""]);
  });

  test('mientras el alta viaja la columna se ve ocupada y no se escribe', () {
    final columns = _columns();
    columns.writeFree(0, "Precio");
    final free = columns.freeAt(0)!;

    columns.startCreate(free);

    expect(columns.busyAt(0), isTrue);
    expect(columns.canEditAt(0), isFalse);
  });

  test('un alta que falla deja la columna lista para reintentar', () {
    final columns = _columns();
    columns.writeFree(0, "Precio");
    final free = columns.freeAt(0)!;
    columns.startCreate(free);

    columns.endCreate(free, created: false);

    expect(columns.busyAt(0), isFalse);
    expect(_titles(columns), ["Precio", "", ""]);
  });

  test('un alta que sale bien saca la columna libre', () {
    // La columna ya no es libre: la trae la estructura, que se acaba de releer.
    final columns = _columns();
    columns.writeFree(0, "Precio");
    final free = columns.freeAt(0)!;
    columns.startCreate(free);

    columns.endCreate(free, created: true);

    expect(_titles(columns), ["", ""]);
  });

  test('la clave de ancho de una columna libre es su posicion', () {
    // Sin FIELD_ID no hay con que recordarla: se cae en el lugar que ocupa.
    final columns = _columns();

    expect(columns.keyOf(0), "col_0");
    expect(columns.keys, ["col_0", "col_1"]);
  });

  group('la forma de la planilla', () {
    // Las claves son lo que escucha la grilla. Mientras sean la misma instancia
    // la planilla no se rehace, asi que lo que se prueba aca es que cambien
    // cuando —y solo cuando— la planilla gana o pierde una columna.
    test('sin cambios son siempre la misma instancia', () {
      final columns = _columns();

      expect(identical(columns.keys, columns.keys), isTrue);
    });

    test('un renombre en camino no cambia la forma', () {
      // Es lo que evita que renombrar una columna cueste la grilla entera: el
      // titulo lo escucha su celda, y no es una de las claves.
      final columns = _columns();
      final before = columns.keys;

      columns.startRename("field-1", "Precio");

      expect(identical(columns.keys, before), isTrue);
    });

    test('una baja en camino tampoco', () {
      // La columna sigue estando hasta que la estructura vuelva sin ella.
      final columns = _columns();
      final before = columns.keys;

      columns.startDelete("field-1");

      expect(identical(columns.keys, before), isTrue);
    });

    test('mandar el alta de una columna libre tampoco', () {
      // Ya esta dibujada desde que se le escribio el titulo; el alta solo la
      // pone en gris hasta que vuelve.
      final columns = _columns();
      columns.writeFree(0, "Precio");
      final before = columns.keys;

      columns.startCreate(columns.freeAt(0)!);

      expect(identical(columns.keys, before), isTrue);
    });

    test('ganar una columna si la cambia', () {
      final columns = _columns();
      final before = columns.keys;

      columns.writeFree(0, "Precio");

      expect(identical(columns.keys, before), isFalse);
      expect(columns.keys, ["col_0", "col_1", "col_2"]);
    });

    test('seguir escribiendo el titulo no la vuelve a cambiar', () {
      final columns = _columns();
      columns.writeFree(0, "P");
      final before = columns.keys;

      columns.writeFree(0, "Precio");

      expect(identical(columns.keys, before), isTrue);
    });
  });

  group('arrastrar una columna', () {
    test('las libres del final no se mueven', () {
      // Todavia no son campos de la tabla: no hay posicion que guardar ni nada
      // que reordenar.
      final columns = _columns();

      expect(columns.reorder(0, 2), isNull);
      expect(columns.reorder(1, 0), isNull);
    });

    test('un borde que no existe no mueve nada', () {
      final columns = _columns();

      expect(columns.reorder(0, -1), isNull);
      expect(columns.reorder(0, 9), isNull);
    });

    test('volver a un orden que ya es el de ahora no avisa', () {
      final columns = _columns();

      int notices = 0;
      columns.addListener(() => notices += 1);

      columns.restoreOrder(const []);

      expect(notices, 0);
    });
  });

  test('cada columna libre lee de su propio lugar de la fila', () {
    // No hay donde guardar hasta que se creen, pero lo que se escriba en cada
    // una necesita un lugar propio en el borrador: sin eso, dos columnas en
    // blanco se pisarian el texto.
    final columns = _columns();

    expect(columns.shape.slots, [0, 1]);
    expect(columns.slotAt(0), 0);
    expect(columns.slotAt(1), 1);
  });

  test('una columna libre no tiene tipo ni es un campo', () {
    // Es lo que hace que sus celdas se vean pero no se escriban: no hay donde
    // guardar hasta que la columna se cree.
    final columns = _columns();

    expect(columns.typeOf(0), "");
    expect(columns.isFieldAt(0), isFalse);
  });

  test('una columna fuera de la planilla no existe', () {
    final columns = _columns();

    expect(columns.at(9), isNull);
    expect(columns.canEditAt(9), isFalse);
    expect(columns.nameOf(9), "");
  });
}
