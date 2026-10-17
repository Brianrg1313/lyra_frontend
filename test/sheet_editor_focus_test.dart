import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/stock/tables/table_structure_model.dart';
import 'package:app/services/stock/tables/table_view_service.dart';

import 'package:app/screens/home/sections/inventory/table_view/state/sheet_cell.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_controller.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_metrics.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_widths.dart';

/// A table with no records, whose rows are all written.
class _Table extends TableViewService {
  @override
  List<TableFieldModel> get fields => const [
    TableFieldModel(id: "f-name", name: "Name", type: "TEXT"),
    TableFieldModel(id: "f-unit", name: "Unit", type: "SELECT")
  ];

  @override
  int get records => 0;
}

/// A cell opened from a selected one writes at once. The grid holds the focus
/// while a cell is only selected (and gets it back when a list's dropdown closes),
/// and the editor's `autofocus` does not take while its scope holds one: the
/// editor showed without the caret and only a second click wrote.
void main() {
  testWidgets('a cell opened after a selected one takes the focus', (tester) async {
    late SheetController controller;

    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      controller = SheetController(
        service: _Table(),
        metrics: const SheetMetrics(rowHeight: 32, gutterWidth: 40),
        widths: SheetWidths(defaultWidth: 160, minWidth: 60),
        context: () => context
      );

      // The grid with the one editor it mounts, the way the sheet does.
      return Focus(
        focusNode: controller.grid,
        child: ListenableBuilder(
          listenable: controller.cursor,
          builder: (context, _) => Material(
            child: controller.cursor.editing
              ? TextField(
                  controller: controller.editor,
                  focusNode: controller.focus,
                  autofocus: true
                )
              : const SizedBox()
          )
        )
      );
    })));
    addTearDown(controller.dispose);

    controller.select(const SheetCell(0, 1));
    await tester.pump();
    expect(controller.grid.hasPrimaryFocus, isTrue);

    controller.open(const SheetCell(0, 0));
    await tester.pump();
    await tester.pump();

    expect(controller.focus?.hasPrimaryFocus, isTrue);
  });
}
