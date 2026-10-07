import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:core/button.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/services/inventory/table_template_model.dart';
import 'package:app/services/inventory/table_templates_service.dart';
import 'package:app/services/stock/sources/inventory_source.dart';
import 'package:app/services/stock/tables/table_lite_model.dart';
import 'package:app/services/stock/tables/tables_service.dart';
import 'package:app/screens/home/sections/_sections.dart';
import 'package:app/screens/home/sections/inventory/table_list/_table_list.dart';
import 'package:app/screens/home/sections/inventory/table_list/inventory_bar.dart';
import 'package:app/screens/home/sections/inventory/table_list/inventory_start.dart';
import 'package:app/screens/home/sections/inventory/table_list/stock_summary/_stock_summary.dart';
import 'package:app/screens/home/sections/inventory/table_view/_table_view.dart';
import 'package:app/toolkit/api.dart';
import 'package:app/toolkit/settings/routes.dart';

/// The inventory section opens one table at a time, picked in its bar: the link's, else
/// the remembered one, else the primary. A table still being imported shows what its
/// import is up to instead of a view (an untyped sheet with no rows reads as a failed
/// import, and gets imported again). A company with no table is offered the templates.
const _first = "550e8400-e29b-41d4-a716-446655440000";
const _second = "550e8400-e29b-41d4-a716-446655440001";

const _tables = [
  TableLiteModel(id: _first, title: "Precios", primary: true),
  TableLiteModel(id: _second, title: "Depósito")
];

class _Inventory implements InventorySource {
  _Inventory({this.templatesAnswer = const []});

  final List<TableTemplateModel> templatesAnswer;

  /// The tables' answer, held until the test lets it go.
  final answer = Completer<List<TableLiteModel>>();

  int templateReads = 0;

  @override
  Future<List<TableLiteModel>> tables() => answer.future;

  @override
  Future<List<TableTemplateModel>> templates() async {
    templateReads++;
    return templatesAnswer;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app(Widget child, {required TablesService tables}) => MaterialApp(
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
        ChangeNotifierProvider<BusinessService>.value(value: BusinessService()..seed({
          "keys": ["id", "name"],
          "values": [["1842", "Bodega"]]
        }))
      ],
      child: SizedBox(width: 1200, height: 700, child: child)
    ));
  })
);

/// Mounts the section on [path] with every table being imported, so what opens is
/// drawn without mounting a view (which would read). The stages are seeded once the
/// read started (a first read drops another company's imports) and before it lands.
Future<void> _open(WidgetTester tester, String path) async {
  Navis.navigate(path);

  final source = _Inventory();
  final tables = TablesService(source: source);
  addTearDown(tables.dispose);

  await tester.pumpWidget(_app(const InventorySection(), tables: tables));
  await tester.pump();

  for (final table in _tables) {
    tables.seedImport(table.id, TableImportStage.preparing);
  }

  source.answer.complete(_tables);
  await tester.pump();
  await tester.pump();
}

void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));

    TestWidgetsFlutterBinding.ensureInitialized();
    Navis.defineRoutes(routes);
  });

  tearDown(() => useBusiness(null));

  test('a table is busy through both halves of the import', () {
    final tables = TablesService();
    addTearDown(tables.dispose);

    expect(tables.isBusy(_first), isFalse);

    tables.seedImport(_first, TableImportStage.preparing);
    expect(tables.isBusy(_first), isTrue);

    tables.seedImport(_first, TableImportStage.loading);
    expect(tables.importStage(_first), TableImportStage.loading);

    expect(tables.isBusy(_second), isFalse);
  });

  testWidgets('without a link the primary table opens', (tester) async {
    await _open(tester, HomeSection.inventory.path);

    expect(find.text("Precios"), findsOneWidget);
    expect(find.text("Depósito"), findsNothing);
  });

  testWidgets("the bar ends in the open table's options and create, against the edge", (tester) async {
    await _open(tester, HomeSection.inventory.path);

    // The options menu carries the settings: no gear of its own.
    expect(find.byIcon(CI.setting), findsNothing);
    expect(find.byIcon(CI.dots_horizontal), findsOneWidget);

    final options = tester.getCenter(find.byIcon(CI.dots_horizontal)).dx;
    final create = find.ancestor(
      of: find.text(S.current.create_table),
      matching: find.byType(Button)
    ).first;

    expect(tester.getCenter(create).dx, greaterThan(options));
    // Only the bar's padding is left after create.
    final bar = tester.getTopRight(find.byType(InventoryBar)).dx;
    expect(tester.getTopRight(create).dx, closeTo(bar - AppSize.gap, 1));
  });

  testWidgets("the bar's status sits in its middle", (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) {
        AppSize.instance(context);

        return Center(child: SizedBox(width: 1200, child: InventoryBar(
          parts: const InventoryBarParts(
            selector: SizedBox(width: 120),
            controls: [SizedBox(width: 40)],
            actions: [SizedBox(width: 300)]
          ),
          status: const [SizedBox(key: Key("count"), width: 80)]
        )));
      })
    ));

    final bar = tester.getRect(find.byType(InventoryBar));
    expect(tester.getCenter(find.byKey(const Key("count"))).dx, closeTo(bar.center.dx, 1));
  });

  testWidgets("a table's link opens that table", (tester) async {
    await _open(tester, "/home/inventory/$_second");

    expect(Navis.currentKey.value, TableViewSection.routeKey);
    expect(find.text("Depósito"), findsOneWidget);
    expect(find.text("Precios"), findsNothing);
  });

  testWidgets('a table being imported shows its import, not a view', (tester) async {
    await _open(tester, HomeSection.inventory.path);

    expect(find.text(S.current.import_table_preparing), findsOneWidget);
    expect(find.byType(StockSummarySection), findsNothing);
    expect(find.byType(TableViewSection), findsNothing);
  });

  testWidgets('with no table the templates are offered, with a blank one', (tester) async {
    final source = _Inventory(templatesAnswer: const [
      TableTemplateModel(
        id: "menu",
        name: "Menú",
        description: "Platos y bebidas",
        fields: [TableTemplateField(name: "Nombre", type: "title")]
      )
    ]);

    final templates = TableTemplatesService(source: source);
    addTearDown(templates.dispose);

    final tables = TablesService(source: source);
    addTearDown(tables.dispose);

    await tester.pumpWidget(_app(
      InventoryStart(templates: templates, onCreated: (_) {}, onBlank: () {}),
      tables: tables
    ));
    await tester.pump();
    await tester.pump();

    expect(source.templateReads, 1);
    expect(find.text("Menú"), findsOneWidget);
    expect(find.text("Platos y bebidas"), findsOneWidget);
    expect(find.text(S.current.inventory_start_blank), findsOneWidget);
  });
}
