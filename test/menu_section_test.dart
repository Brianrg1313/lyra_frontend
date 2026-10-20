import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/services/inventory/picture_import_service.dart';
import 'package:app/services/inventory/table_template_model.dart';
import 'package:app/services/stock/sources/inventory_source.dart';
import 'package:app/services/stock/tables/table_lite_model.dart';
import 'package:app/services/stock/tables/tables_service.dart';
import 'package:app/screens/home/sections/_sections.dart';
import 'package:app/screens/home/sections/menu/_menu.dart';
import 'package:app/screens/modals/inventory/create_table/_create_table.dart';
import 'package:app/toolkit/settings/routes.dart';

/// The menu reads the inventory's tables and keeps the made products' only (the inventory's
/// side of the split is pinned in `table_kinds_test`): a company without one is offered the first.
class _Inventory implements InventorySource {
  _Inventory(this.answer);

  final List<TableLiteModel> answer;

  /// The bodies of the tables created.
  final created = <Map<String, dynamic>>[];

  @override
  Future<List<TableLiteModel>> tables() async => answer;

  @override
  Future<String> createTable(Map<String, dynamic> request) async {
    created.add(request);
    return "menu-1";
  }

  @override
  Future<List<TableTemplateModel>> templates() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<_Inventory> _mount(WidgetTester tester, Widget section, List<TableLiteModel> answer) async {
  final source = _Inventory(answer);
  final tables = TablesService(source: source);
  addTearDown(tables.dispose);

  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: Builder(builder: (context) {
      AppSize.instance(context);

      return Scaffold(body: MultiProvider(
        providers: [
          ChangeNotifierProvider<TablesService>.value(value: tables),
          ChangeNotifierProvider<PictureImportService>.value(value: PictureImportService()),
          ChangeNotifierProvider<BusinessService>.value(value: BusinessService()..seed({
            "keys": ["id", "name"],
            "values": [["1842", "Bodega"]]
          }))
        ],
        child: SizedBox(width: 1200, height: 700, child: section)
      ));
    })
  ));

  await tester.pump();
  await tester.pump();

  return source;
}

void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));

    TestWidgetsFlutterBinding.ensureInitialized();
    Navis.defineRoutes(routes);
  });

  test('the menu sits right under the inventory, before the supply chain', () {
    expect(HomeSection.resources.take(3), [HomeSection.inventory, HomeSection.menu, HomeSection.supplyChain]);
  });

  testWidgets('a company with catalogs only is offered its first menu', (tester) async {
    await _mount(tester, const MenuSection(), const [
      TableLiteModel(id: "catalog-1", title: "Precios", primary: true),
      TableLiteModel(id: "supplies-1", title: "Insumos", kind: TableKind.supplies)
    ]);

    expect(find.text(S.current.menu_empty_title), findsOneWidget);
    expect(find.text(S.current.menu_create), findsOneWidget);
    expect(find.text("Precios"), findsNothing);
    expect(find.text("Insumos"), findsNothing);
  });

  testWidgets("a new menu starts with its name and price, or with a restaurant's columns, never a catalog's", (tester) async {
    final source = await _mount(tester, const CreateTableModal(kind: TableKind.made), const []);

    expect(find.text(S.current.menu_create_blank), findsOneWidget);
    expect(find.text(S.current.table_template_title), findsNothing, reason: "no clothing nor shoes for a menu");

    await tester.enterText(find.byType(EditableText).first, "Lunch");
    await tester.tap(find.text(S.current.menu_create_dishes));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.menu_create_action));
    await tester.pumpAndSettle();

    expect(source.created.single["TITLE"], "Lunch");
    expect(source.created.single["TEMPLATE"], "MENU");
    expect(source.created.single["KIND"], "made");
  });
}
