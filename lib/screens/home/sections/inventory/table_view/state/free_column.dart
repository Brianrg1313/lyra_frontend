/// Una columna libre del final de la planilla: su titulo mientras se escribe y
/// si ya se esta creando. Es un objeto y no un texto suelto porque el alta viaja
/// encolada y tiene que encontrar despues a su columna, aunque para entonces se
/// hayan corrido de lugar.
class FreeColumn {
  String name = "";
  bool creating = false;

  /// Una columna libre esta en blanco mientras no tenga titulo. La que se esta
  /// creando nunca lo esta: ya es de la tabla aunque el backend todavia no la
  /// devuelva.
  bool get isBlank => name.isEmpty && !creating;

  /// Deja [columns] con exactamente [free] columnas en blanco al final.
  ///
  /// Es la unica regla del crecimiento horizontal de la planilla, y se aplica
  /// despues de cada cambio de titulo: si se lleno la ultima libre, aparece otra
  /// detras; si una se vacio, se va la que sobra. Las del medio se respetan
  /// aunque esten en blanco: son un hueco que el usuario dejo a proposito.
  static void normalize(List<FreeColumn> columns, {int free = 2}) {
    while (columns.isNotEmpty && columns.last.isBlank) {
      columns.removeLast();
    }

    for (int i = 0; i < free; i++) {
      columns.add(FreeColumn());
    }
  }
}
