import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/inventory/table_field_type.dart';
import 'package:app/services/stock/tables/table_structure_model.dart';
import 'package:app/services/stock/tables/table_view_model.dart';
import 'package:app/services/stock/tables/table_view_service.dart';

import 'package:app/screens/home/sections/inventory/table_view/state/sheet_actions.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_cell.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_controller.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_metrics.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_selection.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_widths.dart';

/// Three records with a name and a price; the corrections are kept, not sent.
class _Table extends TableViewService {
  final List<TableRowModel> _records = [
    for (final (index, name) in ["Rice", "Beans", "Salt"].indexed)
      TableRowModel([name, "${index + 1}"], id: "r$index")
  ];

  final List<(int, String, String)> sent = [];

  @override
  List<TableFieldModel> get fields => const [
    TableFieldModel(id: "f-name", name: "Name", type: "TEXT"),
    TableFieldModel(id: "f-price", name: "Price", type: "PRICE")
  ];

  @override
  int get records => _records.length;

  @override
  TableRowModel? rowAt(int index) =>
    index >= 0 && index < _records.length ? _records[index] : null;

  @override
  int? rowOf(String id) {
    final row = _records.indexWhere((record) => record.id == id);
    return row < 0 ? null : row;
  }

  @override
  Future<bool> editRecord(
    BuildContext context, {
    required int row,
    required int slot,
    required String fieldId,
    required String value
  }) async {
    sent.add((row, fieldId, value));
    _records[row] = _records[row].withValue(slot, value);
    notifyListeners();
    return true;
  }
}

void main() {
  late _Table table;
  late SheetController controller;

  Future<void> mount(WidgetTester tester) async {
    table = _Table();

    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      controller = SheetController(
        service: table,
        metrics: const SheetMetrics(rowHeight: 32, gutterWidth: 40),
        widths: SheetWidths(defaultWidth: 160, minWidth: 60),
        context: () => context
      );
      controller.setRows(3);

      return Focus(
        focusNode: controller.grid,
        onKeyEvent: controller.handleKey,
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
  }

  /// Types [text] in [cell] and leaves it, which is what sends the correction.
  Future<void> correct(WidgetTester tester, SheetCell cell, String text) async {
    controller.open(cell);
    await tester.pump();
    controller.editor!.text = text;
    controller.select(const SheetCell(2, 1));
    await tester.pump();
  }

  Future<void> press(WidgetTester tester, LogicalKeyboardKey key, {bool shift = false}) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(key);
    if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
  }

  testWidgets('Ctrl+Z writes back what a record had, and Ctrl+Y writes it again', (tester) async {
    await mount(tester);

    await correct(tester, const SheetCell(0, 0), "Brown rice");
    expect(table.sent.last, (0, "f-name", "Brown rice"));

    await press(tester, LogicalKeyboardKey.keyZ);
    expect(table.sent.last, (0, "f-name", "Rice"));
    expect(controller.cursor.cell, const SheetCell(0, 0), reason: "the cursor goes to what was undone");

    await press(tester, LogicalKeyboardKey.keyY);
    expect(table.sent.last, (0, "f-name", "Brown rice"));

    await press(tester, LogicalKeyboardKey.keyZ);
    await press(tester, LogicalKeyboardKey.keyZ, shift: true);
    expect(table.sent.last, (0, "f-name", "Brown rice"));
  });

  testWidgets('Ctrl+Z on a cell being typed takes back the typing, not the history', (tester) async {
    await mount(tester);

    await correct(tester, const SheetCell(0, 0), "Brown rice");
    final sent = table.sent.length;

    controller.open(const SheetCell(1, 0));
    await tester.pump();
    await tester.pump();
    controller.editor!.text = "Black beans";

    await press(tester, LogicalKeyboardKey.keyZ);
    expect(table.sent.length, sent, reason: "nothing was sent: the typing was dropped");
    expect(controller.history.canUndo, isTrue);
    expect(table.rowAt(1)!.at(0), "Beans");
  });

  testWidgets('crossing a cell without changing it is not remembered', (tester) async {
    await mount(tester);

    controller.open(const SheetCell(0, 1));
    await tester.pump();
    controller.select(const SheetCell(1, 1));
    await tester.pump();

    expect(controller.history.canUndo, isFalse);
  });

  testWidgets('one step written over a range is undone at once and leaves the range on it', (tester) async {
    await mount(tester);

    controller.history.group(() {
      controller.finishRecord(const SheetCell(0, 1), "10", before: "1");
      controller.finishRecord(const SheetCell(2, 1), "30", before: "3");
    });

    controller.undo();
    await tester.pump();

    expect(table.sent.sublist(2), [(2, "f-price", "3"), (0, "f-price", "1")]);
    expect(controller.selection.range, const SheetRange(SheetCell(0, 1), SheetCell(2, 1)));
  });

  testWidgets('a range is stretched from the cursor and a plain move lets go of it', (tester) async {
    await mount(tester);

    controller.select(const SheetCell(0, 0));
    expect(controller.stretchTo(const SheetCell(2, 1)), isTrue);
    expect(controller.cursor.cell, const SheetCell(0, 0), reason: "the cursor stays on the anchor");
    expect(controller.selection.contains(1, 1), isTrue);

    controller.stretchBy(rows: -1, columns: 0);
    expect(controller.selection.range!.focus, const SheetCell(1, 1));

    controller.select(const SheetCell(2, 0));
    expect(controller.selection.range, isNull);

    controller.select(const SheetCell(kFieldsRow, 0));
    expect(controller.stretchTo(const SheetCell(1, 1)), isFalse, reason: "the fields row is no range's");
  });

  testWidgets('the menu offers the general actions, and a type\'s only over its columns', (tester) async {
    await mount(tester);

    final undo = sheetActions.firstWhere((action) => action.id == "undo");
    const target = SheetTarget(range: SheetRange.single(SheetCell(0, 0)), types: []);
    expect(undo.offers(controller, target), isFalse, reason: "nothing to undo yet");

    await correct(tester, const SheetCell(0, 0), "Brown rice");
    expect(undo.offers(controller, target), isTrue);

    final priced = SheetAction(
      id: "priced",
      label: (_) => "",
      types: const {TableFieldType.price},
      run: (_, _) {}
    );
    const range = SheetRange(SheetCell(0, 0), SheetCell(1, 1));

    expect(
      priced.offers(controller, const SheetTarget(range: range, types: [TableFieldType.price])),
      isTrue
    );
    expect(
      priced.offers(controller, const SheetTarget(range: range, types: [TableFieldType.text, TableFieldType.price])),
      isFalse,
      reason: "a range across another type gets the general actions only"
    );
  });
}
