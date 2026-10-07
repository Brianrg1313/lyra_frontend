import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/stock/tables/table_structure_model.dart';
import 'package:app/services/stock/tables/table_view_model.dart';

/// La respuesta de `GET /inventory/products/builder/structure/<UUID>` tal cual la define el
/// contrato: la cabecera de la tabla y sus campos en forma columnar.
Map<String, dynamic> get _response => {
  "id": "8f2c1a90-3d7b-4e21-9c55-6ab0f1d2e4c7",
  "name": "Productos",
  "description": "Catálogo de la tienda",
  "color": "0xFF2196F3",
  "date": "2026-07-14T10:32:11.000Z",
  "records": 1287,
  "fields": {
    "keys": ["id", "name", "type"],
    "values": [
      ["a1b2c3d4-1111-4aaa-8bbb-000000000001", "Nombre", "title"],
      ["a1b2c3d4-1111-4aaa-8bbb-000000000002", "Descripción", "description"],
      ["a1b2c3d4-1111-4aaa-8bbb-000000000003", "Precio", "price"],
      ["a1b2c3d4-1111-4aaa-8bbb-000000000004", "Existencias", "stock"],
      ["a1b2c3d4-1111-4aaa-8bbb-000000000005", "Activo", "boolean"],
      ["a1b2c3d4-1111-4aaa-8bbb-000000000006", "Alta", "date"]
    ]
  }
};

void main() {
  group('estructura', () {
    test('lee la cabecera de la tabla', () {
      final structure = TableStructureModel.fromResponse(_response);

      expect(structure.id, "8f2c1a90-3d7b-4e21-9c55-6ab0f1d2e4c7");
      expect(structure.name, "Productos");
      expect(structure.description, "Catálogo de la tienda");
      expect(structure.color, "0xFF2196F3");
      expect(structure.records, 1287);
      expect(structure.date, DateTime.utc(2026, 7, 14, 10, 32, 11));
    });

    test('lee los campos en el orden en que vienen', () {
      final structure = TableStructureModel.fromResponse(_response);

      expect(
        [for (final field in structure.fields) field.name],
        ["Nombre", "Descripción", "Precio", "Existencias", "Activo", "Alta"]
      );
      expect(
        [for (final field in structure.fields) field.type],
        ["title", "description", "price", "stock", "boolean", "date"]
      );
      expect(
        structure.fields.first.id,
        "a1b2c3d4-1111-4aaa-8bbb-000000000001"
      );
    });

    test('una tabla sin campos se lee igual', () {
      // Es el estado de una tabla recien creada: la planilla la abre y sus
      // columnas libres son las que esperan el primer titulo.
      final structure = TableStructureModel.fromResponse({
        ..._response,
        "fields": {"keys": ["id", "name", "type"], "values": []}
      });

      expect(structure.fields, isEmpty);
      expect(structure.name, "Productos");
    });

    test('los campos tambien se leen como lista de objetos', () {
      final structure = TableStructureModel.fromResponse({
        ..._response,
        "fields": [
          {"id": "f1", "name": "Nombre", "type": "title"},
          {"id": "f2", "name": "Precio", "type": "price"}
        ]
      });

      expect([for (final field in structure.fields) field.id], ["f1", "f2"]);
      expect(structure.fields.last.type, "price");
    });

    test('una fecha ilegible no se lleva puesta la estructura', () {
      final structure = TableStructureModel.fromResponse({
        ..._response,
        "date": "ayer"
      });

      expect(structure.date, isNull);
      expect(structure.fields, hasLength(6));
    });

    test('una respuesta que no es un objeto queda vacia', () {
      expect(TableStructureModel.fromResponse(null).isEmpty, isTrue);
      expect(TableStructureModel.fromResponse("nada").fields, isEmpty);
    });

    test('un campo trae el ancho con el que se lo dejo', () {
      // Es lo que hace que la tabla se abra acomodada para todos: el ancho no es
      // de quien la mira sino de la tabla, y viene con sus campos.
      final structure = TableStructureModel.fromResponse({
        ..._response,
        "fields": {
          "keys": ["id", "name", "type", "width"],
          "values": [
            ["f1", "Nombre", "title", 240],
            ["f2", "Precio", "price", null]
          ]
        }
      });

      expect(structure.fields.first.width, 240);
      // Una columna que nunca se arrastro no tiene ancho guardado: la planilla
      // le pone el de siempre.
      expect(structure.fields.last.width, 0);
    });

    test('un ancho que no se puede leer deja la columna como estaba', () {
      // Un dato raro en una columna no puede tumbar la carga de la tabla: se lo
      // trata como a la que nunca se redimensiono.
      final structure = TableStructureModel.fromResponse({
        ..._response,
        "fields": [
          {"id": "f1", "name": "Nombre", "width": "ancho"},
          {"id": "f2", "name": "Precio", "width": -80},
          {"id": "f3", "name": "Costo", "width": "180"}
        ]
      });

      expect([for (final field in structure.fields) field.width], [0, 0, 180]);
    });

    test('un campo de lista trae sus opciones', () {
      // Vienen con la estructura y no en una lectura aparte: son parte de la
      // columna, como su tipo o su ancho, y le pertenecen a ese campo solo.
      final structure = TableStructureModel.fromResponse({
        ..._response,
        "fields": {
          "keys": ["id", "name", "type", "options"],
          "values": [
            ["f1", "Color", "options", ["Rojo", "Verde"]],
            ["f2", "Talle", "options", []],
            ["f3", "Precio", "price", null]
          ]
        }
      });

      expect(structure.fields[0].options, ["Rojo", "Verde"]);
      // Una lista sin opciones y una columna que no es lista se leen igual: sin
      // opciones. La primera se despliega igual, con el boton de crear la que
      // falta.
      expect(structure.fields[1].options, isEmpty);
      expect(structure.fields[2].options, isEmpty);
    });

    test('las opciones se leen tambien como texto JSON', () {
      // Por si el backend devuelve la columna sin decodificar.
      final structure = TableStructureModel.fromResponse({
        ..._response,
        "fields": [
          {"id": "f1", "name": "Color", "options": '["Rojo","Verde"]'}
        ]
      });

      expect(structure.fields.single.options, ["Rojo", "Verde"]);
    });

    test('unas opciones ilegibles dejan la columna sin lista', () {
      // Un dato raro en una columna no puede tumbar la carga de la tabla: se la
      // trata como a una lista todavia vacia, a la que igual se le pueden crear
      // opciones.
      final structure = TableStructureModel.fromResponse({
        ..._response,
        "fields": [
          {"id": "f1", "name": "Color", "options": "{no es json"},
          {"id": "f2", "name": "Talle", "options": 7},
          {"id": "f3", "name": "Marca", "options": ["Uno", "", null, "  Dos  "]}
        ]
      });

      expect(structure.fields[0].options, isEmpty);
      expect(structure.fields[1].options, isEmpty);
      // Lo que si se puede leer se lee, recortado y sin los huecos.
      expect(structure.fields[2].options, ["Uno", "Dos"]);
    });

    test('un campo sin nombre se muestra con su id', () {
      final structure = TableStructureModel.fromResponse({
        ..._response,
        "fields": {
          "keys": ["id", "name", "type"],
          "values": [["f1", "", "title"]]
        }
      });

      expect(structure.fields.single.name, "f1");
    });
  });

  group('alineacion de la pagina', () {
    final fields = TableStructureModel.fromResponse(_response).fields;

    test('las columnas las manda la estructura', () {
      final page = TableViewModel.fromResponse({
        "keys": [],
        "values": []
      }).alignedTo(fields);

      expect(
        [for (final column in page.columns) column.name],
        ["Nombre", "Descripción", "Precio", "Existencias", "Activo", "Alta"]
      );
    });

    test('los valores se reacomodan al orden de la estructura', () {
      // La pagina trae las mismas columnas pero al reves: cada celda tiene que
      // terminar bajo su campo, no bajo la posicion en que vino.
      final page = TableViewModel.fromResponse({
        "keys": [
          for (final field in fields.reversed)
            {"id": field.id, "name": field.name, "type": field.type}
        ],
        "values": [
          ["2026-01-01", true, 7, 1500, "Un vino", "Malbec"]
        ]
      }).alignedTo(fields);

      expect(page.rows.single.values, ["Malbec", "Un vino", 1500, 7, true, "2026-01-01"]);
    });

    test('un campo que la pagina no trae queda vacio', () {
      final page = TableViewModel.fromResponse({
        "keys": [{"id": fields[2].id, "name": "Precio", "type": "price"}],
        "values": [[1500]]
      }).alignedTo(fields);

      expect(page.rows.single.values, [null, null, 1500, null, null, null]);
    });

    test('una pagina sin encabezados se respeta por posicion', () {
      // Sin FIELD_ID con que emparejar, el orden en que vinieron los valores es
      // lo unico que se puede suponer.
      final page = const TableViewModel(rows: [
        TableRowModel(["Malbec", "Un vino", 1500])
      ]).alignedTo(fields);

      expect(page.columns, hasLength(6));
      expect(page.rows.single.at(0), "Malbec");
      expect(page.rows.single.at(2), 1500);
    });

    test('sin estructura la pagina queda como vino', () {
      final page = TableViewModel.fromResponse({
        "keys": ["Nombre"],
        "values": [["Malbec"]]
      });

      expect(identical(page.alignedTo(const []), page), isTrue);
    });
  });
}
