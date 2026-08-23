import 'package:flutter_test/flutter_test.dart';

import 'package:app/screens/home/sections/inventory/table_view/state/sheet_dates.dart';

void main() {
  test('una columna de fechas arranca escrita', () {
    // Es la lectura de todos los dias: la que se entiende de un vistazo. La de
    // cifras se pide.
    final dates = SheetDates();

    expect(dates.isFull("field_1"), isFalse);
  });

  test('el boton la pasa de una lectura a la otra', () {
    final dates = SheetDates();

    dates.toggle("field_1");
    expect(dates.isFull("field_1"), isTrue);

    dates.toggle("field_1");
    expect(dates.isFull("field_1"), isFalse);
  });

  test('cada columna se lee como quiera, sin arrastrar a las demas', () {
    // Una tabla puede tener la fecha de alta y la de vencimiento: mirar la hora
    // de una no tiene por que llenar de ceros la otra.
    final dates = SheetDates();

    dates.toggle("field_1");

    expect(dates.isFull("field_1"), isTrue);
    expect(dates.isFull("field_2"), isFalse);
  });

  test('cambiar el formato avisa una sola vez', () {
    final dates = SheetDates();
    var notices = 0;

    dates.addListener(() => notices++);

    dates.toggle("field_1");

    expect(notices, 1);
  });
}
