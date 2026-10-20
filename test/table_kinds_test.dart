import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/services/home/home_service.dart';
import 'package:app/services/catalog/currency_model.dart';
import 'package:app/services/inventory/picture_import_service.dart';
import 'package:app/services/inventory/table_template_model.dart';
import 'package:app/services/kitchen/kitchen_products_service.dart';
import 'package:app/services/kitchen/recipe_availability_model.dart';
import 'package:app/services/stock/sources/inventory_source.dart';
import 'package:app/services/stock/sources/stock_source.dart';
import 'package:app/services/stock/summary/stock_summary_model.dart';
import 'package:app/services/stock/summary/stock_summary_service.dart';
import 'package:app/services/stock/tables/table_lite_model.dart';
import 'package:app/services/stock/tables/tables_service.dart';
import 'package:app/screens/home/sections/_sections.dart';
import 'package:app/screens/home/sections/inventory/_inventory.dart';
import 'package:app/screens/home/sections/inventory/table_list/inventory_start.dart';
import 'package:app/screens/home/sections/inventory/table_list/stock_summary/summary_layout.dart';
import 'package:app/screens/home/sections/inventory/table_list/stock_summary/summary_product_row.dart';
import 'package:app/screens/home/sections/inventory/table_list/stock_summary/summary_stepper.dart';
import 'package:app/screens/home/sections/inventory/table_list/inventory_bar.dart';
import 'package:app/screens/home/sections/inventory/table_list/supplies/_supplies.dart';
import 'package:app/screens/modals/inventory/create_table/_create_table.dart';
import 'package:app/toolkit/api.dart';
import 'package:app/toolkit/settings/routes.dart';

/// Supplies and products are different tables in one section, and no table shows in two
/// (`cocina-frontend.md` §2): the inventory lists catalogs and supplies, asking the kind of a new
/// one, and the menu made products only; a supplies table's list reads the table it was opened
/// on; and a catalog's dish made to order shows in its stock column what its supplies allow, with
/// no buttons (it has no shelf to move).
const _menu = "550e8400-e29b-41d4-a716-446655440000";
const _pantry = "550e8400-e29b-41d4-a716-446655440001";

const _catalog = TableLiteModel(id: _menu, title: "Menu", primary: true);
const _supplies = TableLiteModel(id: _pantry, title: "Pantry", kind: TableKind.supplies);
const _burgers = "550e8400-e29b-41d4-a716-446655440002";
const _made = TableLiteModel(id: _burgers, title: "Burgers", kind: TableKind.made);

void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFffffff));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));

    TestWidgetsFlutterBinding.ensureInitialized();
    Navis.defineRoutes(routes);
  });

  tearDown(() => useBusiness(null));

  Future<TablesService> inventory(WidgetTester tester, String path, List<TableLiteModel> answer) async {
    Navis.navigate(path);

    final source = _Inventory();
    final tables = TablesService(source: source);
    addTearDown(tables.dispose);

    await tester.pumpWidget(_app(const InventorySection(), tables: tables));
    await tester.pump();

    // Every table being imported: what opens is drawn without mounting a view (which reads).
    for (final table in answer) {
      tables.seedImport(table.id, TableImportStage.preparing);
    }

    source.answer.complete(answer);
    await tester.pump();
    await tester.pump();

    return tables;
  }

  testWidgets("the inventory opens a supplies table beside its catalogs, by its link", (tester) async {
    await inventory(tester, "${HomeSection.inventory.path}/$_pantry", const [_catalog, _supplies]);

    expect(tester.takeException(), isNull);
    expect(find.text("Pantry"), findsOneWidget);
    expect(find.text("Menu"), findsNothing);
  });

  testWidgets("the inventory never opens a made products table, not even by its link: it is the menu's", (tester) async {
    await inventory(tester, "${HomeSection.inventory.path}/$_burgers", const [_catalog, _made, _supplies]);

    expect(tester.takeException(), isNull);
    expect(find.text("Menu"), findsOneWidget);
    expect(find.text("Burgers"), findsNothing);
    expect(find.text("Pantry"), findsNothing);
  });

  testWidgets("a company with made products only is offered to create its inventory", (tester) async {
    await inventory(tester, HomeSection.inventory.path, const [_made]);

    expect(find.byType(InventoryStart), findsOneWidget);
    expect(find.text("Burgers"), findsNothing);
  });

  testWidgets("a company with supplies tables only opens them, not the start", (tester) async {
    await inventory(tester, HomeSection.inventory.path, const [_supplies]);

    expect(tester.takeException(), isNull);
    expect(find.byType(InventoryStart), findsNothing);
    expect(find.text("Pantry"), findsOneWidget);
  });

  testWidgets("a new inventory table asks what it holds, says it is for good, and sends it", (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final source = _Inventory.answering(const []);
    final tables = TablesService(source: source);
    addTearDown(tables.dispose);

    await tester.pumpWidget(_app(const SingleChildScrollView(child: CreateTableModal()), tables: tables));
    await tester.pump();

    expect(find.text(S.current.table_kind_catalog), findsOneWidget);
    expect(find.text(S.current.create_table_kind_fixed), findsOneWidget);

    await tester.enterText(find.byType(EditableText).first, "Pantry");
    await tester.tap(find.text(S.current.table_kind_supplies));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.create_table));
    await tester.pumpAndSettle();

    expect(source.created.single["TITLE"], "Pantry");
    expect(source.created.single["KIND"], "supplies");
  });

  test("a supplies table's list reads the table it is opened on", () async {
    final stock = _Stock();
    final service = KitchenProductsService(listen: false, stock: stock, measure: (_) async => const {});
    addTearDown(service.dispose);

    await service.open(_supplies);

    expect(service.table!.id, _pantry);
    expect(stock.summarized, [_pantry]);
    expect(service.products.map((product) => product.id), ["burger", "salt"]);
  });

  testWidgets("a supplies table with nothing listed offers its sheet, where supplies are written", (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final service = KitchenProductsService(listen: false)..seed(table: _supplies);
    addTearDown(service.dispose);

    await tester.pumpWidget(_app(
      ChangeNotifierProvider<HomeService>.value(
        value: HomeService(),
        child: SuppliesSection(table: _supplies, parts: const InventoryBarParts(selector: SizedBox(), controls: []), service: service)
      ),
      tables: TablesService(source: _Inventory())
    ));
    await tester.pump();

    // No overflow check: the test font draws every letter as wide as it is tall, and the
    // section message's button is a fixed width that the real font's label fits in.
    tester.takeException();
    expect(find.text(S.current.kitchen_products_empty), findsOneWidget);
    expect(find.text(S.current.kitchen_open_sheet), findsOneWidget);
  });

  test("a made table's summary measures its rows' recipes", () async {
    final measured = <List<String>>[];
    final service = StockSummaryService(
      source: _Stock(),
      tableId: _menu,
      recipes: true,
      measure: (ids) async {
        measured.add(ids);
        return const {"burger": RecipeAvailability(productId: "burger", available: 3)};
      }
    );
    addTearDown(service.dispose);

    await service.load();
    await Future<void>.delayed(Duration.zero);

    expect(measured, [["burger", "salt"]]);
    expect(service.recipeOf("burger")!.available, 3);
    expect(service.recipeOf("salt"), isNull);
  });

  testWidgets("a dish made to order shows what its supplies allow, with no buttons", (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final page = _page();

    await tester.pumpWidget(_bare((context) {
      final layout = SummaryLayout.of(context, page.columns);

      return Column(children: [
        SummaryProductRow(
          row: page.rows.first,
          layout: layout,
          currency: _currency,
          recipes: true,
          recipe: const RecipeAvailability(productId: "burger", available: 3, limit: RecipeLimit(productId: "bacon", name: "bacon"))
        ),
        SummaryProductRow(row: page.rows.last, layout: layout, currency: _currency, recipes: true)
      ]);
    }));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(SummaryStepper), findsNWidgets(2));
    expect(find.descendant(of: find.byType(SummaryProductRow).first, matching: find.byType(SummaryStepper)), findsNothing);
    expect(find.text("3"), findsOneWidget);
  });
}

const _currency = CurrencyModel(code: "USD", name: "Dollar", symbol: "\$");

/// A catalog with a burger (made to order: its stock is what its supplies allow) and salt.
StockSummaryPage _page() => StockSummaryPage.fromResponse({
  "table": _menu,
  "total": 2,
  "page": 1,
  "size": 30,
  "columns": [
    {"key": "image", "type": "image", "fixed": true},
    {"key": "11111111-1111-4111-8111-111111111111", "name": "Name", "type": "text", "width": 240},
    {"key": "stock", "name": "Stock", "type": "stock", "fixed": true},
    {"key": "reserved", "type": "stock", "fixed": true}
  ],
  "data": {
    "keys": ["id", "image", "11111111-1111-4111-8111-111111111111", "stock", "reserved"],
    "values": [
      ["burger", null, "Burger", 3, 0],
      ["salt", null, "Salt", 7, 1]
    ]
  }
});

Widget _bare(Widget Function(BuildContext context) body) => MaterialApp(
  localizationsDelegates: const [
    S.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate
  ],
  supportedLocales: S.delegate.supportedLocales,
  home: Builder(builder: (context) {
    AppSize.instance(context);
    return Scaffold(body: body(context));
  })
);

Widget _app(Widget child, {required TablesService tables}) => _bare((context) => MultiProvider(
  providers: [
    ChangeNotifierProvider<TablesService>.value(value: tables),
    ChangeNotifierProvider<PictureImportService>.value(value: PictureImportService()),
    ChangeNotifierProvider<BusinessService>.value(value: BusinessService()..seed({
      "keys": ["id", "name"],
      "values": [["1842", "Bodega"]]
    }))
  ],
  child: SizedBox(width: 1200, height: 700, child: child)
));

class _Inventory implements InventorySource {
  _Inventory();

  _Inventory.answering(List<TableLiteModel> tables) {
    answer.complete(tables);
  }

  final answer = Completer<List<TableLiteModel>>();

  /// The bodies of the tables created.
  final created = <Map<String, dynamic>>[];

  @override
  Future<List<TableLiteModel>> tables() => answer.future;

  @override
  Future<String> createTable(Map<String, dynamic> request) async {
    created.add(request);
    return "pantry-2";
  }

  @override
  Future<List<TableTemplateModel>> templates() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A summary of [_page] for any table, noting which ones were read.
class _Stock implements StockSource {
  final summarized = <String>[];

  @override
  Future<StockSummaryPage> summary({required int page, required int size, String match = "", String tableId = "", StockSummarySort? sort}) async {
    summarized.add(tableId);
    return _page();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
