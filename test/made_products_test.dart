import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/home/home_service.dart';

import 'package:app/services/inventory/product_image.dart';
import 'package:app/services/inventory/table_field_type.dart';
import 'package:app/services/inventory/table_record_request.dart';
import 'package:app/services/kitchen/kitchen_product_model.dart';
import 'package:app/services/kitchen/kitchen_product_search.dart';
import 'package:app/services/kitchen/kitchen_request.dart';
import 'package:app/services/kitchen/kitchen_units.dart';
import 'package:app/services/kitchen/kitchen_report_model.dart';
import 'package:app/services/kitchen/made_consumes_model.dart';
import 'package:app/services/kitchen/made_kitchen_api.dart';
import 'package:app/services/kitchen/made_product_model.dart';
import 'package:app/services/kitchen/made_products_service.dart';
import 'package:app/services/kitchen/modifier_model.dart';
import 'package:app/services/kitchen/recipe_model.dart';
import 'package:app/services/stock/sources/inventory_source.dart';
import 'package:app/services/stock/summary/stock_summary_model.dart';
import 'package:app/services/stock/tables/table_structure_model.dart';
import 'package:app/services/stock/tables/table_view_model.dart';
import 'package:app/screens/home/sections/inventory/made_products/_made_products.dart';
import 'package:app/screens/home/sections/inventory/table_list/inventory_bar.dart';
import 'package:app/screens/modals/supply_chain/recipe/recipe_editor.dart';

/// A made product's recipe is part of its record (`cocina-frontend.md` §3): it travels in the
/// record's own write (`CONSUMES`, `BATCH`) and comes back beside the rows of `records/list`. A
/// made table is a list of forms, not a sheet: a product is its name, its price and what it
/// consumes, written in the supplies' units.
void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFffffff));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

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

  group("units", () {
    test("a weight is written in grams or kilos and travels in the supply's own unit", () {
      final kg = kitchenUnitsFor("kg");

      expect([for (final unit in kg) unit.symbol], ["g", "kg"]);
      expect(300 * kg.first.factor, closeTo(0.3, 1e-9));
      expect(kitchenUnitsFor("Kilos").last.factor, 1);
      expect(kitchenUnitsFor("g").last.factor, 1000);
      expect([for (final unit in kitchenUnitsFor("litros")) unit.symbol], ["ml", "l"]);
    });

    test("a supply's unit is its row's, else its stock column's, else a measure's", () {
      StockSummaryPage page({String stockUnit = "", bool unitColumn = false}) => StockSummaryPage(
        table: "s",
        columns: [
          const StockSummaryColumn(key: "f-name", name: "Name"),
          const StockSummaryColumn(key: "f-weight", name: "Weight", type: TableFieldType.measure, unit: "g"),
          if (unitColumn) const StockSummaryColumn(key: "f-unit", name: "Unidad"),
          StockSummaryColumn(key: StockSummaryColumn.stockKey, unit: stockUnit, fixed: true)
        ],
        rows: const [
          StockSummaryRow(id: "meat", values: {"f-name": "Meat", "f-unit": "", "stock": 10}),
          StockSummaryRow(id: "bread", values: {"f-name": "Bread", "f-unit": "pieza", "stock": 40})
        ]
      );

      String unitOf(StockSummaryPage page, String id) =>
        KitchenProduct.fromSummary(page, supplies: true).firstWhere((product) => product.id == id).unit;

      expect(unitOf(page(), "meat"), "g");
      expect(unitOf(page(stockUnit: "kg"), "meat"), "kg");
      expect(unitOf(page(stockUnit: "kg", unitColumn: true), "meat"), "kg", reason: "an empty row falls to the table's");
      expect(unitOf(page(stockUnit: "kg", unitColumn: true), "bread"), "pieza");
    });

    test("anything else is written only in its own unit", () {
      expect(kitchenUnitsFor("slice"), const [KitchenUnit("slice", 1)]);
      expect(kitchenUnitsFor(""), const [KitchenUnit("", 1)]);
    });

    test("a quantity reads in the unit it reads best in", () {
      final meat = kitchenBestUnit(0.3, "kg");
      expect((meat.qty, meat.unit.symbol), (300, "g"));

      final sack = kitchenBestUnit(2, "kg");
      expect((sack.qty, sack.unit.symbol), (2, "kg"));

      final milk = kitchenBestUnit(1500, "ml");
      expect((milk.qty, milk.unit.symbol), (1.5, "l"));

      final bread = kitchenBestUnit(1, "");
      expect((bread.qty, bread.unit.symbol), (1, ""));
    });
  });

  group("form", () {
    test("the name is the title, the price the first price, the rest what a field can hold", () {
      final fields = MadeFields.of(const [
        TableFieldModel(id: "f-photo", name: "Photo", type: "IMAGE"),
        TableFieldModel(id: "f-notes", name: "Notes", type: "TEXT"),
        TableFieldModel(id: "f-name", name: "Name", type: "TITLE"),
        TableFieldModel(id: "f-price", name: "Price", type: "PRICE"),
        TableFieldModel(id: "f-stock", name: "Stock", type: "STOCK")
      ]);

      expect(fields.name?.id, "f-name");
      expect(fields.price?.id, "f-price");
      expect([for (final field in fields.others) field.id], ["f-notes"]);
    });

    test("a product is read with what it consumes", () {
      final page = TableViewModel.fromResponse({
        "keys": ["id", "f-name", "f-price"],
        "values": [["burger", "Cheese burger", 8.5]],
        "consumes": {"burger": {"mode": "order", "available": 100, "lines": [
          {"id": "l1", "tableId": "s", "productId": "meat", "name": "Meat", "qty": 0.3}
        ]}}
      }, tableId: "menu").alignedTo(_fields);

      final product = MadeProduct.listFrom(page).single;

      expect(product.id, "burger");
      expect(product.values, {"f-name": "Cheese burger", "f-price": "8.5"});
      expect(product.consumes!.availability.available, 100);
      expect(product.consumes!.recipe.lines.single.qty, 0.3);
    });

    testWidgets("a table without a name or a price gets both before its first product", (tester) async {
      final source = _Menu(fields: const []);
      final service = await _service(tester, source);

      final saved = await service.save(
        tester.element(find.byType(SizedBox)),
        nameTitle: "Name",
        priceTitle: "Price",
        draft: _burger
      );

      expect(saved, isTrue);
      expect([for (final field in source.createdFields) (field["NAME"], field["TYPE"], field["POSITION"])], [
        ("Name", "TITLE", 0),
        ("Price", "PRICE", 1)
      ]);
      expect(source.created.single["DATA"], {"f-name": "Cheese burger", "f-price": "8.5"});
      expect(source.created.single["BATCH"], isFalse);
      expect((source.created.single["CONSUMES"] as List).single, {"TABLE_ID": "s", "PRODUCT_ID": "meat", "QUANTITY": 0.3});
      expect(service.products.single.id, "burger", reason: "the list is read again");
      expect(service.unitOf("meat"), "kg");
    });

    testWidgets("an edit sends only the columns that changed, and every line", (tester) async {
      final source = _Menu(fields: _fields, rows: [["burger", "Cheese burger", "8.5"]]);
      final service = await _service(tester, source);

      final saved = await service.save(
        tester.element(find.byType(SizedBox)),
        product: service.products.single,
        nameTitle: "Name",
        priceTitle: "Price",
        draft: _draft(price: "9", mode: RecipeMode.batch)
      );

      expect(saved, isTrue);
      expect(source.createdFields, isEmpty);
      expect(source.edited.single["ID"], "burger");
      expect(source.edited.single["DATA"], {"f-price": "9"});
      expect(source.edited.single["BATCH"], isTrue);
      expect(source.edited.single["CONSUMES"], hasLength(1));
    });

    testWidgets("a made table lists its products with what each consumes, in the unit it reads best in", (tester) async {
      final source = _Menu(fields: _fields, rows: [["burger", "Cheese burger", "8.5"]], consumes: {
        "burger": {"mode": "order", "available": 100, "lines": [
          {"id": "l1", "tableId": "s", "productId": "meat", "name": "Meat", "qty": 0.3},
          {"id": "l2", "tableId": "s", "productId": "bread", "name": "Bread", "qty": 1}
        ]}
      });
      final service = await _service(tester, source);

      await tester.pumpWidget(_app(MadeProductsSection(
        tableId: "menu",
        parts: const InventoryBarParts(selector: SizedBox(), controls: []),
        service: service
      )));
      await tester.pumpAndSettle();

      expect(find.text("Cheese burger"), findsOneWidget);
      expect(find.text("Meat"), findsOneWidget);
      expect(find.text("300 g"), findsOneWidget);
      expect(find.text("Bread"), findsOneWidget);
      expect(find.text("×1"), findsOneWidget);
    });

    testWidgets("a line is written in grams and travels in the supply's kilos", (tester) async {
      RecipeDraft? saved;

      await tester.pumpWidget(_app(SingleChildScrollView(child: RecipeEditor(
        recipe: const Recipe(productId: "burger", tableId: "menu", lines: [
          RecipeLine(id: "l1", tableId: "s", productId: "meat", name: "Meat", qty: 0.3)
        ]),
        supplies: false,
        canEdit: true,
        units: const {"meat": "kg"},
        onSave: (draft) async {
          saved = draft;
          return true;
        },
        onCancel: () {}
      ))));
      await tester.pumpAndSettle();

      expect(find.text("300"), findsOneWidget);
      expect(find.text("g"), findsOneWidget);

      await tester.enterText(find.text("300"), "250");
      await tester.tap(find.text(S.current.save));
      await tester.pumpAndSettle();

      expect(saved!.lines.single.qty, 0.25);

      // Switched to kilos, the same figure is kilos.
      await tester.tap(find.text("g"));
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.current.save));
      await tester.pumpAndSettle();

      expect(saved!.lines.single.qty, 250);
    });

    testWidgets("a line folded and unfolded again keeps its waste and takes the focus", (tester) async {
      RecipeDraft? saved;

      await tester.pumpWidget(_app(SingleChildScrollView(child: RecipeEditor(
        recipe: const Recipe(productId: "burger", tableId: "menu", lines: [
          RecipeLine(id: "l1", tableId: "s", productId: "meat", name: "Meat", qty: 0.3, waste: 5)
        ]),
        supplies: false,
        canEdit: true,
        units: const {"meat": "kg"},
        onSave: (draft) async {
          saved = draft;
          return true;
        },
        onCancel: () {}
      ))));
      await tester.pumpAndSettle();

      // Unfolded (it has waste), folded, unfolded: its input is mounted twice on one controller.
      await tester.tap(find.byIcon(CI.arrow_top));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(CI.arrow_down));
      await tester.pumpAndSettle();

      await tester.tap(find.text("5"));
      await tester.pumpAndSettle();
      await tester.enterText(find.text("5"), "10");
      await tester.tap(find.text(S.current.save));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(saved!.lines.single.waste, 10);
    });

    testWidgets("a first description creates its column; an added detail its own", (tester) async {
      final source = _Menu(fields: _fields);
      final service = await _service(tester, source);

      await service.save(
        tester.element(find.byType(SizedBox)),
        nameTitle: "Name",
        priceTitle: "Price",
        descriptionTitle: "Description",
        draft: _draft(description: "Beef and cheddar", added: const {"Calories": "540"})
      );

      expect([for (final field in source.createdFields) (field["NAME"], field["TYPE"])], [
        ("Description", "DESCRIPTION"),
        ("Calories", "TEXT")
      ]);
      expect(source.created.single["DATA"], {
        "f-Calories": "540",
        "f-description": "Beef and cheddar",
        "f-name": "Cheese burger",
        "f-price": "8.5"
      });
    });

    testWidgets("a photo goes up against the record once it exists", (tester) async {
      // The upload travels as a file, written to the temp folder.
      const channel = MethodChannel("plugins.flutter.io/path_provider");
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async => Directory.systemTemp.path);
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));

      final source = _Menu(fields: _fields);
      final service = await _service(tester, source);
      final context = tester.element(find.byType(SizedBox));

      await tester.runAsync(() => service.save(
        context,
        nameTitle: "Name",
        priceTitle: "Price",
        draft: _draft(photo: MadePhoto.replace(Uint8List.fromList([1, 2, 3])))
      ));

      expect(source.images, ["add burger"]);
    });

    testWidgets("a product offers a new group, one it starts offering, and stops offering another", (tester) async {
      const dough = ModifierGroup(id: "dough", name: "Dough", min: 1, max: 1, products: [(tableId: "menu", productId: "pizza")],
        options: [ModifierOption(id: "thin", name: "Thin")]);
      const sauces = ModifierGroup(id: "sauces", name: "Sauces", products: [(tableId: "menu", productId: "burger")],
        options: [ModifierOption(id: "bbq", name: "BBQ")]);
      const extras = ModifierGroup(id: "", name: "Extras", options: [ModifierOption(name: "Pickles", price: 0.5)]);

      final kitchen = _Kitchen([dough, sauces]);
      final source = _Menu(fields: _fields, rows: [["burger", "Cheese burger", "8.5"]]);
      final service = await _service(tester, source, kitchen: kitchen);

      expect(service.groupsOf("burger").single.id, "sauces");

      await service.save(
        tester.element(find.byType(SizedBox)),
        product: service.products.single,
        nameTitle: "Name",
        priceTitle: "Price",
        draft: _draft(groups: [(group: dough, edited: false), (group: extras, edited: true)])
      );

      List<String> offering(String id) => [
        for (final product in kitchen.saved.firstWhere((body) => (body["ID"] ?? "") == id)["PRODUCTS"] as List)
          product["PRODUCT_ID"] as String
      ];

      expect(kitchen.saved, hasLength(3));
      expect(offering("dough"), ["pizza", "burger"]);
      expect(offering(""), ["burger"]);
      expect(offering("sauces"), isEmpty);
    });

    testWidgets("an edit that changes no column sends no DATA", (tester) async {
      final source = _Menu(fields: _fields, rows: [["burger", "Cheese burger", "8.5"]]);
      final service = await _service(tester, source);

      await service.save(
        tester.element(find.byType(SizedBox)),
        product: service.products.single,
        nameTitle: "Name",
        priceTitle: "Price",
        draft: _burger
      );

      expect(source.edited.single.containsKey("DATA"), isFalse);
    });
  });
}

const _fields = [
  TableFieldModel(id: "f-name", name: "Name", type: "TITLE"),
  TableFieldModel(id: "f-price", name: "Price", type: "PRICE")
];

final MadeProductDraft _burger = _draft();

MadeProductDraft _draft({
  String price = "8.5",
  String description = "",
  Map<String, String> added = const {},
  MadePhoto photo = const MadePhoto.keep(),
  RecipeMode mode = RecipeMode.order,
  List<MadeGroupChoice>? groups
}) => (
  name: "Cheese burger",
  price: price,
  description: description,
  values: const <String, String>{},
  added: added,
  photo: photo,
  mode: mode,
  lines: const <RecipeLineDraft>[(tableId: "s", productId: "meat", qty: 0.3, negotiable: false, waste: 0)],
  groups: groups
);

Future<MadeProductsService> _service(WidgetTester tester, _Menu source, {_Kitchen? kitchen}) async {
  await tester.pumpWidget(const SizedBox());

  final service = MadeProductsService(tableId: "menu", source: source, search: _Supplies(), kitchen: kitchen ?? _Kitchen());
  addTearDown(service.dispose);

  await service.load();
  return service;
}

Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: const [
    S.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate
  ],
  supportedLocales: S.delegate.supportedLocales,
  home: Builder(builder: (context) {
    AppSize.instance(context);

    return Scaffold(body: ChangeNotifierProvider<HomeService>.value(
      value: HomeService(),
      child: SizedBox(width: 1200, height: 700, child: child)
    ));
  })
);

/// The company's modifier groups, and the bodies written to them.
class _Kitchen extends MadeKitchenApi {
  _Kitchen([this.known = const []]);

  final List<ModifierGroup> known;
  final saved = <Map<String, dynamic>>[];

  @override
  Future<List<ModifierGroup>> groups() async => known;

  @override
  Future<void> saveGroup(Map<String, dynamic> body) async => saved.add(body);

  @override
  Future<DishCost?> cost(String productId) async => null;
}

/// The supplies, by id: meat counted in kg.
class _Supplies extends KitchenProductSearch {
  @override
  Future<Map<String, KitchenProduct>> suppliesById() async =>
    const {"meat": KitchenProduct(id: "meat", tableId: "s", name: "Meat", unit: "kg", supplies: true)};
}

/// A made table: its columns (grown by a created field) and its records; a created record is
/// the burger.
class _Menu implements InventorySource {
  _Menu({required List<TableFieldModel> fields, List<List<dynamic>>? rows, this.consumes = const {}})
    : _fields = [...fields],
      _rows = rows ?? [];

  final List<TableFieldModel> _fields;
  final List<List<dynamic>> _rows;
  final images = <String>[];

  /// `records/list`'s `consumes`.
  final Map<String, dynamic> consumes;
  final createdFields = <Map<String, dynamic>>[];
  final created = <Map<String, dynamic>>[];
  final edited = <Map<String, dynamic>>[];

  @override
  Future<TableStructureModel> structure(String tableId) async =>
    TableStructureModel(id: tableId, records: _rows.length, fields: List.of(_fields));

  @override
  Future<void> createField(Map<String, dynamic> request) async {
    createdFields.add(request);
    _fields.add(TableFieldModel(
      id: switch (request["TYPE"]) {"TITLE" => "f-name", "PRICE" => "f-price", "DESCRIPTION" => "f-description", _ => "f-${request["NAME"]}"},
      name: request["NAME"],
      type: request["TYPE"]
    ));
  }

  @override
  Future<({TableViewModel page, int? total})> records(
    String tableId, {
    required int page,
    required int size,
    String match = ""
  }) async => (
    page: TableViewModel(
      columns: [
        const TableColumnModel(id: "id", name: "id"),
        for (final field in _fields) TableColumnModel(id: field.id, name: field.name)
      ],
      rows: [for (final row in _rows) TableRowModel(row)],
      consumes: MadeConsumes.mapFrom(consumes, tableId: tableId)
    ),
    total: _rows.length
  );

  @override
  Future<String> createRecord(Map<String, dynamic> request) async {
    created.add(request);
    _rows.add(["burger", "Cheese burger", "8.5"]);
    return "burger";
  }

  @override
  Future<void> editRecord(Map<String, dynamic> request) async => edited.add(request);

  @override
  Future<List<ProductImage>> addImage(String tableId, String recordId, File file) async {
    images.add("add $recordId");
    return const [];
  }

  @override
  Future<void> removeImage(String tableId, String recordId, String fileId) async => images.add("remove $recordId $fileId");

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
