import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:core/form.dart';
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
import 'package:app/screens/home/sections/inventory/table_list/_table_list.dart';
import 'package:app/screens/home/sections/inventory/table_list/inventory_start.dart';
import 'package:app/screens/home/sections/inventory/table_list/stock_summary/summary_layout.dart';
import 'package:app/screens/home/sections/inventory/table_list/stock_summary/summary_product_row.dart';
import 'package:app/screens/home/sections/inventory/table_list/stock_summary/summary_stepper.dart';
import 'package:app/screens/home/sections/inventory/table_list/view_toggle.dart';
import 'package:app/screens/home/sections/inventory/table_view/_table_view.dart';
import 'package:app/screens/home/sections/supply_chain/recipes/_recipes.dart';
import 'package:app/toolkit/api.dart';
import 'package:app/toolkit/settings/routes.dart';

/// Supplies and products are different tables, and no table shows in both sections
/// (`cocina-frontend.md` §2.1): the inventory lists catalogs only, the production line supplies
/// only, each with its own empty state; and a catalog's dish made to order shows in its stock
/// column what its supplies allow, with no buttons (it has no shelf to move).
const _menu = "550e8400-e29b-41d4-a716-446655440000";
const _pantry = "550e8400-e29b-41d4-a716-446655440001";

const _catalog = TableLiteModel(id: _menu, title: "Menu", primary: true);
const _supplies = TableLiteModel(id: _pantry, title: "Pantry", supplies: true);

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

  testWidgets("the inventory never opens a supplies table, not even by its link", (tester) async {
    await inventory(tester, "${HomeSection.inventory.path}/$_pantry", const [_catalog, _supplies]);

    expect(tester.takeException(), isNull);
    expect(find.text("Menu"), findsOneWidget);
    expect(find.text("Pantry"), findsNothing);
  });

  testWidgets("a company with supplies tables only is offered to create its products'", (tester) async {
    await inventory(tester, HomeSection.inventory.path, const [_supplies]);

    expect(tester.takeException(), isNull);
    expect(find.byType(InventoryStart), findsOneWidget);
    expect(find.text("Pantry"), findsNothing);
  });

  test("the production line reads the supplies tables only", () async {
    final stock = _Stock();
    final service = KitchenProductsService(listen: false, inventory: _Inventory.answering(const [_catalog, _supplies]), stock: stock, measure: (_) async => const {});
    addTearDown(service.dispose);

    await service.load(tableId: _menu);

    expect(service.tables.map((table) => table.id), [_pantry]);
    expect(service.table!.id, _pantry);
    expect(stock.summarized, [_pantry]);

    final none = KitchenProductsService(listen: false, inventory: _Inventory.answering(const [_catalog]), stock: stock, measure: (_) async => const {});
    addTearDown(none.dispose);

    await none.load();

    expect(none.status, KitchenProductsStatus.empty);
    expect(none.table, isNull);
    expect(stock.summarized, [_pantry]);
  });

  testWidgets("with no supplies table the tab offers to create one", (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final service = KitchenProductsService(listen: false)..seed();
    addTearDown(service.dispose);

    await tester.pumpWidget(_app(
      ChangeNotifierProvider<KitchenProductsService>.value(value: service, child: const RecipesTab()),
      tables: TablesService(source: _Inventory())
    ));
    await tester.pump();

    // No overflow check: the test font draws every letter as wide as it is tall, and the
    // section message's button is a fixed width that the real font's label fits in.
    tester.takeException();
    expect(find.text(S.current.supply_chain_no_tables), findsOneWidget);
    expect(find.text(S.current.supply_chain_table_create), findsOneWidget);
  });

  testWidgets("a supplies table with nothing listed offers its sheet, where supplies are written", (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final service = KitchenProductsService(listen: false)..seed(tables: const [_supplies]);
    addTearDown(service.dispose);

    await tester.pumpWidget(_app(
      ChangeNotifierProvider<KitchenProductsService>.value(value: service, child: const RecipesTab()),
      tables: TablesService(source: _Inventory())
    ));
    await tester.pump();

    // Same font caveat as above.
    tester.takeException();
    expect(find.text(S.current.supply_chain_products_empty), findsOneWidget);
    expect(find.text(S.current.supply_chain_open_sheet), findsOneWidget);
    expect(find.byType(InventoryViewToggle), findsOneWidget);
    expect(find.byType(TableViewSection), findsNothing);
  });

  testWidgets("the list comes back from the sheet with a working search", (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final service = KitchenProductsService(listen: false, inventory: _Inventory.answering(const [_supplies]), stock: _Stock(), measure: (_) async => const {});
    addTearDown(service.dispose);
    await service.load();

    await tester.pumpWidget(_app(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<KitchenProductsService>.value(value: service),
          ChangeNotifierProvider<HomeService>.value(value: HomeService())
        ],
        child: const RecipesTab()
      ),
      tables: TablesService(source: _Inventory())
    ));
    await tester.pump();
    tester.takeException();

    // List, sheet, list, sheet, list: the search input mounts each time on a live controller.
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byType(InventoryViewToggle));
      await tester.pump();
      await tester.pump();

      expect(find.byType(TableViewSection), i.isEven ? findsOneWidget : findsNothing);

      final error = tester.takeException();
      expect(error.toString(), isNot(contains("disposed")));
    }

    expect(find.byType(SearchInput), findsOneWidget);
  });

  test("a catalog's summary measures its rows' recipes", () async {
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

  @override
  Future<List<TableLiteModel>> tables() => answer.future;

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
