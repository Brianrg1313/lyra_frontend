import 'package:flutter_test/flutter_test.dart';

import 'package:app/screens/home/sections/inventory/table_view/state/free_column.dart';

/// Titulos de las columnas libres, para leer de un vistazo como quedo la cola
/// de la planilla ("" es una columna en blanco).
List<String> _titles(List<FreeColumn> columns) =>
  [for (final column in columns) column.name];

void main() {
  test('la planilla arranca con dos columnas libres', () {
    final columns = <FreeColumn>[];

    FreeColumn.normalize(columns);

    expect(_titles(columns), ["", ""]);
  });

  test('poner un titulo deja otra libre detras', () {
    final columns = <FreeColumn>[];
    FreeColumn.normalize(columns);

    // Se escribe en la primera libre: la cola tiene que volver a tener dos.
    columns.first.name = "Precio";
    FreeColumn.normalize(columns);

    expect(_titles(columns), ["Precio", "", ""]);
  });

  test('vaciar un titulo se lleva la columna que sobra', () {
    final columns = <FreeColumn>[];
    FreeColumn.normalize(columns);
    columns.first.name = "Precio";
    FreeColumn.normalize(columns);

    columns.first.name = "";
    FreeColumn.normalize(columns);

    expect(_titles(columns), ["", ""]);
  });

  test('dos titulos seguidos dejan las dos libres al final', () {
    final columns = <FreeColumn>[];
    FreeColumn.normalize(columns);

    columns[0].name = "Precio";
    FreeColumn.normalize(columns);
    columns[1].name = "Stock";
    FreeColumn.normalize(columns);

    expect(_titles(columns), ["Precio", "Stock", "", ""]);
  });

  test('un hueco en el medio se respeta', () {
    // Escribir en la segunda libre dejando la primera en blanco: ese hueco es
    // del usuario y no se cierra solo, pero detras siguen sobrando dos.
    final columns = <FreeColumn>[];
    FreeColumn.normalize(columns);

    columns[1].name = "Stock";
    FreeColumn.normalize(columns);

    expect(_titles(columns), ["", "Stock", "", ""]);
  });

  test('la columna que se esta creando no se descarta', () {
    // Mientras el alta viaja, la columna no tiene titulo que mostrar todavia en
    // la tabla pero ya es de la tabla: sacarla la haria desaparecer a mitad de
    // camino.
    final columns = <FreeColumn>[];
    FreeColumn.normalize(columns);

    columns.first
      ..name = "Precio"
      ..creating = true;
    FreeColumn.normalize(columns);

    expect(columns.first.creating, isTrue);
    expect(_titles(columns), ["Precio", "", ""]);
  });

  test('normalizar dos veces seguidas no agrega columnas de mas', () {
    // Regresion: cada tecla normaliza, asi que la operacion tiene que ser
    // idempotente o la planilla se llenaria de columnas vacias.
    final columns = <FreeColumn>[];

    FreeColumn.normalize(columns);
    FreeColumn.normalize(columns);
    FreeColumn.normalize(columns);

    expect(_titles(columns), ["", ""]);
  });
}
