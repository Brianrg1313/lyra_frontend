import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/stock/tables/table_view_service.dart';

/// Una tabla de la que ya se leyo el primer tramo de 50 registros, que es como
/// queda apenas se abre.
TablePaging _opened() {
  final paging = TablePaging();

  paging.read(paging.request(0), 50);
  return paging;
}

void main() {
  test('al abrir solo se puede pedir el primer tramo', () {
    // Hasta que llegue una pagina no se sabe de a cuantos registros se lee, asi
    // que ninguna fila de mas abajo se puede traducir a una pagina.
    final paging = TablePaging();

    expect(paging.request(0), 1);
    expect(paging.request(900), 0);
  });

  test('la misma pagina no se pide dos veces', () {
    // Las cincuenta filas que se estan pintando piden todas su tramo: tiene que
    // salir una sola peticion.
    final paging = TablePaging();

    expect(paging.request(0), 1);
    expect(paging.request(0), 0);
  });

  test('con el primer tramo leido cada fila cae en su pagina', () {
    final paging = _opened();

    expect(paging.size, 50);
    expect(paging.pageOf(0), 1);
    expect(paging.pageOf(49), 1);
    expect(paging.pageOf(50), 2);
    expect(paging.pageOf(1286), 26);
    expect(paging.startOf(2), 50);
  });

  test('pedir por adelantado trae el tramo siguiente', () {
    // Es lo que hace la planilla: al pintar una fila pide tambien la de diez mas
    // abajo, asi el tramo siguiente sale antes de que se lo necesite.
    final paging = _opened();

    expect(paging.request(35 + 10), 0, reason: "todavia es el tramo leido");
    expect(paging.request(45 + 10), 2);
  });

  test('un salto al medio de la tabla pide solo ese tramo', () {
    // Arrastrar la barra hasta la fila 900 no tiene que leer las 18 paginas de
    // arriba: la fila se pide en el lugar donde esta.
    final paging = _opened();

    expect(paging.request(900), 19);
  });

  test('el tramo leido se guarda en su lugar de la tabla', () {
    final paging = _opened();

    expect(paging.read(paging.request(900), 50), 900);
    expect(paging.known, 950);
  });

  test('una pagina corta es el final de la tabla', () {
    final paging = _opened();
    paging.read(paging.request(50), 30);

    expect(paging.atEnd, isTrue);
    expect(paging.known, 80);
    expect(paging.request(85), 0, reason: "debajo del final se escribe, no se lee");
  });

  test('una tabla vacia no pide nada mas', () {
    final paging = TablePaging();
    paging.read(paging.request(0), 0);

    expect(paging.atEnd, isTrue);
    expect(paging.known, 0);
    expect(paging.request(0), 0);
  });

  test('un tramo que fallo no se vuelve a pedir solo', () {
    // La planilla pide sus filas en cada repintado y el error provoca uno: sin
    // esto, una pagina que falla se pediria en un bucle.
    final paging = _opened();
    paging.failed(paging.request(50));

    expect(paging.request(50), 0);
    expect(paging.isReading, isFalse);
  });

  test('reintentar vuelve a habilitar el tramo que fallo', () {
    final paging = _opened();
    paging.failed(paging.request(50));

    paging.retry();

    expect(paging.request(50), 2);
  });

  test('releer la tabla olvida lo leido pero no el tamaño del tramo', () {
    // Pasa despues de guardar una fila: hay un registro mas y corre a todos los
    // que van detras, pero se sigue leyendo de a cincuenta.
    final paging = _opened();

    paging.reset();

    expect(paging.size, 50);
    expect(paging.known, 0);
    expect(paging.atEnd, isFalse);
    expect(paging.request(900), 19);
  });
}
