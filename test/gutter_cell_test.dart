import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:provider/provider.dart';

import 'package:core/kit/app_size.dart';
import 'package:core/kit/icons.dart';
import 'package:core/kit/theme_color.dart';
import 'package:core/widgets/buttons/feedback.dart';

import 'package:app/screens/home/sections/inventory/table_view/sheet_style.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_cursor.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_drafts.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_hover.dart';
import 'package:app/services/stock/tables/table_view_service.dart';

import 'package:app/toolkit/theme/dark.dart';
import 'package:app/toolkit/theme/light.dart';
import 'package:app/screens/home/sections/inventory/table_view/gutter_cell.dart';
import 'package:app/screens/home/sections/inventory/table_view/sheet_theme.dart';

const double _kRowHeight = 32;
const double _kGutterWidth = 40;

/// Monta la celda de la banda de numeros de la primera fila en blanco.
///
/// Una tabla recien creada no tiene registros, asi que la fila 0 del cuerpo es
/// ya una de las que se escriben y su borrador es `drafts.at(0)`.
Future<void> _gutter(WidgetTester tester, SheetDrafts drafts) =>
  tester.pumpWidget(MaterialApp(
    home: Builder(builder: (context) {
      AppSize.instance(context);

      return MultiProvider(
        providers: [
          ChangeNotifierProvider<TableViewService>(
            create: (_) => TableViewService()
          ),
          ChangeNotifierProvider<SheetDrafts>.value(value: drafts),
          ChangeNotifierProvider<SheetCursor>(create: (_) => SheetCursor()),
          ChangeNotifierProvider<SheetHover>(create: (_) => SheetHover())
        ],
        child: SheetTheme(
          style: SheetStyle(
            scheme: ThemeColor.of(context),
            rowHeight: _kRowHeight,
            gutterWidth: _kGutterWidth
          ),
          child: const Scaffold(body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: _kGutterWidth,
              height: _kRowHeight,
              child: GutterCell(index: 0)
            )
          ))
        )
      );
    })
  ));

void main() {
  setUpAll(() {
    ThemeColor.light = lightScheme;
    ThemeColor.dark = darkScheme;
  });

  testWidgets('una fila en blanco muestra su numero', (tester) async {
    // La fila de los campos es la 1, asi que el primer registro es la 2.
    await _gutter(tester, SheetDrafts());

    expect(find.text("2"), findsOneWidget);
  });

  testWidgets('una fila escrita no ofrece ningun boton', (tester) async {
    // Es el cambio: escribir ya no pone un tilde que haya que tocar. La fila se
    // guarda sola al salir de ella, asi que la banda sigue mostrando el numero.
    final drafts = SheetDrafts();
    drafts.write(0, 0, "Yerba");

    await _gutter(tester, drafts);

    expect(find.text("2"), findsOneWidget);
    expect(find.byType(FeedbackButton), findsNothing);
    expect(find.byIcon(CI.check), findsNothing);
  });

  testWidgets('la fila que se esta guardando muestra el spinner', (tester) async {
    // Lo unico que la banda tiene que decir del alta: que va en camino.
    final drafts = SheetDrafts();
    drafts.write(0, 0, "Yerba");
    drafts.setSaving(drafts.at(0)!, true);

    await _gutter(tester, drafts);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text("2"), findsNothing);
    expect(find.byType(FeedbackButton), findsNothing);
  });

  testWidgets('cuando el alta termina vuelve el numero', (tester) async {
    final drafts = SheetDrafts();
    drafts.write(0, 0, "Yerba");
    final draft = drafts.at(0)!;
    drafts.setSaving(draft, true);

    await _gutter(tester, drafts);

    drafts.setSaving(draft, false);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text("2"), findsOneWidget);
  });
}
