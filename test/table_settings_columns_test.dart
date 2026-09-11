import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/inventory/table_field_type.dart';
import 'package:app/services/stock/tables/table_detail_model.dart';
import 'package:app/services/stock/tables/table_detail_service.dart';
import 'package:app/screens/modals/inventory/table_settings/columns_table.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

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
    type: TableFieldType.options,
    options: ["Rojo", "Verde"],
    visibility: TableFieldVisibility.hidden,
    summary: false
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

    // Cada columna lleva sus tres etiquetas: son lo unico que dice que se esta
    // eligiendo, y a veinte columnas de distancia una cabecera unica arriba de
    // todo ya quedo fuera de la vista.
    expect(find.text("Type"), findsNWidgets(3));
    expect(find.text("Visibility"), findsNWidgets(3));
    expect(find.text("Inventory summary"), findsNWidgets(3));

    // La tercera celda cambia de pregunta segun el tipo: una lista tiene
    // opciones y un precio tiene unidad, y ningun tipo tiene las dos.
    expect(find.text("Options"), findsNWidgets(2));
    expect(find.text("Unit"), findsOneWidget);

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

  testWidgets('el resumen del inventario es una casilla por columna', (
    tester
  ) async {
    // Es la otra pregunta de la fila: la visibilidad dice cuanto ve la IA y
    // esta, que se le muestra a una persona de un vistazo. El "Color" esta
    // escondido para el agente y ademas afuera del resumen; las otras dos,
    // adentro.
    await tester.pumpWidget(_app(_fields));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(SettingsToggle, "Shown"), findsNWidgets(2));
    expect(find.widgetWithText(SettingsToggle, "Excluded"), findsOneWidget);
  });

  testWidgets('la casilla del resumen no se pinta sola: la pinta lo guardado', (
    tester
  ) async {
    // Tocarla dispara la escritura, y la columna cambia recien cuando el
    // backend la acepta. Sin red no entra nada, asi que la casilla tiene que
    // quedar donde estaba: prenderla igual diria que la columna esta en el
    // resumen cuando no lo esta.
    await tester.pumpWidget(_app(_fields));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(SettingsToggle, "Excluded"));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(SettingsToggle, "Excluded"), findsOneWidget);
    expect(find.widgetWithText(SettingsToggle, "Shown"), findsNWidgets(2));
  });

  testWidgets('las opciones solo son un dato en las columnas de lista', (
    tester
  ) async {
    // En los tipos que no eligen de una lista ni llevan unidad, la celda queda
    // con un guion y no con un desplegable apagado: no es un dato vacio, es un
    // dato que no existe para ese campo.
    await tester.pumpWidget(_app(_fields));
    await tester.pumpAndSettle();

    expect(find.text("2 options"), findsOneWidget);
    // El precio lleva unidad, asi que ahi hay un control y no un guion: el del
    // texto es el unico que se queda sin ninguna de las dos.
    expect(find.text("No unit"), findsOneWidget);
    expect(find.text("—"), findsOneWidget);
  });

  testWidgets('la unidad solo es un dato donde el numero no trae simbolo', (
    tester
  ) async {
    // Es la misma celda de las opciones y la misma regla: un porcentaje no
    // lleva unidad porque ahi la unidad **es** el tipo, asi que se queda con el
    // guion de los demas.
    await tester.pumpWidget(_app(const [
      TableDetailFieldModel(
        id: "f1",
        name: "Costo",
        type: TableFieldType.currency,
        unit: "USD"
      ),
      TableDetailFieldModel(
        id: "f2",
        name: "Descuento",
        type: TableFieldType.percentage
      )
    ]));
    await tester.pumpAndSettle();

    expect(find.text("Unit"), findsOneWidget);
    expect(find.text("USD"), findsOneWidget);
    expect(find.text("Options"), findsOneWidget);
    expect(find.text("—"), findsOneWidget);
  });

  testWidgets('una lista sin opciones lo dice en vez de quedar en blanco', (
    tester
  ) async {
    await tester.pumpWidget(_app(const [
      TableDetailFieldModel(id: "f1", name: "Color", type: TableFieldType.options)
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
    // veintitres y el desplegable muestra cuatro.
    // El desplegable se abre con el tipo que la columna ya tiene arriba de
    // todo, asi que lo que se ve es lo que hay a partir de ahi: los dos
    // semanticos lo encabezan y "Descripcion" es el que queda a la vista.
    expect(find.text("Description"), findsOneWidget);
    expect(find.text("Type of information"), findsOneWidget);
  });

  testWidgets('la unidad se escribe en el propio desplegable', (tester) async {
    // No hay una lista de unidades que ofrecer —son el codigo de una moneda o
    // una magnitud cualquiera— asi que lo que se ofrece es escribirla, en la
    // misma fila de crear con la que se agrega una opcion. Con una puesta,
    // ademas, la fila de sacarsela: es lo que devuelve la columna a la moneda de
    // la empresa.
    await tester.pumpWidget(_app(const [
      TableDetailFieldModel(
        id: "f1",
        name: "Costo",
        type: TableFieldType.currency,
        unit: "USD"
      )
    ]));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(SettingsSelect, "USD"));
    await tester.pumpAndSettle();

    expect(find.text("Set unit"), findsOneWidget);
    expect(find.text("Without unit"), findsOneWidget);
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

  testWidgets('en un ancho intermedio los controles van de a dos', (
    tester
  ) async {
    // La ficha partida en dos columnas, o metida en un panel: ahi no entran los
    // cuatro en un renglon, y uno por renglon dejaba cuatro botones del ancho
    // entero de la tarjeta con una palabra adentro.
    await tester.pumpWidget(_app(_fields, width: 500));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    double y(String label) => tester.getTopLeft(find.text(label).first).dy;
    double x(String label) => tester.getTopLeft(find.text(label).first).dx;

    // Renglon de arriba: el tipo y la visibilidad, uno al lado del otro.
    expect(y("Visibility"), y("Type"));
    expect(x("Visibility"), greaterThan(x("Type")));

    // Renglon de abajo: las opciones y el resumen.
    expect(y("Inventory summary"), y("Options"));
    expect(y("Options"), greaterThan(y("Type")));
    expect(x("Inventory summary"), greaterThan(x("Options")));

    // Y las dos celdas de abajo arrancan donde las dos de arriba: es lo que
    // hace que se lea como una grilla y no como cuatro botones sueltos.
    expect(x("Options"), x("Type"));
    expect(x("Inventory summary"), x("Visibility"));
  });

  testWidgets('en angosto los controles se apilan en vez de encogerse', (
    tester
  ) async {
    // Antes que cortar "Fecha y hora" o "3 opciones" en una celda de cien
    // pixeles, se los deja enteros uno debajo del otro y se baja.
    await tester.pumpWidget(_app(_fields, width: 240));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    // Ni siquiera dos por renglon: cada uno se lleva el ancho entero.
    expect(
      tester.getTopLeft(find.text("Visibility").first).dy,
      greaterThan(tester.getTopLeft(find.text("Type").first).dy)
    );

    // Los datos siguen todos, y cada uno sigue diciendo que es.
    expect(find.text("Precio"), findsOneWidget);
    expect(find.text("Declared"), findsOneWidget);
    expect(find.text("2 options"), findsOneWidget);
    expect(find.text("Visibility"), findsNWidgets(3));
    expect(find.text("Inventory summary"), findsNWidgets(3));
  });
}
