import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/inventory/import_source.dart';
import 'package:app/screens/modals/inventory/import_table/_import_table.dart';

/// El modal de importar: la lista de origenes que se abre al tocar "Import
/// table" en el listado de tablas.
///
/// Lo que se prueba de el es lo unico que hace: mostrar todos los origenes
/// —tambien los que todavia no existen, que son la mayoria— y contestar con el
/// que se eligio sin importar nada por su cuenta.

/// La aplicacion minima para montar el modal: los textos y las medidas, que es
/// todo lo que usa.
///
/// [child] va dentro de un [Navigator] propio para poder leer con que valor se
/// cierra: eso es lo unico que el modal produce.
Widget _app({required Widget child, required void Function(dynamic) onPop}) =>
  MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: Builder(builder: (context) {
      AppSize.instance(context);

      return Scaffold(body: Builder(builder: (context) => Center(
        child: TextButton(
          onPressed: () => Navigator
            .push<dynamic>(context, MaterialPageRoute<dynamic>(
              builder: (_) => Scaffold(body: child)
            ))
            .then(onPop),
          child: const Text("open")
        )
      )));
    })
  );

void main() {
  // Los esquemas de color son `late final` del paquete: se cargan una sola vez
  // para todo el archivo o el segundo test explota al reasignarlos.
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });
  testWidgets('lista todos los origenes y marca los que faltan', (tester) async {
    await tester.pumpWidget(_app(
      child: const ImportTableModal(),
      onPop: (_) {}
    ));

    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    // El que funciona va primero y sin cartel.
    expect(find.text("Upload spreadsheet"), findsOneWidget);

    // Los que no, se muestran igual: son la promesa de por donde va a poder
    // entrar el inventario.
    for (final label in [
      "Google Sheets", "JSON", "XML", "OpenDocument", "Airtable",
      "Notion", "Smartsheet", "Trello", "Shopify", "WooCommerce", "Magento"
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }

    // Uno por cada origen que todavia no existe, que son todos menos la
    // planilla.
    expect(find.text("Soon"), findsNWidgets(11));
  });

  testWidgets('elegir la planilla cierra con ese origen', (tester) async {
    dynamic popped;

    await tester.pumpWidget(_app(
      child: const ImportTableModal(),
      onPop: (value) => popped = value
    ));

    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();

    await tester.tap(find.text("Upload spreadsheet"));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(popped, ImportSource.spreadsheet);
  });

  testWidgets('un origen que todavia no esta no hace nada', (tester) async {
    dynamic popped;
    var closed = false;

    await tester.pumpWidget(_app(
      child: const ImportTableModal(),
      onPop: (value) {
        closed = true;
        popped = value;
      }
    ));

    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();

    // Sin blanco de acierto: la fila apagada no tiene nada que responda al
    // toque, que es justamente lo que se esta probando.
    await tester.tap(find.text("Shopify"), warnIfMissed: false);
    await tester.pumpAndSettle();

    // El modal sigue abierto: no se eligio nada.
    expect(tester.takeException(), isNull);
    expect(closed, isFalse);
    expect(popped, isNull);
    expect(find.text("Upload spreadsheet"), findsOneWidget);
  });

  testWidgets('en escritorio se mide contra su contenido', (tester) async {
    // Como lo monta [showModal] en escritorio: una caja que mide lo que mide lo
    // que tiene adentro, sin alto que repartir. La lista se corta sola.
    await tester.pumpWidget(_app(
      child: const Center(child: SingleChildScrollView(
        child: IntrinsicWidth(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [ImportTableModal()]
        ))
      )),
      onPop: (_) {}
    ));

    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text("Upload spreadsheet"), findsOneWidget);
  });
  testWidgets('las siglas van al final de la lista', (tester) async {
    // El orden es la mitad de la pantalla: lo que cualquiera reconoce arriba y
    // las siglas abajo, para que la lista no se lea como algo tecnico.
    await tester.pumpWidget(_app(
      child: const ImportTableModal(),
      onPop: (_) {}
    ));

    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();

    double top(String label) => tester.getTopLeft(find.text(label)).dy;

    expect(top("Upload spreadsheet"), lessThan(top("Google Sheets")));
    expect(top("Google Sheets"), lessThan(top("Shopify")));
    expect(top("Shopify"), lessThan(top("Notion")));
    expect(top("Notion"), lessThan(top("JSON")));
    expect(top("JSON"), lessThan(top("XML")));
  });

  testWidgets('el buscador filtra por nombre', (tester) async {
    await tester.pumpWidget(_app(
      child: const ImportTableModal(),
      onPop: (_) {}
    ));

    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), "shop");
    await tester.pumpAndSettle();

    expect(find.text("Shopify"), findsOneWidget);
    expect(find.text("Notion"), findsNothing);

    // El titulo de un grupo sin nada adentro tampoco queda.
    expect(find.text("Other formats"), findsNothing);
  });

  testWidgets('el buscador tambien mira lo que el origen trae', (tester) async {
    // Quien tiene su inventario en un Excel escribe "excel", no "spreadsheet".
    await tester.pumpWidget(_app(
      child: const ImportTableModal(),
      onPop: (_) {}
    ));

    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), "Excel");
    await tester.pumpAndSettle();

    expect(find.text("Upload spreadsheet"), findsOneWidget);
    expect(find.text("Shopify"), findsNothing);
  });

  testWidgets('una busqueda sin resultados lo dice', (tester) async {
    await tester.pumpWidget(_app(
      child: const ImportTableModal(),
      onPop: (_) {}
    ));

    await tester.tap(find.text("open"));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), "zzz");
    await tester.pumpAndSettle();

    expect(find.text("No source matches your search"), findsOneWidget);
    expect(find.text("Upload spreadsheet"), findsNothing);

    // El buscador sigue ahi para corregir lo escrito.
    expect(find.byType(TextField), findsOneWidget);
  });
}
