import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/inventory/table_record_request.dart';

void main() {
  test('el alta manda la tabla y los datos', () {
    expect(
      createRecordRequest(tableId: "t1", values: {"f-precio": "22.50"}),
      {"TABLE_ID": "t1", "DATA": {"f-precio": "22.50"}}
    );
  });

  test('la edicion manda ademas a que registro', () {
    expect(
      editRecordRequest(
        tableId: "t1",
        id: "r1",
        values: {"f-precio": "24.90"}
      ),
      {"TABLE_ID": "t1", "ID": "r1", "DATA": {"f-precio": "24.90"}}
    );
  });

  test('la edicion manda solo el campo que se toco', () {
    // La planilla edita de a una celda: mandar la fila entera reescribiria
    // campos que nadie miro.
    final body = editRecordRequest(
      tableId: "t1",
      id: "r1",
      values: {"f-precio": "24.90"}
    );

    expect((body["DATA"] as Map).keys, ["f-precio"]);
  });
}
