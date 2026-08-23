import 'package:flutter/foundation.dart';

/// Que columnas de fecha se estan mirando completas.
///
/// Una fecha se lee de dos maneras distintas y las dos hacen falta: escrita
/// (`Feb 12, 2026`) es la que se entiende de un vistazo, y en cifras con su hora
/// (`2026-02-12 12:30 PM`) es la que se compara, se copia y se controla. El
/// boton de la celda pasa de una a la otra.
///
/// **Es de la columna y no de la celda.** Una columna de fechas se lee como una
/// tira: si cada fila pudiera estar en un formato distinto, dos fechas de la
/// misma columna dejarian de compararse de un vistazo, que es justo lo que una
/// planilla tiene que dar. Asi que el boton de cualquier fila cambia la columna
/// entera, como el formato de una columna de Excel.
///
/// Se recuerda por la clave de la columna —el FIELD_ID, la misma con la que
/// [SheetWidths] recuerda su ancho— y no por su posicion: arrastrar la columna
/// de lugar se lleva el formato con ella.
///
/// Es un notificador propio, y minusculo, por lo mismo que el resto: cambiar el
/// formato tiene que costar las celdas de esa columna y nada mas. Cada celda de
/// fecha se suscribe a **su** clave, asi que el comparador de las demas devuelve
/// lo de siempre y no se rehacen.
class SheetDates extends ChangeNotifier {
  final Set<String> _full = {};

  /// Si esa columna se esta mirando en cifras y con hora.
  bool isFull(String column) => _full.contains(column);

  /// Pasa la columna de una lectura a la otra.
  void toggle(String column) {
    if (!_full.remove(column)) _full.add(column);
    notifyListeners();
  }
}
