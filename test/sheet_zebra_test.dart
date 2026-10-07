import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/kit/app_size.dart';
import 'package:core/kit/theme_color.dart';

import 'package:app/screens/home/sections/inventory/table_view/sheet_style.dart';

import 'package:app/toolkit/theme/dark.dart';
import 'package:app/toolkit/theme/light.dart';
import 'package:app/screens/home/sections/inventory/table_view/sheet_row_fill.dart';

const double _kRowHeight = 32;

/// El estilo de la planilla tal como se lo arma [Sheet], resuelto contra el tema
/// [brightness].
Future<(SheetStyle, SchemeColor)> _style(
  WidgetTester tester, {
  Brightness brightness = Brightness.light
}) async {
  late SheetStyle style;
  late SchemeColor scheme;

  // El tema va aca abajo y no en `MaterialApp.theme`: ese pasa por un
  // `AnimatedTheme`, asi que en el primer frame despues del pump todavia es el
  // anterior y el caso oscuro correria sobre la paleta clara.
  await tester.pumpWidget(MaterialApp(
    home: Theme(
      data: ThemeData(brightness: brightness),
      child: Builder(builder: (context) {
        AppSize.instance(context);

        scheme = ThemeColor.of(context);
        style = SheetStyle(
          scheme: scheme,
          rowHeight: _kRowHeight,
          gutterWidth: 40
        );

        return const Scaffold(body: SizedBox());
      })
    )
  ));

  return (style, scheme);
}

void main() {
  setUpAll(() {
    ThemeColor.light = lightScheme;
    ThemeColor.dark = darkScheme;
  });

  testWidgets('las filas alternan las dos superficies del tema', (tester) async {
    final (style, scheme) = await _style(tester);

    expect(style.cell(row: 0, selected: false).color, scheme.table.background);
    expect(style.cell(row: 1, selected: false).color, scheme.table.even);
  });

  testWidgets('la banda no se corta nunca', (tester) async {
    // Los registros y las filas en blanco de abajo son una sola grilla: la
    // cebra alterna por posicion, asi que no hay un salto donde termina lo
    // cargado ni dos filas seguidas del mismo color en ningun lado.
    final (style, _) = await _style(tester);

    for (var row = 0; row < 12; row++) {
      expect(
        style.cell(row: row, selected: false).color,
        isNot(style.cell(row: row + 1, selected: false).color),
        reason: "las filas $row y ${row + 1} quedaron del mismo color"
      );
    }
  });

  testWidgets('el cursor cambia el borde, no la banda', (tester) async {
    // Pararse en una celda no la saca de su fila: lo que la resalta es el
    // marco, y el fondo sigue siendo el que le toca a su fila.
    final (style, _) = await _style(tester);

    for (final row in [0, 1]) {
      final idle = style.cell(row: row, selected: false);
      final active = style.cell(row: row, selected: true);

      expect(active.color, idle.color);
      expect(active.border, isNot(idle.border));
    }
  });

  testWidgets('el borde del cursor no le cambia la caja a la celda', (tester) async {
    // Un borde ocupa lugar. Si el del cursor apareciera recien al elegir la
    // celda, entrar en ella le comeria un pixel por lado al contenido y el texto
    // pegaria un salto justo cuando se lo va a escribir. Los cuatro lados estan
    // siempre; los dos que no son la cuadricula van transparentes.
    final (style, scheme) = await _style(tester);

    for (final row in [0, 1]) {
      final idle = style.cell(row: row, selected: false).border!;
      final active = style.cell(row: row, selected: true).border!;

      expect(idle.dimensions, active.dimensions);
      // Un pixel por lado: el marco del cursor senala, no engorda.
      expect(idle.dimensions, const EdgeInsets.all(1));
    }

    // Los dos lados que no dibuja la cuadricula no se ven, pero estan.
    final idle = style.cell(row: 0, selected: false).border as Border;

    expect(idle.top.color.a, 0);
    expect(idle.left.color.a, 0);
    expect(idle.right.color, scheme.table.lines);
    expect(idle.bottom.color, scheme.table.lines);
  });

  testWidgets('la fila bajo el mouse y la del cursor tienen su propio fondo', (tester) async {
    // Son las dos senales de donde esta uno en una tabla larga: por donde pasa
    // el puntero y donde se quedo parado. Cada una tiene su color del esquema, y
    // ninguna de las dos puede confundirse con la cebra.
    final (style, scheme) = await _style(tester);

    for (final row in [0, 1]) {
      final plain = style.cell(row: row, selected: false).color;
      final over = style
        .cell(row: row, selected: false, fill: SheetRowFill.over)
        .color;
      final selected = style
        .cell(row: row, selected: false, fill: SheetRowFill.selected)
        .color;

      expect(over, scheme.table.over);
      expect(selected, scheme.table.rowSelected);

      expect(over, isNot(plain));
      expect(selected, isNot(plain));
      expect(over, isNot(selected));
    }
  });

  testWidgets('la fila resaltada no depende de la cebra', (tester) async {
    // La cebra es de las filas que no tienen nada encima: una fila resaltada se
    // ve igual sea par o impar, porque lo que dice es otra cosa.
    final (style, _) = await _style(tester);

    for (final fill in [SheetRowFill.over, SheetRowFill.selected]) {
      expect(
        style.cell(row: 0, selected: false, fill: fill).color,
        style.cell(row: 1, selected: false, fill: fill).color
      );
    }
  });

  testWidgets('la banda de numeros se pinta como su fila', (tester) async {
    // El resaltado no se puede cortar en el numero: seria una fila pintada a
    // medias.
    final (style, scheme) = await _style(tester);

    expect(style.gutter().color, style.headerFill);
    expect(style.gutter(fill: SheetRowFill.over).color, scheme.table.over);
    expect(
      style.gutter(fill: SheetRowFill.selected).color,
      scheme.table.rowSelected
    );
  });

  testWidgets('el marco de un control se lleva la superficie que su fila no usa', (tester) async {
    // Es lo que lo hace visible en las dos bandas: con un color fijo
    // desapareceria en la mitad de la planilla.
    for (final brightness in [Brightness.light, Brightness.dark]) {
      final (style, scheme) = await _style(tester, brightness: brightness);

      // Que el tema del caso sea de verdad el que se esta mirando: sin esto la
      // vuelta oscura podria estar corriendo sobre la paleta clara y el caso no
      // probaria nada.
      expect(scheme.isDark, brightness == Brightness.dark);

      for (final row in [0, 1, 2, 3]) {
        expect(
          style.frameFill(row: row),
          isNot(style.cell(row: row, selected: false).color),
          reason: "el marco de la fila $row se pierde contra su fondo"
        );
      }
    }
  });
}
