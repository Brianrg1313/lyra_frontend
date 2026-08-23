import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/inventory/table_field_request.dart';

void main() {
  test('la edicion manda el id, el nombre y el tipo nuevo', () {
    final body = editFieldRequest(
      id: "d4e5f6",
      name: "  Precio  ",
      type: "PRICE"
    );

    expect(body, {"ID": "d4e5f6", "NAME": "Precio", "TYPE": "PRICE"});

    // El cuerpo viaja tal cual por la api, asi que tiene que ser serializable.
    expect(jsonDecode(jsonEncode(body)), body);
  });

  test('lo que no se cambia no viaja', () {
    // Cambiar el tipo desde la planilla no toca la descripcion ni corre la
    // columna de lugar: el backend deja como estaba lo que no le mandan.
    final body = editFieldRequest(id: "d4e5f6", name: "Precio", type: "DATE");

    expect(body.containsKey("DESCRIPTION"), isFalse);
    expect(body.containsKey("POSITION"), isFalse);
  });

  test('sin tipo la clave no viaja', () {
    final body = editFieldRequest(id: "d4e5f6", name: "Precio", type: "");

    expect(body.containsKey("TYPE"), isFalse);
    expect(body["NAME"], "Precio");
  });

  test('el renombre manda el nombre nuevo y ningun tipo', () {
    // Renombrar es escribir otro titulo en la celda del campo: el tipo no se
    // toca, asi que su clave no viaja y el backend lo deja como estaba.
    final body = editFieldRequest(id: "d4e5f6", name: "  Costo  ");

    expect(body, {"ID": "d4e5f6", "NAME": "Costo"});
  });

  test('el ancho viaja con el nombre que el campo ya tenia', () {
    // Soltar el borde de una columna guarda su ancho, y el backend pide el
    // nombre siempre: se le manda el que trae la estructura, que no se toco.
    final body = editFieldRequest(id: "d4e5f6", name: "Precio", width: 240);

    expect(body, {"ID": "d4e5f6", "NAME": "Precio", "WIDTH": 240});
    expect(jsonDecode(jsonEncode(body)), body);
  });

  test('sin ancho la clave no viaja', () {
    // Renombrar una columna o cambiarle el tipo no la ensancha: el backend deja
    // el ancho como estaba.
    final body = editFieldRequest(id: "d4e5f6", name: "Precio", type: "DATE");

    expect(body.containsKey("WIDTH"), isFalse);
  });

  test('la baja es solo el id', () {
    // El campo ya sabe de que tabla es: mandar algo mas seria mandar de mas.
    expect(deleteFieldRequest(id: "d4e5f6"), {"ID": "d4e5f6"});
    expect(
      jsonDecode(jsonEncode(deleteFieldRequest(id: "d4e5f6"))),
      {"ID": "d4e5f6"}
    );
  });

  test('el alta sigue mandando la posicion y el tipo', () {
    final body = createFieldRequest(
      tableId: "a1b2c3",
      name: "Precio",
      description: "   ",
      type: "TEXT",
      position: 3
    );

    expect(body, {
      "TABLE_ID": "a1b2c3",
      "NAME": "Precio",
      "POSITION": 3,
      "TYPE": "TEXT"
    });
  });

  test('las opciones viajan como la lista entera', () {
    // Una opcion le pertenece al campo, asi que se guarda como su nombre o su
    // ancho: escribiendo el valor que tiene que quedar, no con un alta aparte.
    final body = editFieldRequest(
      id: "d4e5f6",
      name: "Color",
      options: const ["Rojo", "Verde"]
    );

    expect(body, {
      "ID": "d4e5f6",
      "NAME": "Color",
      "OPTIONS": ["Rojo", "Verde"]
    });

    expect(jsonDecode(jsonEncode(body)), body);
  });

  test('sin opciones la clave no viaja', () {
    // Renombrar una columna de lista, o ensancharla, no le toca las opciones.
    final body = editFieldRequest(id: "d4e5f6", name: "Color", width: 240);

    expect(body.containsKey("OPTIONS"), isFalse);
  });

  test('una lista vacia si viaja: es lo que borra las opciones', () {
    // Es la unica clave donde "vacio" es un valor y no la ausencia de uno.
    final body = editFieldRequest(id: "d4e5f6", name: "Color", options: const []);

    expect(body["OPTIONS"], isEmpty);
    expect(body.containsKey("OPTIONS"), isTrue);
  });

  test('las opciones viajan recortadas y sin huecos', () {
    final body = editFieldRequest(
      id: "d4e5f6",
      name: "Color",
      options: const ["  Rojo  ", "   ", "Verde"]
    );

    expect(body["OPTIONS"], ["Rojo", "Verde"]);
  });

  test('la visibilidad viaja sola, con el nombre que el campo ya tenia', () {
    // Es lo que manda la ficha de la tabla al mover una columna a "declarada":
    // no se le esta tocando ni el nombre ni el tipo ni lo que hay escrito.
    final body = editFieldRequest(
      id: "d4e5f6",
      name: "Costo",
      visibility: "declared"
    );

    expect(body, {"ID": "d4e5f6", "NAME": "Costo", "VISIBILITY": "declared"});
  });

  test('sin visibilidad la clave no viaja', () {
    final body = editFieldRequest(id: "d4e5f6", name: "Costo", type: "PRICE");

    expect(body.containsKey("VISIBILITY"), isFalse);
  });

  test('el tipo y la visibilidad viajan juntos si se cambian los dos', () {
    final body = editFieldRequest(
      id: "d4e5f6",
      name: "Costo",
      type: "PRICE",
      visibility: "hidden"
    );

    expect(body["TYPE"], "PRICE");
    expect(body["VISIBILITY"], "hidden");
    expect(body.containsKey("WIDTH"), isFalse);
    expect(body.containsKey("POSITION"), isFalse);
  });
}
