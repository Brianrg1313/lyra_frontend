import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/kit/app_size.dart';
import 'package:core/kit/icons.dart';
import 'package:core/kit/theme_color.dart';
import 'package:core/widgets/buttons/feedback.dart';

import 'package:app/generated/l10n.dart';
import 'package:app/services/inventory/table_field_type.dart';
import 'package:app/screens/home/sections/inventory/table_view/cells/_cells.dart';
import 'package:app/screens/home/sections/inventory/table_view/sheet_style.dart';

import 'package:app/toolkit/theme/dark.dart';
import 'package:app/toolkit/theme/light.dart';

const double _kRowHeight = 32;
const double _kCellWidth = 160;

/// Monta una celda de SKU suelta, con el mismo estilo que le baja la
/// planilla.
Future<void> _cell(
  WidgetTester tester, {
  String value = "",
  bool editable = true,
  double width = _kCellWidth,
  VoidCallback? onGenerate
}) async {
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
            width: width,
            height: _kRowHeight,
            child: Container(
              alignment: Alignment.centerLeft,
              padding: style.cellPadding,
              decoration: style.cell(row: 0, selected: false),
              child: SheetCells.value(
                type: TableFieldType.sku,
                value: value,
                style: style.value,
                alignment: TableFieldType.sku.alignment,
                row: 0,
                column: 0,
                columnKey: "col_0",
                editable: editable,
                onGenerateSku: onGenerate
              )
            )
          )
        ))
      );
    })
  ));
}

void main() {
  setUpAll(() {
    ThemeColor.light = lightScheme;
    ThemeColor.dark = darkScheme;
  });

  testWidgets('el codigo se lee en gris y no con el color del dato', (tester) async {
    // Un SKU no es algo que se lea ni que se compare de un vistazo con el de la
    // fila de al lado: es la etiqueta con la que se encuentra el producto. En
    // negro es la columna que mas ruido hace de la planilla, porque son las
    // cadenas mas largas y las menos legibles.
    await _cell(tester, value: "ABC-123");

    final context = tester.element(find.byType(SkuCell));
    final scheme = ThemeColor.of(context);
    final style = SheetTheme.of(context);

    final text = tester.widget<Text>(
      find.descendant(of: find.byType(SkuCell), matching: find.byType(Text))
    );

    expect(text.style?.color, scheme.text.secondary);
    expect(text.style?.color, isNot(style.value.color));
    // Gris, pero no el gris de una celda apagada: el SKU se escribe como
    // cualquier otra.
    expect(text.style?.fontSize, style.value.fontSize);
  });

  testWidgets('una celda de SKU vacia y editable ofrece generarlo', (tester) async {
    var generated = 0;
    await _cell(tester, onGenerate: () => generated += 1);

    expect(find.byIcon(CI.ia), findsOneWidget);

    await tester.tap(find.byType(FeedbackButton));
    await tester.pump();

    expect(generated, 1);
  });

  testWidgets('el boton no gasta la columna en una etiqueta', (tester) async {
    // Una celda de planilla es angosta: lo que hace el boton lo cuentan su
    // icono y su globo, no un texto adentro de la columna.
    await _cell(tester, width: 400, onGenerate: () {});

    expect(find.text("Generate SKU"), findsNothing);

    final button = tester.getSize(find.byType(FeedbackButton));

    expect(button.width, lessThan(_kRowHeight));
    expect(button.width, button.height);
  });

  testWidgets('el boton va contra el borde derecho de la celda', (tester) async {
    await _cell(tester, width: 400, onGenerate: () {});

    final cell = tester.getRect(find.byType(SkuCell));
    final button = tester.getRect(find.byType(FeedbackButton));

    expect(cell.right - button.right, lessThan(1));
  });

  testWidgets('el boton desaparece en cuanto la celda tiene un SKU cargado', (tester) async {
    await _cell(tester, value: "AB12CD34EF56", onGenerate: () {});

    expect(find.text("AB12CD34EF56"), findsOneWidget);
    expect(find.byType(FeedbackButton), findsNothing);
  });

  testWidgets('una celda que no se escribe no ofrece generar nada', (tester) async {
    // Un campo que lleva el backend o un registro que todavia no llego no
    // manda [onGenerateSku]: sin el la celda no tiene donde guardar lo que se
    // generara.
    await _cell(tester, editable: false);

    expect(find.byType(FeedbackButton), findsNothing);
  });

  testWidgets('en una columna angosta el boton sigue entrando', (tester) async {
    await _cell(tester, width: 60, onGenerate: () {});

    expect(tester.takeException(), isNull);
    expect(find.byIcon(CI.ia), findsOneWidget);
  });
}
