import 'package:flutter/services.dart';

import 'sheet_cursor.dart';

/// Lo que una tecla le pide a la planilla.
///
/// La navegacion es la de un Excel: Tab y Shift+Tab se mueven de celda, Enter y
/// las flechas arriba/abajo bajan y suben, Escape cancela lo que se estaba
/// escribiendo. Mientras se escribe, las flechas izquierda y derecha se dejan
/// pasar —mueven el cursor dentro del texto, que es lo que se espera de una
/// celda abierta— y sin editor, en cambio, cambian de columna.
///
/// Vive aparte del manejador de foco para poder leerse (y probarse) sin montar
/// la planilla.
enum SheetKeyIntent {
  /// Tab: la celda siguiente, dando la vuelta de linea al pasarse.
  nextCell,

  /// Shift+Tab: la celda anterior, con la misma vuelta.
  previousCell,

  rowDown,
  rowUp,
  columnRight,
  columnLeft,

  /// Escape: deshacer lo escrito en la celda.
  cancel;

  /// Cuanto mueve el cursor, o `null` si no es un movimiento.
  ({int rows, int columns, bool wrap})? get move => switch (this) {
    nextCell => (rows: 0, columns: 1, wrap: true),
    previousCell => (rows: 0, columns: -1, wrap: true),
    rowDown => (rows: 1, columns: 0, wrap: false),
    rowUp => (rows: -1, columns: 0, wrap: false),
    columnRight => (rows: 0, columns: 1, wrap: false),
    columnLeft => (rows: 0, columns: -1, wrap: false),
    cancel => null
  };

  /// Que pide esa tecla, o `null` si la planilla no la usa y tiene que seguir su
  /// camino.
  static SheetKeyIntent? of(
    LogicalKeyboardKey key, {
    required bool shift,
    required bool editing
  }) {
    if (key == LogicalKeyboardKey.tab) {
      return shift ? previousCell : nextCell;
    }

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      return shift ? rowUp : rowDown;
    }

    if (key == LogicalKeyboardKey.arrowDown) return rowDown;
    if (key == LogicalKeyboardKey.arrowUp) return rowUp;

    // Con el editor abierto estas dos son del texto, no de la grilla.
    if (!editing && key == LogicalKeyboardKey.arrowRight) return columnRight;
    if (!editing && key == LogicalKeyboardKey.arrowLeft) return columnLeft;

    if (editing && key == LogicalKeyboardKey.escape) return cancel;

    return null;
  }
}

/// Adonde cae el cursor al moverlo [rows] filas y [columns] columnas desde
/// [from].
///
/// Con [wrap] (lo que hace Tab) pasarse de la ultima columna sigue en la primera
/// de la fila siguiente; sin el, el cursor se queda pegado al borde. Hacia
/// arriba se llega a la fila de los campos, que es una fila mas de la planilla y
/// se recorre igual.
///
/// La fila que devuelve puede caer **debajo** del final de la planilla: pasarse
/// de la ultima fila agrega otra en blanco, y eso no lo decide esta cuenta sino
/// quien la llama, que es el que sabe cuantas filas hay.
SheetCell sheetDestination({
  required SheetCell from,
  required int rows,
  required int columns,
  required bool wrap,
  required int lastColumn
}) {
  int row = from.row + rows;
  int column = from.column + columns;

  if (column > lastColumn) {
    if (!wrap) {
      column = lastColumn;
    } else {
      column = 0;
      row += 1;
    }
  } else if (column < 0) {
    if (!wrap) {
      column = 0;
    } else {
      column = lastColumn;
      row -= 1;
    }
  }

  if (row < kFieldsRow) row = kFieldsRow;

  return SheetCell(row, column);
}
