import 'package:flutter/foundation.dart';

/// Una fila escrita y sin guardar. Guarda el texto de cada celda por posicion de
/// columna y si esa fila en particular se esta mandando, para que el spinner de
/// su numero de fila afecte solo a la fila que se guarda.
class SheetDraft {
  final Map<int, String> values = {};
  bool saving = false;

  /// `true` si la fila tiene algo escrito: es lo que la vuelve guardable.
  bool get hasData => values.values.any((value) => value.trim().isNotEmpty);
}

/// Las filas escritas que todavia no se guardaron, en el orden en que aparecen
/// debajo de los registros del backend.
///
/// Una fila en blanco **no tiene borrador**: recien se crea uno cuando se
/// escribe algo en ella, asi las decenas de filas vacias que muestra la planilla
/// (y las cientos de miles de filas de registros que hay encima) no cuestan
/// nada.
///
/// Notifica solo cuando cambia algo que se ve: que una fila pase de vacia a
/// escrita —ahi la planilla gana una fila y aparece otra en blanco detras—, que
/// empiece o termine de guardarse, o que se vaya. Cada tecla, en cambio, no
/// notifica: el texto ya lo esta mostrando el editor de esa celda.
///
/// Ese ultimo ahorro vale **porque hay un editor delante**. Las celdas que no lo
/// tienen —una lista, que se elige en un desplegable— dejan su valor por
/// [choose], que avisa siempre: ahi lo unico que muestra lo elegido es la propia
/// celda, y sin aviso no se rehace nadie.
class SheetDrafts extends ChangeNotifier {
  final List<SheetDraft> _drafts = [];

  int get length => _drafts.length;

  /// El borrador de esa fila, o `null` si todavia no se escribio nada en ella.
  SheetDraft? at(int index) =>
    index >= 0 && index < _drafts.length ? _drafts[index] : null;

  /// Lo que hay escrito en esa celda.
  String textAt(int index, int column) => at(index)?.values[column] ?? "";

  /// Vuelca el texto de una celda que se esta **escribiendo**.
  ///
  /// Una celda que queda vacia se borra del borrador, asi una fila que se vacia
  /// deja de contar como pendiente. Se avisa solo si la fila cambio de estado:
  /// escribir la segunda letra no mueve nada en pantalla, porque lo que se
  /// escribe ya lo esta mostrando el editor de esa celda.
  void write(int index, int column, String text) => _put(index, column, text);

  /// Vuelca el valor de una celda que se **elige** (una lista).
  ///
  /// Es [write] pero avisando siempre que el valor cambie: una celda de lista no
  /// tiene editor delante, asi que lo elegido no se ve hasta que ella misma se
  /// rehaga, y quien la rehace es este aviso. Es una vez por eleccion —un toque
  /// en un desplegable— y no una por tecla, que es lo que [write] ahorra.
  void choose(int index, int column, String value) =>
    _put(index, column, value, silent: false);

  /// El volcado de una celda al borrador. [silent] es lo unico que distingue las
  /// dos formas de dejar un valor: si alcanza con que la fila avise cuando
  /// cambia de estado, o si tiene que avisar tambien cuando solo cambio el valor.
  void _put(int index, int column, String text, {bool silent = true}) {
    if (index < 0) return;

    final had = at(index)?.hasData ?? false;
    final before = textAt(index, column);

    if (text.trim().isEmpty) {
      at(index)?.values.remove(column);
    } else {
      // Recien aca la fila en blanco se vuelve un borrador: escribir es lo que
      // la crea, no seleccionarla.
      while (_drafts.length <= index) {
        _drafts.add(SheetDraft());
      }
      _drafts[index].values[column] = text;
    }

    if (had != (at(index)?.hasData ?? false)) {
      notifyListeners();
      return;
    }

    if (silent || before == textAt(index, column)) return;
    notifyListeners();
  }

  void setSaving(SheetDraft draft, bool saving) {
    if (draft.saving == saving) return;

    draft.saving = saving;
    notifyListeners();
  }

  /// Saca una fila que ya quedo persistida: ahora es un registro de la tabla.
  ///
  /// Quien la saca tiene que hacerlo **en el mismo instante** en que la tabla
  /// empieza a contar el registro nuevo: las filas de aca abajo se ubican
  /// restando la cantidad de registros, asi que una cosa sin la otra las corre
  /// de lugar (ver `SheetController._dropPersisted`).
  void remove(SheetDraft draft) {
    if (!_drafts.remove(draft)) return;
    notifyListeners();
  }

  void clear() {
    if (_drafts.isEmpty) return;

    _drafts.clear();
    notifyListeners();
  }
}
