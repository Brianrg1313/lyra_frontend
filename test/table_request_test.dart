import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/inventory/table_request.dart';

void main() {
  test('el alta manda titulo, descripcion y color', () {
    final body = createTableRequest(
      title: "Vinos",
      description: "Catalogo de la bodega",
      color: "0xFF60A5FA"
    );

    expect(body, {
      "TITLE": "Vinos",
      "DESCRIPTION": "Catalogo de la bodega",
      "COLOR": "0xFF60A5FA"
    });

    // El cuerpo viaja tal cual por la api, asi que tiene que ser serializable.
    expect(jsonDecode(jsonEncode(body)), body);
  });

  test('sin descripcion la clave no viaja', () {
    // El backend distingue "sin descripcion" de "descripcion en blanco".
    final body = createTableRequest(
      title: "  Vinos  ",
      description: "   ",
      color: "0xFFF87171"
    );

    expect(body.containsKey("DESCRIPTION"), isFalse);
    expect(body["TITLE"], "Vinos");
    expect(body["COLOR"], "0xFFF87171");
  });

  test('el color siempre viaja', () {
    // El formulario arranca con un color puesto, asi que el alta nunca queda sin
    // el.
    final body = createTableRequest(
      title: "Vinos",
      description: "",
      color: "0xFF34D399"
    );

    expect(body["COLOR"], "0xFF34D399");
  });

  group('edicion parcial desde los ajustes', () {
    test('cambiar la descripcion no reescribe el nombre', () {
      // Es la razon de ser del endpoint: la ficha edita un dato por vez, y lo
      // que no viaja el backend lo deja como estaba. Mandando el nombre igual
      // se pisaria un renombre que hubiera entrado por otro lado.
      final body = editTableDetailsRequest(
        id: "a1b2c3",
        description: "  Catalogo de la bodega  "
      );

      expect(body, {"ID": "a1b2c3", "DESCRIPTION": "Catalogo de la bodega"});
      expect(body.containsKey("NAME"), isFalse);

      // El cuerpo viaja tal cual por la api, asi que tiene que ser
      // serializable.
      expect(jsonDecode(jsonEncode(body)), body);
    });

    test('el renombre viaja solo, y en NAME', () {
      final body = editTableDetailsRequest(id: "a1b2c3", name: "  Vinos  ");

      expect(body, {"ID": "a1b2c3", "NAME": "Vinos"});
      expect(body.containsKey("DESCRIPTION"), isFalse);
    });

    test('los dos juntos tambien pueden viajar', () {
      final body = editTableDetailsRequest(
        id: "a1b2c3",
        name: "Vinos",
        description: "Catalogo"
      );

      expect(body, {
        "ID": "a1b2c3",
        "NAME": "Vinos",
        "DESCRIPTION": "Catalogo"
      });
    });

    test('la descripcion en blanco si viaja: es lo que la borra', () {
      // El unico lugar donde el vacio es un valor y no la ausencia de uno. Sin
      // esto, una descripcion puesta por error no tendria vuelta atras.
      final body = editTableDetailsRequest(id: "a1b2c3", description: "   ");

      expect(body["DESCRIPTION"], "");
      expect(body.containsKey("DESCRIPTION"), isTrue);
    });

    test('sin nada que cambiar viaja solo el id', () {
      // El backend rechaza un cuerpo asi (`nothing_to_update`), y por eso el
      // servicio ni lo manda: la funcion no inventa claves para tapar el caso.
      expect(editTableDetailsRequest(id: "a1b2c3"), {"ID": "a1b2c3"});
    });
  });
}
