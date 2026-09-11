import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/stock/tables/table_detail_model.dart';
import 'package:app/screens/modals/inventory/table_settings/summary_block.dart';

/// El bloque solo, sin la pantalla: lo que se comprueba es como se lee la
/// cabecera de una tabla, no como se navega hasta ella.
Widget _app(TableDetailModel detail) => MaterialApp(
  localizationsDelegates: const [
    S.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate
  ],
  supportedLocales: S.delegate.supportedLocales,
  home: Builder(builder: (context) {
    AppSize.instance(context);

    return Scaffold(body: SingleChildScrollView(
      child: TableSummaryBlock(detail: detail)
    ));
  })
);

const _id = "8f2c1a90-3d7b-4e21";

/// El identificador tapado: el primer bloque a la vista y los guiones puestos,
/// que es lo que lo deja seguir leyendose como un uuid.
const _masked = "8f2c1a90-••••-••••";

TableDetailModel _detail({String description = "Catalogo de la bodega"}) =>
  TableDetailModel(
    id: _id,
    name: "Vinos",
    description: description,
    records: 1287,
    columns: const TableColumnsSummary(total: 4)
  );

void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  testWidgets('el titulo de la tabla se lee y se puede corregir', (tester) async {
    // Hasta ahora la tabla solo se nombraba en la barra de arriba, que es
    // donde se lee y no donde se corrige.
    await tester.pumpWidget(_app(_detail()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text("Title"), findsOneWidget);
    expect(find.text("Vinos"), findsOneWidget);
    expect(find.byIcon(CI.edit), findsNWidgets(2));
  });

  testWidgets('sobre un dato vacio el boton agrega, no corrige', (tester) async {
    // El lapiz sobre una fila en blanco miente: no hay nada que corregir.
    await tester.pumpWidget(_app(_detail(description: "")));
    await tester.pumpAndSettle();

    expect(find.text("No description"), findsOneWidget);
    expect(find.byIcon(CI.plus), findsOneWidget);
    expect(find.byIcon(CI.edit), findsOneWidget);
  });

  testWidgets('el identificador se muestra tapado', (tester) async {
    await tester.pumpWidget(_app(_detail()));
    await tester.pumpAndSettle();

    expect(find.text(_masked), findsOneWidget);
    expect(find.text(_id), findsNothing);
    expect(find.byIcon(CI.eye), findsOneWidget);
    expect(find.byIcon(CI.copy), findsOneWidget);
  });

  testWidgets('el identificador se destapa a pedido', (tester) async {
    await tester.pumpWidget(_app(_detail()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(CI.eye));
    await tester.pumpAndSettle();

    expect(find.text(_id), findsOneWidget);
    expect(find.text(_masked), findsNothing);
    // Destapado, el boton ofrece lo contrario.
    expect(find.byIcon(CI.eye_hidden), findsOneWidget);
  });
}
