import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

// PACKAGES
import 'package:provider/provider.dart';

import 'package:core/kit/app_size.dart';
import 'package:core/kit/theme_color.dart';
import 'package:core/widgets/buttons/feedback.dart';

import 'package:app/generated/l10n.dart';
import 'package:app/services/inventory/table_field_type.dart';
import 'package:app/screens/home/sections/inventory/table_view/cells/_cells.dart';
import 'package:app/screens/home/sections/inventory/table_view/sheet_style.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_dates.dart';

import 'package:app/toolkit/theme/dark.dart';
import 'package:app/toolkit/theme/light.dart';

const double _kRowHeight = 32;
const double _kCellWidth = 200;

/// Monta una columna de celdas de fecha, con el mismo estilo y el mismo estado
/// de formato que les baja la planilla.
///
/// Son varias y no una porque el formato es de la columna: hace falta mas de una
/// fila para poder comprobarlo.
Future<void> _column(
  WidgetTester tester, {
  required List<String> values,
  String columnKey = "field_1",
  TableFieldType type = TableFieldType.date
}) async {
  await tester.pumpWidget(ChangeNotifierProvider<SheetDates>(
    create: (_) => SheetDates(),
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
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                for (final (row, value) in values.indexed) SizedBox(
                  width: _kCellWidth,
                  height: _kRowHeight,
                  child: Container(
                    alignment: Alignment.centerLeft,
                    padding: style.cellPadding,
                    decoration: style.cell(row: row, selected: false),
                    child: SheetCells.value(
                      type: type,
                      value: value,
                      style: style.value,
                      alignment: type.alignment,
                      row: row,
                      column: 0,
                      columnKey: columnKey
                    )
                  )
                )
              ])
            )
          ))
        );
      })
    )
  ));
}

void main() {
  setUpAll(() {
    ThemeColor.light = lightScheme;
    ThemeColor.dark = darkScheme;
  });

  testWidgets('la fecha se lee escrita y no en cifras', (tester) async {
    // Guardada es `2026-02-12`, que es como se compara y como viaja. Leerla asi
    // obliga a descifrar el mes numero por numero.
    await _column(tester, values: ["2026-02-12"]);

    expect(find.text("Feb 12, 2026"), findsOneWidget);
    expect(find.text("2026-02-12"), findsNothing);
  });

  testWidgets('se lee igual escrita de cualquier manera', (tester) async {
    // Una tabla importada trae las fechas como venian en el archivo. La celda
    // las entiende igual, sin esperar a que alguien las corrija.
    await _column(tester, values: ["12/02/26"]);

    expect(find.text("Feb 12, 2026"), findsOneWidget);
  });

  testWidgets('el boton la pasa a la fecha completa', (tester) async {
    await _column(tester, values: ["2026-02-12 12:30"]);

    await tester.tap(find.byType(FeedbackButton));
    await tester.pump();

    expect(find.text("Feb 12, 2026"), findsNothing);
    expect(find.textContaining("2026-02-12 12:30"), findsOneWidget);
  });

  testWidgets('y vuelve a la escrita', (tester) async {
    await _column(tester, values: ["2026-02-12 12:30"]);

    await tester.tap(find.byType(FeedbackButton));
    await tester.pump();
    await tester.tap(find.byType(FeedbackButton));
    await tester.pump();

    expect(find.text("Feb 12, 2026"), findsOneWidget);
  });

  testWidgets('el formato es de la columna y no de la fila', (tester) async {
    // Una columna de fechas se lee como una tira: con cada fila en un formato
    // distinto, dos fechas de la misma columna dejarian de compararse de un
    // vistazo.
    await _column(tester, values: ["2026-02-12", "2026-03-01", "2026-04-20"]);

    await tester.tap(find.byType(FeedbackButton).first);
    await tester.pump();

    expect(find.text("2026-02-12"), findsOneWidget);
    expect(find.text("2026-03-01"), findsOneWidget);
    expect(find.text("2026-04-20"), findsOneWidget);
  });

  testWidgets('la fecha completa no inventa una hora', (tester) async {
    // No es lo mismo no tener hora que tenerla en cero: un vencimiento no vence
    // a las doce de la noche.
    await _column(tester, values: ["2026-02-12"]);

    await tester.tap(find.byType(FeedbackButton));
    await tester.pump();

    expect(find.text("2026-02-12"), findsOneWidget);
  });

  testWidgets('lo que no es una fecha se muestra tal como se cargo', (tester) async {
    // Y sin boton: no hay nada que convertir. Es lo que hace que una tabla
    // recien importada no pierda ni un dato por no haberse entendido.
    await _column(tester, values: ["consultar"]);

    expect(find.text("consultar"), findsOneWidget);
    expect(find.byType(FeedbackButton), findsNothing);
  });

  testWidgets('una celda vacia no ofrece convertir nada', (tester) async {
    await _column(tester, values: [""]);

    expect(find.byType(FeedbackButton), findsNothing);
  });

  testWidgets('una columna de fecha y hora se comporta igual', (tester) async {
    // Los dos tipos se escriben y se leen igual: lo unico que los separa es si
    // el dato trae hora, y eso ya lo dice el dato.
    await _column(
      tester,
      values: ["2026-02-12 12:30"],
      type: TableFieldType.datetime
    );

    expect(find.text("Feb 12, 2026"), findsOneWidget);
  });

  testWidgets('el boton no gasta la columna en una etiqueta', (tester) async {
    // Una celda de planilla es angosta: lo que hace el boton lo cuentan su icono
    // y su globo, no un texto adentro de la columna.
    await _column(tester, values: ["2026-02-12"]);

    expect(find.text("Full date"), findsNothing);

    final button = tester.getSize(find.byType(FeedbackButton));

    expect(button.width, lessThan(_kRowHeight));
    expect(button.width, button.height);
  });

  testWidgets('el boton va contra el borde derecho de la celda', (tester) async {
    await _column(tester, values: ["2026-02-12"]);

    final cell = tester.getRect(find.byType(DateCell));
    final button = tester.getRect(find.byType(FeedbackButton));

    expect(cell.right - button.right, lessThan(1));
  });

  testWidgets('en una columna angosta la fecha sigue entrando', (tester) async {
    await _column(tester, values: ["2026-02-12 12:30"]);

    await tester.tap(find.byType(FeedbackButton));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
