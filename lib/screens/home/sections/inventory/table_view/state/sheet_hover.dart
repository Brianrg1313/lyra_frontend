import 'package:flutter/foundation.dart';

/// La fila que tiene el puntero encima.
///
/// Es un estado propio y no una parte del [SheetCursor] porque son dos cosas
/// distintas que se parecen: el cursor es **donde se esta parado** —lo mueven
/// las teclas y los toques, y sobrevive a que el mouse se vaya de la pantalla—,
/// y esto es **por donde esta pasando el mouse**, que no elige nada y se pierde
/// en cuanto el puntero sale.
///
/// Notifica por su cuenta por lo mismo que el cursor: cambia con cada
/// movimiento del mouse entre filas, asi que si esto colgara del estado de la
/// pantalla, recorrer la planilla con el mouse la repintaria entera. Cada celda
/// se suscribe con `context.select(...at(fila))`, que es un booleano: pasar el
/// mouse de una fila a otra corre el comparador de las celdas que se ven y
/// vuelve a construir **las dos filas** que cambiaron, no la planilla.
///
/// [kNoRow] es "ninguna", y es un numero y no un nulo para que [at] sea una
/// comparacion pelada: la contestan todas las celdas visibles en cada
/// movimiento.
class SheetHover extends ChangeNotifier {
  /// Ninguna fila. Es un indice que no existe: las filas empiezan en 0.
  static const int kNoRow = -1;

  int _row = kNoRow;

  /// La fila bajo el puntero, o [kNoRow] si el mouse no esta sobre ninguna.
  int get row => _row;

  /// `true` si el puntero esta en esa fila. Es a lo que se suscribe cada celda.
  bool at(int row) => _row == row;

  /// El puntero entro en [row].
  void enter(int row) {
    if (_row == row) return;

    _row = row;
    notifyListeners();
  }

  /// El puntero salio de [row].
  ///
  /// Se pide con la fila y no a secas porque los avisos de entrar y salir no
  /// llegan siempre en ese orden: pasando rapido de una fila a la siguiente, el
  /// `onEnter` de la de abajo puede llegar antes que el `onExit` de la de
  /// arriba, y sin esta comprobacion esa salida apagaria el resaltado de la fila
  /// que el puntero ya tiene encima.
  void leave(int row) {
    if (_row != row) return;

    _row = kNoRow;
    notifyListeners();
  }

  /// Apaga el resaltado, sea cual sea la fila. Para cuando el mouse se va de la
  /// planilla entera.
  void clear() => leave(_row);
}
