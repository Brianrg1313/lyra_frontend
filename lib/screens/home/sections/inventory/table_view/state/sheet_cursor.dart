import 'package:flutter/foundation.dart';

/// La fila de los campos es la fila 1 de la planilla; como el cuerpo se numera
/// desde 0 (el primer registro), a ella le toca el -1.
const int kFieldsRow = -1;

/// Celda de la planilla en coordenadas del cuerpo: la fila 0 es el primer
/// registro (la fila 2 de la planilla, porque la 1 son los campos, que es la
/// fila [kFieldsRow]) y la columna es la posicion dentro de las columnas de la
/// planilla.
class SheetCell {
  const SheetCell(this.row, this.column);

  final int row;
  final int column;

  bool at(int row, int column) => this.row == row && this.column == column;

  @override
  bool operator ==(Object other) =>
    other is SheetCell && other.row == row && other.column == column;

  @override
  int get hashCode => Object.hash(row, column);
}

/// Como esta una celda respecto del cursor.
///
/// Es lo que una celda necesita saber del cursor para pintar **su borde**, y por
/// eso es un valor y no tres booleanos sueltos: la celda se suscribe a esto, asi
/// que mover el cursor la vuelve a construir solo si cambio de estado. De las
/// cientos de celdas que hay en pantalla, eso son dos.
///
/// Su **fondo** es otra cosa y sale de otra pregunta ([SheetCursor.isRow]): el
/// cursor resalta la fila entera, asi que ahi lo que cambia son las dos filas.
enum SheetCellState {
  /// Ni elegida ni escribiendose.
  idle,

  /// Elegida, sin editor: es lo que queda al tocar una celda que no se escribe.
  selected,

  /// Elegida y con el editor de texto abierto.
  editing
}

/// La celda elegida y si se la esta escribiendo.
///
/// Vive aparte de la pantalla y notifica por su cuenta porque es lo que mas
/// seguido cambia: cada tecla de navegacion y cada toque lo mueven. Las celdas
/// se suscriben con `context.select(...)`, asi que mover el cursor vuelve a
/// construir **las dos filas** que cambiaron —la que se dejo y la que se tomo— y
/// no la planilla entera. Son dos filas y no dos celdas porque el cursor resalta
/// la fila donde esta parado, no solo su celda.
class SheetCursor extends ChangeNotifier {
  SheetCell? _cell;
  bool _editing = false;

  SheetCell? get cell => _cell;

  /// Fila del cursor, o `null` si no hay celda elegida. Lo mira la banda de
  /// numeros para resaltar la fila.
  int? get row => _cell?.row;

  int? get column => _cell?.column;

  /// `true` cuando la celda del cursor tiene el editor de texto abierto.
  /// Seleccionada sin editar es lo que queda al tocar una celda que no se puede
  /// escribir.
  bool get editing => _editing;

  bool isAt(int row, int column) => _cell?.at(row, column) ?? false;

  /// Como esta esa celda respecto del cursor. Es a lo que se suscribe cada
  /// celda de la planilla.
  SheetCellState stateAt(int row, int column) {
    if (!isAt(row, column)) return SheetCellState.idle;
    return _editing ? SheetCellState.editing : SheetCellState.selected;
  }

  /// `true` si el cursor esta en esa fila, sin importar la columna.
  bool isRow(int row) => _cell?.row == row;

  /// Mueve el cursor. No notifica si nada cambio: entrar y salir de la misma
  /// celda es lo mas comun al recorrer la planilla y no tiene por que repintar.
  void move(SheetCell? cell, {bool editing = false}) {
    if (_cell == cell && _editing == editing) return;

    _cell = cell;
    _editing = editing;
    notifyListeners();
  }

  /// Cierra el editor dejando la celda elegida.
  void stopEditing() {
    if (!_editing) return;

    _editing = false;
    notifyListeners();
  }

  void clear() => move(null);
}
