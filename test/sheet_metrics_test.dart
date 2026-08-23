import 'package:flutter_test/flutter_test.dart';

import 'package:app/screens/home/sections/inventory/table_view/state/sheet_metrics.dart';

/// La geometria de una planilla de filas de 40 y banda de numeros de 40, que es
/// como queda con los tamaños de la app.
const _metrics = SheetMetrics(rowHeight: 40, gutterWidth: 40);

void main() {
  test('las filas que entran descuentan la de campos', () {
    // La fila de campos esta congelada arriba y no se desplaza, asi que el
    // cuerpo tiene un alto de fila menos.
    expect(_metrics.visibleRows(440), 10);
  });

  test('debajo de lo escrito siempre sobran filas en blanco', () {
    // La planilla no termina en la ultima fila cargada: siempre hay donde
    // seguir escribiendo.
    expect(_metrics.bodyRows(used: 12, visible: 10), 17);
  });

  test('una busqueda termina en su ultima coincidencia', () {
    // Filtrada, la planilla mide exactamente lo que coincide: las filas en
    // blanco de abajo no serian para escribir —lo que se cargara ahi no seria
    // de la busqueda— sino renglones vacios haciendo creer que sigue.
    expect(_metrics.bodyRows(used: 3, visible: 30, blanks: false), 3);
  });

  test('una busqueda sin resultados no deja ni una fila', () {
    expect(_metrics.bodyRows(used: 0, visible: 30, blanks: false), 0);
  });

  test('una tabla corta llega igual hasta abajo de la pantalla', () {
    // Con dos registros y una pantalla de treinta filas, la planilla se dibuja
    // hasta el borde y no deja un hueco.
    expect(_metrics.bodyRows(used: 2, visible: 30), 30);
  });

  test('el rango visible sale de una division, no de construir filas', () {
    // Es lo que permite abrir una tabla de cientos de miles de registros: saber
    // que se ve es aritmetica sobre el offset.
    final (first, last) = _metrics.rangeAt(
      offset: 4000,
      viewport: 400,
      rows: 100000
    );

    expect(first, 100);
    expect(last, 110);
  });

  test('el rango no se sale de la tabla', () {
    final (first, last) = _metrics.rangeAt(offset: 0, viewport: 400, rows: 3);

    expect(first, 0);
    expect(last, 2);
  });

  test('una tabla sin filas no pide ningun rango', () {
    final (first, last) = _metrics.rangeAt(offset: 0, viewport: 400, rows: 0);

    expect(last < first, isTrue);
  });

  test('una fila que ya se ve no mueve la banda', () {
    expect(
      _metrics.revealRow(row: 3, offset: 0, viewport: 400, maxExtent: 4000),
      isNull
    );
  });

  test('una fila de mas arriba se trae desde su borde', () {
    expect(
      _metrics.revealRow(row: 2, offset: 400, viewport: 400, maxExtent: 4000),
      80
    );
  });

  test('una fila de mas abajo entra por el pie', () {
    // Se desplaza lo justo para que la fila entre entera abajo, no para
    // ponerla arriba de todo.
    expect(
      _metrics.revealRow(row: 12, offset: 0, viewport: 400, maxExtent: 4000),
      120
    );
  });

  test('la fila de campos nunca mueve la banda', () {
    // Esta congelada arriba: siempre se ve.
    expect(
      _metrics.revealRow(row: -1, offset: 800, viewport: 400, maxExtent: 4000),
      isNull
    );
  });

  test('una columna de mas a la derecha entra por el borde', () {
    expect(
      _metrics.revealColumn(
        left: 900,
        width: 150,
        offset: 0,
        viewport: 800,
        maxExtent: 2000
      ),
      250
    );
  });

  test('traer una celda no se pasa del final de la banda', () {
    expect(
      _metrics.revealRow(row: 200, offset: 0, viewport: 400, maxExtent: 500),
      500
    );
  });
}
