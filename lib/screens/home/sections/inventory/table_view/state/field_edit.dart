/// Que hacer con un campo al salir de su celda, segun lo que quedo escrito.
///
/// La planilla no tiene botones de agregar, renombrar ni eliminar una columna:
/// las tres cosas son lo mismo —escribir en la celda del campo— y lo unico que
/// las distingue es que habia antes y que quedo despues. Esa regla vive aparte
/// de la pantalla porque es la que hay que poder leer de un vistazo (y probar
/// sin montar la planilla).
enum FieldEdit {
  /// El titulo quedo como estaba: entrar y salir de la celda no manda nada.
  none,

  /// Una columna libre a la que se le escribio un titulo: alta del campo.
  create,

  /// Un campo con otro titulo: renombre.
  rename,

  /// Un campo al que se le borro el titulo: baja. Es la unica que se pregunta
  /// antes, porque se lleva la columna y todo lo cargado en ella.
  delete;

  /// Decide el caso de la celda de la fila de campos que se acaba de dejar.
  ///
  /// [isField] dice si la columna ya es un campo de la tabla o todavia es una
  /// de las libres del final, [current] es el titulo que tenia y [text] lo que
  /// quedo escrito. Los espacios no cuentan: un titulo con solo espacios es un
  /// titulo vacio.
  static FieldEdit of({
    required bool isField,
    required String current,
    required String text
  }) {
    final name = text.trim();

    // Una columna libre que se deja en blanco sigue siendo libre: no hay nada
    // que crear ni que borrar.
    if (!isField) return name.isEmpty ? FieldEdit.none : FieldEdit.create;

    if (name == current.trim()) return FieldEdit.none;

    return name.isEmpty ? FieldEdit.delete : FieldEdit.rename;
  }
}
