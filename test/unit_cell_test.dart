import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

// PACKAGES
import 'package:provider/provider.dart';

import 'package:core/kit/app_size.dart';
import 'package:core/kit/theme_color.dart';

import 'package:app/generated/l10n.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/services/catalog/currency_catalog_service.dart';
import 'package:app/services/inventory/table_field_type.dart';
import 'package:app/screens/home/sections/inventory/table_view/cells/_cells.dart';
import 'package:app/screens/home/sections/inventory/table_view/sheet_style.dart';

import 'package:app/toolkit/theme/dark.dart';
import 'package:app/toolkit/theme/light.dart';
import 'package:app/screens/home/sections/inventory/table_view/sheet_theme.dart';

const double _kRowHeight = 32;
const double _kCellWidth = 200;

/// The `/init` `currencies` block, trimmed to what is needed here.
Map<String, dynamic> _catalog() => {
  "keys": [
    "code", "name", "symbol", "position", "locale", "space", "decimals", "type"
  ],
  "values": [
    ["EUR", "Euro", "€", "right", "de-DE", true, 2, "fiat"],
    ["USD", "US Dollar", r"$", "left", "en-US", false, 2, "fiat"],
    ["VES", "Bolivar", "Bs.", "right", "es-VE", true, 2, "fiat"]
  ]
};

/// Mounts a lone cell with the same style the sheet hands down.
///
/// The company declares no currency: so the only thing that can put a symbol in a
/// money cell is the column's unit, which is what is measured.
Future<void> _cell(
  WidgetTester tester, {
  required TableFieldType type,
  required String value,
  String unit = "",
  ValueChanged<BuildContext>? onPickUnit
}) async {
  await tester.pumpWidget(ChangeNotifierProvider<BusinessService>(
    create: (_) => BusinessService(),
    child: ChangeNotifierProvider<CurrencyCatalogService>.value(
      value: CurrencyCatalogService(),
      child: MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: Builder(builder: (context) {
          AppSize.instance(context);

          final style = SheetStyle(
            scheme: ThemeColor.of(context),
            rowHeight: _kRowHeight,
            gutterWidth: 40
          );

          return SheetTheme(
            style: style,
            child: Scaffold(body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: _kCellWidth,
                height: _kRowHeight,
                child: SheetCells.value(
                  type: type,
                  value: value,
                  style: style.value,
                  alignment: type.alignment,
                  unit: unit,
                  row: 0,
                  column: 0,
                  columnKey: "col_0",
                  onPickUnit: onPickUnit
                )
              )
            ))
          );
        })
      )
    )
  ));

  await tester.pumpAndSettle();
}

/// What the cell reads, joining the two weights it is painted in: the number in
/// the datum's color and the symbol in gray.
String _read(WidgetTester tester) =>
  tester.widget<Text>(find.byType(Text).first).textSpan?.toPlainText() ??
  tester.widget<Text>(find.byType(Text).first).data ??
  "";

void main() {
  setUpAll(() {
    ThemeColor.light = lightScheme;
    ThemeColor.dark = darkScheme;
  });

  setUp(() => CurrencyCatalogService().seed(_catalog()));
  tearDown(() => CurrencyCatalogService().clear());

  group("money is written with its column's currency", () {
    testWidgets('a price with its own currency carries that symbol', (tester) async {
      await _cell(
        tester,
        type: TableFieldType.price,
        value: "22.23",
        unit: "USD"
      );

      expect(_read(tester), r"$22.23");
    });

    testWidgets('an amount that is not the price is written the same', (
      tester
    ) async {
      // `currency` is any other money —a cost, a wholesale price— and reads
      // like a price: what separates them is who may say it out loud, which is
      // the agent's business and not the sheet's.
      await _cell(
        tester,
        type: TableFieldType.currency,
        value: "22.23",
        unit: "EUR"
      );

      expect(_read(tester), "22,23 €");
    });

    testWidgets('a currency the catalog lacks is written with its code', (
      tester
    ) async {
      // Any other symbol would lie about the datum.
      await _cell(
        tester,
        type: TableFieldType.price,
        value: "1500",
        unit: "COP"
      );

      expect(_read(tester), contains("COP"));
    });

    testWidgets('what is not an amount shows as it was saved', (
      tester
    ) async {
      await _cell(
        tester,
        type: TableFieldType.price,
        value: "consultar",
        unit: "USD"
      );

      expect(find.text("consultar"), findsOneWidget);
    });
  });

  group('a measure and a percentage carry their symbol behind', () {
    testWidgets("a measure carries its column's unit, attached", (
      tester
    ) async {
      await _cell(
        tester,
        type: TableFieldType.measure,
        value: "1.5",
        unit: "kg"
      );

      expect(_read(tester), "1.5kg");
    });

    testWidgets('a percentage carries its sign, attached', (tester) async {
      // There the unit **is** the type, so the column declares none.
      await _cell(tester, type: TableFieldType.percentage, value: "16");

      expect(_read(tester), "16%");
    });

    testWidgets('a measure without a unit counts units', (tester) async {
      await _cell(tester, type: TableFieldType.measure, value: "5");

      expect(_read(tester), "5u");
    });

    testWidgets('a stock says what it counts: units, or its unit', (tester) async {
      // A bare «30» leaves open whether it is 30 tomatoes or 30 grams of tomato.
      await _cell(tester, type: TableFieldType.stock, value: "30");
      expect(_read(tester), "30u");

      await _cell(tester, type: TableFieldType.stock, value: "2.5", unit: "kg");
      expect(_read(tester), "2.5kg");
    });

    testWidgets("a stock's ruler opens its column's units", (tester) async {
      var opened = 0;
      await _cell(tester, type: TableFieldType.stock, value: "30", onPickUnit: (_) => opened++);

      await tester.tap(find.byIcon(Icons.straighten));
      expect(opened, 1);
    });

    testWidgets('what is not a number carries no symbol', (tester) async {
      // A `kg` behind it would claim there is a weight there.
      await _cell(
        tester,
        type: TableFieldType.measure,
        value: "a pedido",
        unit: "kg"
      );

      expect(find.text("a pedido"), findsOneWidget);
    });
  });
}
