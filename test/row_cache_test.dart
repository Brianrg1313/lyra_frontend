import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/stock/tables/table_view_service.dart';

/// El cache de filas de una tabla abierta: cuanto se guarda de lo leido y que se
/// descarta cuando ya no entra.
///
/// Importa a partir de unos cuantos miles de registros: sin techo, recorrer una
/// tabla de punta a punta la deja entera en memoria.
void main() {
  group('cual pagina se descarta', () {
    test('mientras entren en el presupuesto no se descarta ninguna', () {
      expect(pageToForget([1, 2, 3], around: 3, budget: 3), isNull);
    });

    test('se va la mas lejana de donde se esta mirando', () {
      // Se esta leyendo la 10: la 1 es la que menos chances tiene de volver a
      // hacer falta.
      expect(pageToForget([1, 8, 9, 10], around: 10, budget: 3), 1);
    });

    test('subiendo se descarta la de mas abajo', () {
      // Y no la mas vieja: descartar por antiguedad tiraria justo la pagina de
      // al lado, que es la que se esta por volver a mirar.
      expect(pageToForget([1, 2, 3, 40], around: 2, budget: 3), 40);
    });
  });

  group('lo leido sobrevive a un cambio de columnas', () {
    // Un cambio de columna relee la estructura entera. Tirar las paginas por eso
    // significaba que tocar el titulo de una columna en la fila cincuenta mil
    // obligaba a bajar la tabla de nuevo.
    test('renombrar una columna no mueve ningun valor', () {
      // Los FIELD_ID son los mismos y en el mismo orden.
      expect(fieldsGrewAtEnd(["a", "b"], ["a", "b"]), isTrue);
    });

    test('una columna nueva al final solo deja las filas cortas', () {
      // Esa celda se ve vacia, que es exactamente lo que le toca a un campo
      // recien creado.
      expect(fieldsGrewAtEnd(["a", "b"], ["a", "b", "c"]), isTrue);
    });

    test('la primera columna de una tabla sin campos no tira nada', () {
      expect(fieldsGrewAtEnd([], ["a"]), isTrue);
    });

    test('eliminar una columna corre todos los valores de lugar', () {
      expect(fieldsGrewAtEnd(["a", "b", "c"], ["a", "c"]), isFalse);
    });

    test('una columna nueva en el medio tambien', () {
      expect(fieldsGrewAtEnd(["a", "b"], ["a", "c", "b"]), isFalse);
    });

    test('que el backend los devuelva en otro orden tambien', () {
      expect(fieldsGrewAtEnd(["a", "b"], ["b", "a"]), isFalse);
    });
  });

  group('y a que los campos cambien de lugar', () {
    // Lo que [fieldsGrewAtEnd] descarta casi siempre se puede salvar igual: los
    // valores de una fila leida siguen ahi, solo que en otra posicion. Importa
    // desde que las columnas se arrastran, porque si no cada arrastre tiraria
    // las paginas que se estaban mirando.
    test('reordenarlas solo corre los valores de lugar', () {
      expect(fieldsRemap(["a", "b", "c"], ["c", "a", "b"]), [2, 0, 1]);
    });

    test('eliminar una columna deja las demas donde estaban', () {
      expect(fieldsRemap(["a", "b", "c"], ["a", "c"]), [0, 2]);
    });

    test('una columna nueva queda vacia', () {
      // Es lo que le toca: todavia no hay nada cargado en ella.
      expect(fieldsRemap(["a", "b"], ["a", "nueva", "b"]), [0, -1, 1]);
    });

    test('sin FIELD_ID no hay con que emparejarlas', () {
      // Ahi lo unico seguro es volver a pedir las filas.
      expect(fieldsRemap(["a", ""], ["a", "b"]), isNull);
    });

    test('con ids repetidos tampoco', () {
      expect(fieldsRemap(["a", "a"], ["a"]), isNull);
    });

    test('una tabla que no tenia campos no tiene nada que reacomodar', () {
      // Sus filas no estan alineadas contra ningun campo.
      expect(fieldsRemap([], ["a"]), isNull);
    });
  });

  group('una pagina olvidada se puede volver a pedir', () {
    test('olvidarla la saca de las leidas', () {
      final paging = TablePaging();
      paging.read(paging.request(0), 50);
      paging.read(paging.request(900), 50);

      expect(paging.request(900), 0, reason: "ya esta leida");

      paging.forget(paging.pageOf(900));

      expect(paging.request(900), 19);
    });

    test('olvidar no cambia de a cuantos se lee ni donde termina', () {
      final paging = TablePaging();
      paging.read(paging.request(0), 50);
      paging.read(paging.request(50), 20);

      paging.forget(1);

      expect(paging.size, 50);
      expect(paging.atEnd, isTrue);
      expect(paging.known, 70);
    });

    test('una pagina que fallo tambien se puede olvidar', () {
      final paging = TablePaging();
      paging.read(paging.request(0), 50);
      paging.failed(paging.request(50));

      paging.forget(2);

      expect(paging.request(50), 2);
    });
  });
}
