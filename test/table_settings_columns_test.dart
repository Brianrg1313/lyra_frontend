import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/inventory/table_field_type.dart';
import 'package:app/services/stock/tables/table_detail_model.dart';
import 'package:app/services/stock/tables/table_detail_service.dart';
import 'package:app/screens/home/sections/inventory/table_settings/columns_table.dart';
import 'package:app/screens/home/sections/inventory/table_settings/settings_block.dart';

/// La tabla de columnas sola, sin la pantalla: lo que se comprueba es como se
/// leen y como se cambian las columnas, no como se navega hasta ellas.
///
/// El servicio va provisto porque los desplegables lo buscan en el arbol al
/// guardar. Ninguna de estas pruebas llega a guardar —eso pegaria contra la
/// red—, pero sin el, abrir uno seria un error de arbol y no una eleccion.
Widget _app(List<TableDetailFieldModel> fields, {double? width}) =>
  ChangeNotifierProvider<TableDetailService>(
    create: (_) => TableDetailService(),
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

        return Scaffold(body: SingleChildScrollView(
          child: SizedBox(
            width: width,
            child: TableColumnsTable(fields: fields)
          )
        ));
      })
    )
  );

/// Tres columnas que cubren los tres casos de la fila: una sin descripcion, una
/// con descripcion y visibilidad movida, y una lista con opciones.
List<TableDetailFieldModel> get _fields => const [
  TableDetailFieldModel(id: "f1", name: "Nombre"),
  TableDetailFieldModel(
    id: "f2",
    name: "Precio",
    description: "Precio de venta con IVA",
    position: 1,
    type: TableFieldType.price,
    visibility: TableFieldVisibility.declared
  ),
  TableDetailFieldModel(
    id: "f3",
    name: "Color",
    position: 2,
    type: TableFieldType.select,
    options: ["Rojo", "Verde"],
    visibility: TableFieldVisibility.hidden
  )
];

void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  testWidgets('cada columna es una fila con su tipo y su visibilidad', (
    tester
  ) async {
    // Puestas en columna, "cuales estan sin tipar" y "cual es la que el bot no
    // deberia estar diciendo" se contestan de un vistazo.
    await tester.pumpWidget(_app(_fields));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    expect(find.text("Column"), findsOneWidget);
    expect(find.text("Type"), findsOneWidget);
    expect(find.text("Visibility"), findsOneWidget);
    expect(find.text("Options"), findsOneWidget);

    expect(find.text("Nombre"), findsOneWidget);
    expect(find.text("Precio"), findsOneWidget);
    expect(find.text("Color"), findsOneWidget);

    expect(find.text("Text"), findsOneWidget);
    expect(find.text("Price"), findsOneWidget);
    expect(find.text("Options list"), findsOneWidget);

    expect(find.text("Visible"), findsOneWidget);
    expect(find.text("Declared"), findsOneWidget);
    expect(find.text("Hidden"), findsOneWidget);
  });

  testWidgets('las opciones solo son un dato en las columnas de lista', (
    tester
  ) async {
    // En los demas tipos la celda queda con un guion y no con un desplegable
    // apagado: no es un dato vacio, es un dato que no existe para ese campo.
    await tester.pumpWidget(_app(_fields));
    await tester.pumpAndSettle();

    expect(find.text("2 options"), findsOneWidget);
    expect(find.text("—"), findsNWidgets(2));
  });

  testWidgets('una lista sin opciones lo dice en vez de quedar en blanco', (
    tester
  ) async {
    await tester.pumpWidget(_app(const [
      TableDetailFieldModel(id: "f1", name: "Color", type: TableFieldType.select)
    ]));
    await tester.pumpAndSettle();

    expect(find.text("No options yet"), findsOneWidget);
  });

  testWidgets('el tipo se cambia desde la propia fila', (tester) async {
    await tester.pumpWidget(_app(_fields));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(SettingsSelect, "Text"));
    await tester.pumpAndSettle();

    // La lista de tipos, con el buscador que la vuelve manejable: son
    // diecisiete y el desplegable muestra cuatro.
    expect(find.text("Smart text"), findsOneWidget);
    expect(find.text("Type of information"), findsOneWidget);
  });

  testWidgets('la visibilidad se elige con su explicacion al lado', (
    tester
  ) async {
    // Los tres estados se llaman parecido y el del medio no lo adivina nadie
    // leyendo "declarada".
    await tester.pumpWidget(_app(_fields));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(SettingsSelect, "Visible"));
    await tester.pumpAndSettle();

    expect(
      find.textContaining("filter by it, but never says what it holds"),
      findsOneWidget
    );
  });

  testWidgets('en angosto la fila se parte en vez de encoger las celdas', (
    tester
  ) async {
    // La ficha se abre en dos columnas apenas la pantalla da, y esa mitad no
    // tiene lugar para cinco celdas.
    await tester.pumpWidget(_app(_fields, width: 320));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    // Sin cabecera: partida no encabeza nada.
    expect(find.text("Column"), findsNothing);
    expect(find.text("Visibility"), findsNothing);

    // Los datos siguen todos.
    expect(find.text("Precio"), findsOneWidget);
    expect(find.text("Declared"), findsOneWidget);
    expect(find.text("2 options"), findsOneWidget);
  });
}
