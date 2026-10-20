import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/inventory/table_request.dart';
import 'package:app/services/stock/tables/table_detail_model.dart';
import 'package:app/services/stock/tables/table_lite_model.dart';

/// Productos e insumos se cambian desde los ajustes de la tabla
/// (`cocina-frontend.md` §2): el tipo viaja solo cuando se cambia, y el
/// detalle lo lee y lo conserva en sus copias.
void main() {
  test('KIND viaja solo cuando se cambia el tipo', () {
    expect(editTableDetailsRequest(id: "t1", kind: "supplies"), {"ID": "t1", "KIND": "supplies"});
    expect(editTableDetailsRequest(id: "t1", name: "Piezas").containsKey("KIND"), isFalse);
  });

  test('el detalle lee el tipo y lo conserva al editar', () {
    final detail = TableDetailModel.fromResponse({"id": "t1", "name": "Piezas", "kind": "supplies"});

    expect(detail.kind, TableKind.supplies);
    expect(detail.withText(name: "Repuestos").kind, TableKind.supplies);
    expect(detail.withKind(TableKind.catalog).kind, TableKind.catalog);
    expect(detail.withKind(TableKind.catalog).name, "Piezas");

    // Sin tipo, como el backend: un catálogo
    expect(TableDetailModel.fromResponse({"id": "t2"}).kind, TableKind.catalog);
  });
}
