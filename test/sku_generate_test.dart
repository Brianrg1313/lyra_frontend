import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/kitchen/kitchen_request.dart';
import 'package:app/services/stock/tables/table_structure_model.dart';
import 'package:app/services/stock/tables/table_view_service.dart';

import 'package:app/screens/home/sections/inventory/table_view/state/sheet_controller.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_metrics.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_widths.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_cell.dart';

/// Una tabla con dos columnas y sin un solo registro: todas sus filas son de
/// las que se escriben. El alta no sale a la red, se anota.
class _FakeTable extends TableViewService {
  final List<Map<String, dynamic>> added = [];

  @override
  List<TableFieldModel> get fields => const [
    TableFieldModel(id: "f-name", name: "Nombre", type: "VECTOR"),
    TableFieldModel(id: "f-sku", name: "SKU", type: "SKU")
  ];

  @override
  int get records => 0;

  @override
  Future<bool> add(
    BuildContext context,
    Map<String, dynamic> values, {
    List<dynamic>? row,
    List<RecipeLineDraft>? consumes,
    bool? batch
  }) async {
    added.add(values);
    return true;
  }

  @override
  Future<void> refresh() async {}
}

/// Monta un controlador sobre [table], con un contexto de verdad porque el alta
/// lo necesita (traduce y muestra sus errores).
Future<SheetController> _controller(
  WidgetTester tester,
  _FakeTable table
) async {
  late SheetController controller;

  await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
    controller = SheetController(
      service: table,
      metrics: const SheetMetrics(rowHeight: 32, gutterWidth: 40),
      widths: SheetWidths(defaultWidth: 160, minWidth: 60),
      context: () => context
    );

    return const SizedBox();
  })));

  return controller;
}

void main() {
  const sku = SheetCell(0, 1);

  testWidgets('generar un SKU en una fila en blanco la da de alta', (tester) async {
    // El boton se come el toque de la celda, asi que el cursor nunca entra en
    // esa fila y nunca sale de ella: si el alta esperara a que salga, la fila
    // se quedaria con su codigo puesto y sin registro.
    final table = _FakeTable();
    final controller = await _controller(tester, table);
    addTearDown(controller.dispose);

    controller.generateSku(sku);
    await tester.pumpAndSettle();

    expect(table.added.length, 1);
    expect((table.added.single["f-sku"] as String).length, 12);
  });

  testWidgets('el codigo que se guarda es el que quedo en la celda', (tester) async {
    final table = _FakeTable();
    final controller = await _controller(tester, table);
    addTearDown(controller.dispose);

    controller.generateSku(sku);
    final shown = controller.valueOf(sku);

    await tester.pumpAndSettle();

    expect(table.added.single["f-sku"], shown);
  });

  testWidgets('la fila se va con lo que ya tenia escrito, en un solo alta', (tester) async {
    // Media fila cargada a mano mas el boton es **un** registro, no dos: el
    // borrador es la fila entera y el alta lo manda completo.
    final table = _FakeTable();
    final controller = await _controller(tester, table);
    addTearDown(controller.dispose);

    controller.open(const SheetCell(0, 0));
    controller.editor!.text = "Yerba";
    controller.onChanged("Yerba");

    controller.generateSku(sku);
    await tester.pumpAndSettle();

    expect(table.added.length, 1);
    expect(table.added.single["f-name"], "Yerba");
    expect(table.added.single["f-sku"], isNotEmpty);
  });

  testWidgets('el alta es de esa fila y no arrastra a las de arriba', (tester) async {
    // Se puede generar el codigo en la tercera fila en blanco: las dos de
    // arriba siguen vacias y no se dan de alta.
    final table = _FakeTable();
    final controller = await _controller(tester, table);
    addTearDown(controller.dispose);

    controller.generateSku(const SheetCell(2, 1));
    await tester.pumpAndSettle();

    expect(table.added.length, 1);
    expect(controller.valueOf(const SheetCell(0, 1)), isEmpty);
  });
}
