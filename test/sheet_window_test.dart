import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:core/kit/app_size.dart';
import 'package:core/kit/theme_color.dart';

import 'package:app/generated/l10n.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/services/catalog/currency_catalog_service.dart';
import 'package:app/services/stock/tables/table_structure_model.dart';
import 'package:app/services/stock/tables/table_view_model.dart';
import 'package:app/services/stock/tables/table_view_service.dart';
import 'package:app/toolkit/theme/dark.dart';
import 'package:app/toolkit/theme/light.dart';

import 'package:app/screens/home/sections/inventory/table_view/cell.dart';
import 'package:app/screens/home/sections/inventory/table_view/field_cell.dart';
import 'package:app/screens/home/sections/inventory/table_view/gutter.dart';
import 'package:app/screens/home/sections/inventory/table_view/sheet.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_cell.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_columns.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_controller.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_cursor.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_dates.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_drafts.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_hover.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_metrics.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_selection.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_widths.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_window.dart';

/// A table of [count] records and [width] text columns, made as they are looked at.
class _Wide extends TableViewService {
  _Wide({required this.count, required this.width});

  final int count;
  final int width;

  /// The rows the sheet asked to read, one entry per ask.
  final List<(int, int)> asked = [];

  late final List<TableFieldModel> _fields = [
    for (var i = 0; i < width; i++) TableFieldModel(id: "f$i", name: "Field $i", type: "TEXT")
  ];

  final Map<int, TableRowModel> _made = {};

  @override
  List<TableFieldModel> get fields => _fields;

  @override
  int get records => count;

  @override
  TableRowModel? rowAt(int index) => index < 0 || index >= count
    ? null
    : _made[index] ??= TableRowModel(
        [for (var i = 0; i < width; i++) "v$index-$i"],
        id: "r$index"
      );

  @override
  void ensureRange(int first, int last) => asked.add((first, last));
}

void main() {
  setUpAll(() {
    ThemeColor.light = lightScheme;
    ThemeColor.dark = darkScheme;
  });

  group('which columns a row builds', () {
    // Five columns 100 wide: their edges.
    const edges = <double>[0, 100, 200, 300, 400, 500];

    test('the ones the band shows, and one more on each side', () {
      final span = SheetSpan.of(edges, offset: 150, viewport: 100);

      // 150 to 250 shows columns 1 and 2.
      expect((span.first, span.last), (0, 3));
      expect(span.lead, 0);
    });

    test('the ones to the left are a blank as wide as they are', () {
      final span = SheetSpan.of(edges, offset: 320, viewport: 100);

      expect((span.first, span.last), (2, 4));
      expect(span.lead, 200);
    });

    test('a column kept stays built, and so do the ones up to the band', () {
      // The one being typed in, scrolled out of view to the left.
      final span = SheetSpan.of(edges, offset: 320, viewport: 100, keep: const [0]);

      expect((span.first, span.last), (0, 4));
    });

    test('no columns, nothing to build', () {
      final span = SheetSpan.of(const [0.0], offset: 0, viewport: 100);
      expect(span.last, lessThan(span.first));
    });
  });

  group('a sheet of a million rows and sixty columns', () {
    late _Wide table;
    late SheetController controller;

    Future<void> mount(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      table = _Wide(count: 1000000, width: 60);

      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [S.delegate],
        home: Builder(builder: (context) {
          AppSize.instance(context);

          controller = SheetController(
            service: table,
            metrics: SheetMetrics(rowHeight: AppSize.action, gutterWidth: AppSize.action),
            widths: SheetWidths(defaultWidth: 100, minWidth: 40),
            context: () => context
          );

          return MultiProvider(
            providers: [
              ChangeNotifierProvider<BusinessService>.value(value: BusinessService()),
              ChangeNotifierProvider<CurrencyCatalogService>.value(value: CurrencyCatalogService()),
              Provider<SheetController>.value(value: controller),
              Provider<SheetWidths>.value(value: controller.widths),
              ChangeNotifierProvider<TableViewService>.value(value: table),
              ChangeNotifierProvider<SheetCursor>.value(value: controller.cursor),
              ChangeNotifierProvider<SheetColumns>.value(value: controller.columns),
              ChangeNotifierProvider<SheetDrafts>.value(value: controller.drafts),
              ChangeNotifierProvider<SheetHover>.value(value: controller.hover),
              ChangeNotifierProvider<SheetSelection>.value(value: controller.selection),
              ChangeNotifierProvider<SheetWindow>.value(value: controller.window),
              ChangeNotifierProvider<SheetDates>.value(value: controller.dates)
            ],
            child: const Material(child: Sheet())
          );
        })
      ));
      await tester.pumpAndSettle();
      addTearDown(controller.dispose);
    }

    /// The columns the first record's row built, by position.
    List<int> built(WidgetTester tester) => [
      for (final element in find.byType(SheetCellView).evaluate())
        if ((element.widget as SheetCellView).row == 0) (element.widget as SheetCellView).position
    ];

    testWidgets('a row builds the columns in view, not all sixty', (tester) async {
      await mount(tester);

      final columns = built(tester);
      expect(columns.first, 0);
      expect(columns.length, lessThan(20), reason: "about twelve fit, plus the margin");
      expect(
        find.byType(FieldCell).evaluate().length,
        columns.length,
        reason: "the fields row builds the same ones"
      );
    });

    testWidgets('scrolling sideways builds the ones that come in', (tester) async {
      await mount(tester);

      controller.horizontal.jumpTo(controller.horizontal.position.maxScrollExtent);
      await tester.pump();

      final columns = built(tester);
      expect(columns, isNot(contains(0)));
      expect(columns.last, 61, reason: "the two free columns close the sheet");
    });

    testWidgets('the cell being typed in stays built wherever the band goes', (tester) async {
      await mount(tester);

      controller.open(const SheetCell(0, 0));
      await tester.pump();

      controller.horizontal.jumpTo(controller.horizontal.position.maxScrollExtent);
      await tester.pump();

      expect(built(tester), contains(0));
      expect(controller.cursor.editing, isTrue, reason: "its editor was not unmounted");
    });

    testWidgets('the gutter is as wide as the last number needs', (tester) async {
      await mount(tester);

      final gutter = tester.widget<SheetGutter>(find.byType(SheetGutter));
      expect(gutter.width, greaterThan(AppSize.action));
      expect(tester.takeException(), isNull, reason: "row 1000006 is written whole");
    });

    testWidgets('a leap across the table reads only where it lands', (tester) async {
      await mount(tester);
      table.asked.clear();

      // The scrollbar dragged down: five leaps of thousands of rows, one per frame.
      for (var step = 1; step <= 5; step++) {
        controller.vBody.jumpTo(step * 400000.0);
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(table.asked, isEmpty, reason: "nothing is read on the way");

      await tester.pump(const Duration(milliseconds: 200));
      expect(table.asked, hasLength(1));
      expect(table.asked.single.$1, 2000000 ~/ AppSize.action);
    });

    testWidgets('scrolling a few rows reads at once', (tester) async {
      await mount(tester);
      table.asked.clear();

      controller.vBody.jumpTo(AppSize.action * 3);
      await tester.pump();

      expect(table.asked, isNotEmpty);
    });

    testWidgets('the mouse crossing rows repaints their bands, not their cells', (tester) async {
      await mount(tester);

      final cell = find.byType(SheetCellView).first;
      final before = tester.element(cell).widget;

      controller.hover.enter(0);
      await tester.pump();

      expect(identical(tester.element(cell).widget, before), isTrue);
    });
  });
}
