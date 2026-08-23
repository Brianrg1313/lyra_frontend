import 'package:flutter_test/flutter_test.dart';

import 'package:app/screens/home/sections/inventory/table_view/state/sheet_hover.dart';

void main() {
  test('arranca sin ninguna fila encendida', () {
    final hover = SheetHover();

    expect(hover.row, SheetHover.kNoRow);
    expect(hover.at(0), isFalse);
  });

  test('entrar en una fila la enciende y apaga la anterior', () {
    final hover = SheetHover();

    hover.enter(3);
    expect(hover.at(3), isTrue);

    hover.enter(4);
    expect(hover.at(4), isTrue);
    expect(hover.at(3), isFalse);
  });

  test('entrar de nuevo en la misma fila no avisa', () {
    // Es lo mas comun moviendo el mouse: se recorre una fila de punta a punta y
    // el puntero entra en una celda tras otra sin cambiar de fila.
    final hover = SheetHover();
    var notices = 0;

    hover.enter(2);
    hover.addListener(() => notices++);

    hover.enter(2);
    hover.enter(2);

    expect(notices, 0);
  });

  test('salir de una fila la apaga', () {
    final hover = SheetHover();

    hover.enter(1);
    hover.leave(1);

    expect(hover.row, SheetHover.kNoRow);
  });

  test('una salida que llega tarde no apaga la fila nueva', () {
    // Pasando rapido de una fila a la siguiente, el aviso de entrar en la de
    // abajo puede llegar antes que el de salir de la de arriba. Sin la
    // comprobacion, esa salida dejaria la planilla sin ninguna fila encendida
    // aunque el mouse este sobre una.
    final hover = SheetHover();

    hover.enter(5);
    hover.enter(6);
    hover.leave(5);

    expect(hover.at(6), isTrue);
  });

  test('salir de una fila que no estaba encendida no avisa', () {
    final hover = SheetHover();
    var notices = 0;

    hover.enter(7);
    hover.addListener(() => notices++);

    hover.leave(1);

    expect(notices, 0);
    expect(hover.at(7), isTrue);
  });

  test('se apaga entera cuando el mouse deja la planilla', () {
    final hover = SheetHover();

    hover.enter(9);
    hover.clear();

    expect(hover.row, SheetHover.kNoRow);
  });
}
