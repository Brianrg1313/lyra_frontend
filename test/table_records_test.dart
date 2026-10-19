import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/stock/tables/table_structure_model.dart';
import 'package:app/services/stock/tables/table_view_model.dart';

/// Los campos de la tabla, como los da la estructura.
const _fields = [
  TableFieldModel(id: "f-precio", name: "Precio", type: "PRICE"),
  TableFieldModel(id: "f-nombre", name: "Nombre", type: "TEXT")
];

/// Una pagina tal cual la devuelve `POST /inventory/products/records/list/`: la paginacion
/// afuera, los datos comprimidos adentro y los encabezados pelados, que son los
/// FIELD_ID con el id del registro al frente.
const _page = {
  "total": 2,
  "page": 1,
  "size": 50,
  "data": {
    "keys": ["id", "f-nombre", "f-precio"],
    "values": [
      ["r1", "Yerba", 1500],
      ["r2", "Azucar", 900]
    ]
  }
};

void main() {
  test("each row carries its product's own unit, or none", () {
    // `units` only names the products counted in something else than their column.
    final rows = TableViewModel.fromResponse({..._page, "units": {"r2": "u"}}).alignedTo(_fields).rows;

    expect(rows.first.unit, "");
    expect(rows.last.unit, "u");
    expect(rows.last.withValue(0, 1).unit, "u", reason: "a written cell keeps the row's unit");
  });

  test('la pagina se lee de adentro de la paginacion', () {
    final view = TableViewModel.fromResponse(_page);

    expect(view.rows.length, 2);
    expect(view.columns.length, 3);
  });

  test('las celdas caen bajo la columna que les toca', () {
    // Los encabezados de la pagina vienen en otro orden que los campos de la
    // estructura, y aun asi cada valor tiene que quedar en su columna: quien
    // manda es la estructura, la pagina solo aporta los valores.
    final rows = TableViewModel.fromResponse(_page).alignedTo(_fields).rows;

    expect(rows.first.at(0), 1500);
    expect(rows.first.at(1), "Yerba");
    expect(rows.last.at(0), 900);
    expect(rows.last.at(1), "Azucar");
  });

  test('el id del registro no se cuela como una columna mas', () {
    final view = TableViewModel.fromResponse(_page).alignedTo(_fields);

    // La planilla tiene tantas columnas como campos: el `id` de cada fila es
    // del backend y no se muestra.
    expect(view.columns.length, _fields.length);
    expect(view.rows.first.values.length, _fields.length);
    expect(view.rows.first.values.contains("r1"), isFalse);
  });

  test('cada fila se queda con el id de su registro', () {
    // No se muestra, pero es lo que hace editable a la fila: sin el no hay a
    // que registro mandarle la correccion.
    final rows = TableViewModel.fromResponse(_page).alignedTo(_fields).rows;

    expect(rows.first.id, "r1");
    expect(rows.last.id, "r2");
  });

  test('un campo llamado como el id sigue siendo un campo', () {
    // El id del registro se busca solo entre las columnas que no son de ningun
    // campo: una tabla puede tener su propia columna "ID" cargada a mano.
    const fields = [
      TableFieldModel(id: "ID", name: "Codigo", type: "TEXT"),
      TableFieldModel(id: "f-nombre", name: "Nombre", type: "TEXT")
    ];

    final rows = TableViewModel.fromResponse(const {
      "keys": ["id", "ID", "f-nombre"],
      "values": [
        ["r1", "AX-20", "Yerba"]
      ]
    }).alignedTo(fields).rows;

    expect(rows.first.at(0), "AX-20");
    expect(rows.first.id, "r1");
  });

  test('una pagina sin id de registro no deja filas editables', () {
    final rows = TableViewModel.fromResponse(const {
      "keys": ["f-precio", "f-nombre"],
      "values": [
        [1500, "Yerba"]
      ]
    }).alignedTo(_fields).rows;

    expect(rows.first.at(0), 1500);
    expect(rows.first.id, isEmpty);
  });

  test('corregir una celda deja una fila nueva y no toca la anterior', () {
    // Se compara por identidad para decidir que se repinta, asi que la
    // correccion tiene que devolver otra fila y dejar la de antes como estaba.
    final row = TableViewModel.fromResponse(_page).alignedTo(_fields).rows.first;
    final edited = row.withValue(0, "1600");

    expect(edited.at(0), "1600");
    expect(edited.at(1), "Yerba");
    expect(edited.id, "r1");
    expect(row.at(0), 1500);
  });

  test('se puede corregir una celda de una columna recien creada', () {
    // La fila leida es mas corta que los campos de ahora: la celda nueva se
    // completa en vez de perderse.
    const row = TableRowModel(["1500"], id: "r1");

    expect(row.withValue(2, "10").values, ["1500", null, "10"]);
  });

  test('un campo que la pagina no trae queda vacio', () {
    final view = TableViewModel.fromResponse(_page).alignedTo([
      ..._fields,
      const TableFieldModel(id: "f-stock", name: "Stock", type: "STOCK")
    ]);

    expect(view.rows.first.at(2), isNull);
  });
}
