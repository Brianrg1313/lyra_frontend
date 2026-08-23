import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/screens/home/sections/inventory/table_view/state/sheet_cursor.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_keys.dart';

/// Lo que pide una tecla estando fuera del editor (recorriendo la planilla).
SheetKeyIntent? _key(LogicalKeyboardKey key, {bool shift = false}) =>
  SheetKeyIntent.of(key, shift: shift, editing: false);

/// Lo mismo, pero con la celda abierta y escribiendose.
SheetKeyIntent? _typing(LogicalKeyboardKey key, {bool shift = false}) =>
  SheetKeyIntent.of(key, shift: shift, editing: true);

void main() {
  group('que pide cada tecla', () {
    test('Tab va a la celda siguiente y Shift+Tab a la anterior', () {
      expect(_key(LogicalKeyboardKey.tab), SheetKeyIntent.nextCell);
      expect(
        _key(LogicalKeyboardKey.tab, shift: true),
        SheetKeyIntent.previousCell
      );
    });

    test('Enter baja de fila, como en una planilla', () {
      expect(_key(LogicalKeyboardKey.enter), SheetKeyIntent.rowDown);
      expect(_key(LogicalKeyboardKey.numpadEnter), SheetKeyIntent.rowDown);
      expect(
        _key(LogicalKeyboardKey.enter, shift: true),
        SheetKeyIntent.rowUp
      );
    });

    test('escribiendo, las flechas de los costados son del texto', () {
      // Mueven el cursor dentro de lo que se esta escribiendo, que es lo que se
      // espera de una celda abierta.
      expect(_typing(LogicalKeyboardKey.arrowRight), isNull);
      expect(_typing(LogicalKeyboardKey.arrowLeft), isNull);

      // Sin editor, en cambio, cambian de columna.
      expect(_key(LogicalKeyboardKey.arrowRight), SheetKeyIntent.columnRight);
      expect(_key(LogicalKeyboardKey.arrowLeft), SheetKeyIntent.columnLeft);
    });

    test('las flechas de arriba y abajo siempre son de la grilla', () {
      expect(_typing(LogicalKeyboardKey.arrowDown), SheetKeyIntent.rowDown);
      expect(_typing(LogicalKeyboardKey.arrowUp), SheetKeyIntent.rowUp);
    });

    test('Escape solo cancela si hay algo escribiendose', () {
      expect(_typing(LogicalKeyboardKey.escape), SheetKeyIntent.cancel);
      expect(
        _key(LogicalKeyboardKey.escape),
        isNull,
        reason: "sin editor, el Escape cierra lo que haya abierto arriba"
      );
    });

    test('una tecla cualquiera sigue su camino', () {
      expect(_key(LogicalKeyboardKey.keyA), isNull);
    });
  });

  group('adonde cae el cursor', () {
    /// Una planilla de cuatro columnas (la ultima es la 3).
    SheetCell move(
      SheetCell from,
      SheetKeyIntent intent, {
      int lastColumn = 3
    }) {
      final step = intent.move!;

      return sheetDestination(
        from: from,
        rows: step.rows,
        columns: step.columns,
        wrap: step.wrap,
        lastColumn: lastColumn
      );
    }

    test('Tab en la ultima columna sigue en la fila de abajo', () {
      expect(
        move(const SheetCell(2, 3), SheetKeyIntent.nextCell),
        const SheetCell(3, 0)
      );
    });

    test('Shift+Tab en la primera columna vuelve al final de la de arriba', () {
      expect(
        move(const SheetCell(2, 0), SheetKeyIntent.previousCell),
        const SheetCell(1, 3)
      );
    });

    test('la flecha derecha se queda pegada al ultimo borde', () {
      // Sin vuelta de linea: la flecha no cambia de fila.
      expect(
        move(const SheetCell(2, 3), SheetKeyIntent.columnRight),
        const SheetCell(2, 3)
      );
    });

    test('subiendo se llega a la fila de los campos y ahi se para', () {
      // La fila de campos es una fila mas de la planilla y se recorre igual,
      // pero arriba de ella no hay nada.
      expect(
        move(const SheetCell(0, 1), SheetKeyIntent.rowUp),
        const SheetCell(kFieldsRow, 1)
      );
      expect(
        move(const SheetCell(kFieldsRow, 1), SheetKeyIntent.rowUp),
        const SheetCell(kFieldsRow, 1)
      );
    });

    test('bajar no tiene tope: la planilla sigue', () {
      // Pasarse de la ultima fila agrega otra en blanco, y eso lo resuelve quien
      // sabe cuantas hay, no esta cuenta.
      expect(
        move(const SheetCell(999999, 0), SheetKeyIntent.rowDown),
        const SheetCell(1000000, 0)
      );
    });

    test('con una sola columna, Tab baja de fila', () {
      expect(
        move(const SheetCell(1, 0), SheetKeyIntent.nextCell, lastColumn: 0),
        const SheetCell(2, 0)
      );
    });
  });
}
