import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/inventory/table_record_request.dart';
import 'package:app/services/kitchen/kitchen_request.dart';
import 'package:app/services/kitchen/made_consumes_model.dart';
import 'package:app/services/kitchen/recipe_model.dart';
import 'package:app/services/stock/tables/table_structure_model.dart';
import 'package:app/services/stock/tables/table_view_model.dart';
import 'package:app/services/stock/tables/table_view_service.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_cell.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_controller.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_made.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_metrics.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_widths.dart';
import 'package:app/screens/modals/supply_chain/recipe/recipe_editor.dart';

/// A made product's recipe is part of its record (`cocina-frontend.md` §3): it travels in the
/// record's own write (`CONSUMES`, `BATCH`), comes back beside the rows of `records/list`, and
/// the sheet asks for it before a written row is saved, never after.
void main() {
  group("contract", () {
    test("a made page reads what each record consumes, and keeps it once aligned", () {
      final page = TableViewModel.fromResponse({
        "keys": ["id", "f-name"],
        "values": [["burger", "Cheese burger"]],
        "consumes": {
          "burger": {
            "mode": "order",
            "paused": false,
            "available": 12,
            "lines": [{"id": "l1", "tableId": "s", "productId": "bread", "name": "Bread", "qty": 1, "negotiable": false, "waste": 0}]
          },
          "candle": {"mode": "batch", "paused": true, "available": 4, "capacity": 200, "lines": []}
        }
      }, tableId: "menu").alignedTo(const [TableFieldModel(id: "f-name", name: "Name", type: "TITLE")]);

      final burger = page.consumes["burger"]!;
      expect(burger.recipe.tableId, "menu");
      expect(burger.recipe.mode, RecipeMode.order);
      expect(burger.recipe.lines.single.name, "Bread");
      expect(burger.availability.available, 12);
      expect(page.consumes["candle"]!.availability.capacity, 200);
      expect(page.consumes["candle"]!.recipe.paused, isTrue);
      expect(page.rows.single.id, "burger");
    });

    test("another table's page consumes nothing", () {
      expect(MadeConsumes.mapFrom(null, tableId: "t"), isEmpty);
      expect(TableViewModel.fromResponse({"keys": ["id"], "values": []}).consumes, isEmpty);
    });

    test("a made record is created with what it consumes, in the same body", () {
      final body = createRecordRequest(
        tableId: "menu",
        values: {"f-name": "Cheese burger"},
        consumes: const [
          (tableId: "s", productId: "bread", qty: 1, negotiable: false, waste: 0),
          (tableId: "s", productId: "meat", qty: 0.15, negotiable: false, waste: 5),
          (tableId: "s", productId: "bacon", qty: 0.03, negotiable: true, waste: 0)
        ],
        batch: false
      );

      expect(body["DATA"], {"f-name": "Cheese burger"});
      expect(body["BATCH"], isFalse);
      expect(body["CONSUMES"], [
        {"TABLE_ID": "s", "PRODUCT_ID": "bread", "QUANTITY": 1},
        {"TABLE_ID": "s", "PRODUCT_ID": "meat", "QUANTITY": 0.15, "WASTE": 5},
        {"TABLE_ID": "s", "PRODUCT_ID": "bacon", "QUANTITY": 0.03, "NEGOTIABLE": true}
      ]);
    });

    test("a catalog record sends neither", () {
      final body = createRecordRequest(tableId: "t", values: {"f": "Phone"});

      expect(body.containsKey("CONSUMES"), isFalse);
      expect(body.containsKey("BATCH"), isFalse);
    });

    test("editing what a record consumes sends no DATA", () {
      final body = editRecordRequest(
        tableId: "menu",
        id: "burger",
        consumes: const [(tableId: "s", productId: "bread", qty: 2, negotiable: false, waste: 0)],
        batch: true
      );

      expect(body.containsKey("DATA"), isFalse);
      expect(body["BATCH"], isTrue);
      expect((body["CONSUMES"] as List).single["QUANTITY"], 2);
    });
  });

  group("sheet", () {
    const draft = (
      mode: RecipeMode.order,
      lines: <RecipeLineDraft>[(tableId: "s", productId: "bread", qty: 1, negotiable: false, waste: 0)],
      names: <String, String>{"bread": "Bread"}
    );

    testWidgets("a written row is asked what it consumes and saved with it", (tester) async {
      final table = _Menu();
      final asked = <String>[];
      final controller = await _controller(tester, table, consumesFor: (name) async {
        asked.add(name);
        return draft;
      });
      addTearDown(controller.dispose);

      controller.open(const SheetCell(0, 0));
      controller.editor!.text = "Cheese burger";
      controller.onChanged("Cheese burger");
      controller.generateSku(const SheetCell(0, 1));
      await tester.pumpAndSettle();

      expect(asked, ["Cheese burger"]);
      expect(table.added.single.values["f-name"], "Cheese burger");
      expect(table.added.single.consumes!.single.productId, "bread");
      expect(table.added.single.batch, isFalse);
    });

    testWidgets("a row whose question is closed is not saved", (tester) async {
      final table = _Menu();
      final controller = await _controller(tester, table, consumesFor: (_) async => null);
      addTearDown(controller.dispose);

      controller.generateSku(const SheetCell(0, 1));
      await tester.pumpAndSettle();

      expect(table.added, isEmpty);
      expect(controller.valueOf(const SheetCell(0, 1)), isNotEmpty);
    });

    testWidgets("a record made to order opens what it consumes from its stock cell", (tester) async {
      final table = _Menu(withBurger: true);
      final opened = <String>[];
      final controller = await _controller(tester, table, open: (record, name) async => opened.add("${record.id}:$name"));
      addTearDown(controller.dispose);

      controller.tap(0, 2);
      await tester.pumpAndSettle();

      expect(controller.movesStock(const SheetCell(0, 2)), isFalse);
      expect(controller.isMadeRecord(0), isTrue);
      expect(opened, ["burger:Cheese burger"]);
    });
  });
}

/// A made table: a title, a SKU (its button saves a row by itself) and the stock; with
/// [withBurger] one burger made to order, else no record.
class _Menu extends TableViewService {
  _Menu({this.withBurger = false});

  final bool withBurger;
  final List<({Map<String, dynamic> values, List<RecipeLineDraft>? consumes, bool? batch})> added = [];

  @override
  List<TableFieldModel> get fields => const [
    TableFieldModel(id: "f-name", name: "Name", type: "TITLE"),
    TableFieldModel(id: "f-sku", name: "SKU", type: "SKU"),
    TableFieldModel(id: "f-stock", name: "Stock", type: "STOCK")
  ];

  @override
  int get records => withBurger ? 1 : 0;

  @override
  TableRowModel? rowAt(int index) =>
    withBurger && index == 0 ? const TableRowModel(["Cheese burger", "B1", 12], id: "burger") : null;

  @override
  MadeConsumes? consumesOf(String id) => id == "burger"
    ? MadeConsumes.mapFrom({"burger": {"mode": "order", "available": 12, "lines": []}}, tableId: "menu")["burger"]
    : null;

  @override
  Future<bool> add(
    BuildContext context,
    Map<String, dynamic> values, {
    List<dynamic>? row,
    List<RecipeLineDraft>? consumes,
    bool? batch
  }) async {
    added.add((values: values, consumes: consumes, batch: batch));
    return true;
  }

  @override
  Future<void> refresh() async {}
}

Future<SheetController> _controller(
  WidgetTester tester,
  _Menu table, {
  Future<RecipeDraft?> Function(String name)? consumesFor,
  Future<void> Function(TableRowModel record, String name)? open
}) async {
  late SheetController controller;

  await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
    controller = SheetController(
      service: table,
      metrics: const SheetMetrics(rowHeight: 32, gutterWidth: 40),
      widths: SheetWidths(defaultWidth: 160, minWidth: 60),
      context: () => context,
      made: SheetMade(
        consumesFor: consumesFor ?? (_) async => null,
        open: open ?? (_, _) async {}
      )
    );

    return const SizedBox();
  })));

  return controller;
}
