import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/kit/app_size.dart';
import 'package:core/kit/icons.dart';
import 'package:core/kit/theme_color.dart';

import 'package:app/services/inventory/table_field_type.dart';
import 'package:app/screens/home/sections/inventory/table_view/cells/_cells.dart';
import 'package:app/screens/home/sections/inventory/table_view/sheet_style.dart';

import 'package:app/toolkit/theme/dark.dart';
import 'package:app/toolkit/theme/light.dart';

/// Alto de una fila de la planilla. Es chico a proposito: es contra esto que se
/// mide si el marco de la celda deja aire y sigue entrando.
const double _kRowHeight = 32;
const double _kCellWidth = 160;

/// Grosor de la linea de la cuadricula que la celda dibuja a su derecha y abajo.
const double _kLine = 1;

/// La celda que se mide, para no confundirla con los [SizedBox] que trae armado
/// el andamiaje de la pantalla.
const Key _kCell = Key("celda");

/// Monta una celda suelta, con el mismo estilo que le baja la planilla.
Future<SheetStyle> _cell(
  WidgetTester tester, {
  required TableFieldType type,
  String value = "Rojo",
  dynamic raw,
  int row = 0
}) async {
  late SheetStyle style;

  await tester.pumpWidget(MaterialApp(
    home: Builder(builder: (context) {
      AppSize.instance(context);

      style = SheetStyle(
        scheme: ThemeColor.of(context),
        rowHeight: _kRowHeight,
        gutterWidth: 40
      );

      return SheetTheme(
        style: style,
        child: Scaffold(body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            key: _kCell,
            width: _kCellWidth,
            height: _kRowHeight,
            child: Container(
              alignment: Alignment.centerLeft,
              padding: type.picker ? style.framePadding : style.cellPadding,
              decoration: style.cell(row: row, selected: false),
              child: SheetCells.value(
                type: type,
                value: value,
                style: style.value,
                alignment: type.alignment,
                raw: raw,
                row: row,
                column: 0,
                columnKey: "col_0"
              )
            )
          )
        ))
      );
    })
  ));

  return style;
}

/// El marco que la celda de lista dibuja adentro: el [Surface] que la llena.
BoxDecoration _frame(WidgetTester tester) => tester
  .widget<Container>(find
    .descendant(of: find.byType(ListedCell), matching: find.byType(Container))
    .first)
  .decoration as BoxDecoration;

void main() {
  setUpAll(() {
    ThemeColor.light = lightScheme;
    ThemeColor.dark = darkScheme;
  });

  testWidgets('la celda de lista se ve como un boton de desplegable', (tester) async {
    final style = await _cell(tester, type: TableFieldType.options);

    expect(find.text("Rojo"), findsOneWidget);
    // La flecha esta siempre y no solo en la celda elegida: es lo que dice que
    // esa columna se elige, y eso hay que saberlo antes de tocarla.
    expect(find.byIcon(CI.arrow_down), findsOneWidget);

    expect(_frame(tester).color, style.frameFill(row: 0));
  });

  testWidgets('el marco se despega del fondo de su fila', (tester) async {
    // Con la cebra la planilla usa sus dos superficies fila por medio, asi que
    // un color fijo desapareceria en la mitad de la tabla: sobre una fila par
    // en el tema claro, un marco blanco no existe.
    final style = await _cell(tester, type: TableFieldType.options);
    final onEven = _frame(tester).color;

    await _cell(tester, type: TableFieldType.options, row: 1);
    final onOdd = _frame(tester).color;

    expect(onEven, isNot(onOdd));

    final cellOnEven = style.cell(row: 0, selected: false).color;
    final cellOnOdd = style.cell(row: 1, selected: false).color;

    expect(onEven, isNot(cellOnEven));
    expect(onOdd, isNot(cellOnOdd));
  });

  testWidgets('el marco esta tambien en una celda vacia', (tester) async {
    // Es justo donde mas hace falta saber que ahi se elige: no hay ni un valor
    // que lo insinue.
    final style = await _cell(tester, type: TableFieldType.options, value: "");

    expect(find.byIcon(CI.arrow_down), findsOneWidget);
    expect(_frame(tester).color, style.frameFill(row: 0));
  });

  testWidgets('el marco queda despegado de los bordes de la celda', (tester) async {
    final style = await _cell(tester, type: TableFieldType.options);

    final cell = tester.getRect(find.byKey(_kCell));
    final frame = tester.getRect(find.byType(ListedCell));

    final inset = style.framePadding.top;

    // Aire por los cuatro lados, y **el mismo** por los cuatro: un marco apoyado
    // contra la cuadricula se confunde con ella. Es el aire mas el borde, que la
    // celda tiene por los cuatro lados aunque solo se vean dos (los otros dos
    // van transparentes, para que elegir la celda no le cambie la caja).
    for (final gap in [
      frame.left - cell.left,
      frame.top - cell.top,
      cell.right - frame.right,
      cell.bottom - frame.bottom
    ]) {
      expect(gap, closeTo(inset + _kLine, 0.5));
    }

    // Y ocupa todo lo demas: la caja es la celda, no una etiqueta pegada al
    // texto.
    expect(frame.width, closeTo(_kCellWidth - (inset + _kLine) * 2, 0.5));
    expect(frame.height, closeTo(_kRowHeight - (inset + _kLine) * 2, 0.5));
  });

  testWidgets('la celda de varias etiquetas las escribe en una linea', (tester) async {
    // Se guarda como lista, asi que su texto no es el `toString()` de lo que
    // vino (`[Zapatos, Deportivos]`, con los corchetes de Dart) sino sus
    // etiquetas, que es lo que alguien puso.
    await _cell(
      tester,
      type: TableFieldType.categories,
      value: "",
      raw: const ["Zapatos", "Deportivos"]
    );

    expect(find.text("Zapatos, Deportivos"), findsOneWidget);
    expect(find.byIcon(CI.arrow_down), findsOneWidget);
  });

  testWidgets('las celdas que no se eligen no llevan marco', (tester) async {
    // Un texto es un dato y se ve como un dato: la caja es lo que distingue a
    // la celda que abre algo.
    await _cell(tester, type: TableFieldType.text);

    expect(find.text("Rojo"), findsOneWidget);
    expect(find.byIcon(CI.arrow_down), findsNothing);
    expect(find.byType(ListedCell), findsNothing);
  });
}
