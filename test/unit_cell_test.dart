import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// PACKAGES
import 'package:provider/provider.dart';

import 'package:core/kit/app_size.dart';
import 'package:core/kit/theme_color.dart';

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

/// El bloque `currencies` de `/init`, recortado a lo que hace falta aca.
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

/// Monta una celda suelta con el mismo estilo que le baja la planilla.
///
/// La empresa no declara moneda: asi lo unico que puede poner un simbolo en una
/// celda de dinero es la unidad de la columna, que es lo que se mide.
Future<void> _cell(
  WidgetTester tester, {
  required TableFieldType type,
  required String value,
  String unit = ""
}) async {
  await tester.pumpWidget(ChangeNotifierProvider<BusinessService>(
    create: (_) => BusinessService(),
    child: ChangeNotifierProvider<CurrencyCatalogService>.value(
      value: CurrencyCatalogService(),
      child: MaterialApp(
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
                  columnKey: "col_0"
                )
              )
            ))
          );
        })
      )
    )
  ));

  await tester.pump();
}

/// Lo que se lee en la celda, juntando los dos pesos con los que se pinta: el
/// numero con el color del dato y el simbolo en gris.
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

  group('el dinero se escribe con la moneda de su columna', () {
    testWidgets('un precio con moneda propia lleva ese simbolo', (tester) async {
      await _cell(
        tester,
        type: TableFieldType.price,
        value: "22.23",
        unit: "USD"
      );

      expect(_read(tester), r"$22.23");
    });

    testWidgets('un importe que no es el precio se escribe igual', (
      tester
    ) async {
      // `currency` es cualquier otro dinero —un costo, un mayorista— y se lee
      // como un precio: lo que los separa es quien puede decirlo en voz alta,
      // que es asunto del agente y no de la planilla.
      await _cell(
        tester,
        type: TableFieldType.currency,
        value: "22.23",
        unit: "EUR"
      );

      expect(_read(tester), "22,23 €");
    });

    testWidgets('una moneda que el catalogo no tiene se escribe con su codigo', (
      tester
    ) async {
      // Ponerle otro simbolo seria mentir sobre el dato.
      await _cell(
        tester,
        type: TableFieldType.price,
        value: "1500",
        unit: "COP"
      );

      expect(_read(tester), contains("COP"));
    });

    testWidgets('lo que no es un importe se muestra tal como se guardo', (
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

  group('la medida y el porcentaje llevan su simbolo detras', () {
    testWidgets('una medida lleva la magnitud de su columna, despegada', (
      tester
    ) async {
      await _cell(
        tester,
        type: TableFieldType.measure,
        value: "1.5",
        unit: "kg"
      );

      expect(_read(tester), "1.5 kg");
    });

    testWidgets('un porcentaje lleva su signo puesto y pegado', (tester) async {
      // Ahi la unidad **es** el tipo, asi que la columna no declara ninguna.
      await _cell(tester, type: TableFieldType.percentage, value: "16");

      expect(_read(tester), "16%");
    });

    testWidgets('una medida sin magnitud es el numero pelado', (tester) async {
      await _cell(tester, type: TableFieldType.measure, value: "1.5");

      expect(find.text("1.5"), findsOneWidget);
    });

    testWidgets('lo que no es un numero no lleva simbolo', (tester) async {
      // Ponerle `kg` detras seria afirmar que ahi hay un peso.
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
