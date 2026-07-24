import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/products/table_request.dart';

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
}
