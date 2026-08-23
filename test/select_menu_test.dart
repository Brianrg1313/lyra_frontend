import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';

import 'package:core/form.dart';
import 'package:core/kit/app_size.dart';
import 'package:core/kit/theme_color.dart';

import 'package:app/toolkit/theme/dark.dart';
import 'package:app/toolkit/theme/light.dart';

/// Una lista larga, del estilo de los tipos de campo: son tantos que sin tope de
/// alto el desplegable se comeria la pantalla.
final _options = [
  for (final name in const [
    "Texto", "Texto largo", "Numero", "Decimal", "Precio", "SKU",
    "Contador", "Si/No", "Fecha", "Fecha y hora", "Correo", "Telefono",
    "Enlace", "Lista", "Imagen", "Semantico", "Stock"
  ])
    SelectOption(
      value: name.toUpperCase(),
      placeholder: name,
      subtitle: "Que se guarda en $name"
    )
];

/// Abre el desplegable y devuelve la caja donde se deja lo elegido.
Future<List<SelectOption?>> _open(
  WidgetTester tester, {
  String? selected,
  bool dense = false
}) async {
  final picked = <SelectOption?>[];

  await tester.pumpWidget(MaterialApp(
    home: Builder(builder: (context) {
      AppSize.instance(context);

      return Scaffold(body: Align(
        alignment: Alignment.topLeft,
        child: Builder(builder: (context) => GestureDetector(
          onTap: () async => picked.add(await showSelectMenu(
            context: context,
            options: _options,
            selected: selected,
            searchPlaceholder: "Buscar",
            emptyText: "Sin resultados",
            maxOptions: 4,
            dense: dense
          )),
          child: const Text("abrir")
        ))
      ));
    })
  ));

  await tester.tap(find.text("abrir"));
  await tester.pumpAndSettle();

  return picked;
}

/// Abre un desplegable corto —el de las opciones de una columna de una
/// planilla— con la fila de agregar una opcion.
///
/// Devuelve la caja de lo elegido y la de lo que se pidio crear, para poder
/// mirar las dos cosas: que se creo y que quedo elegido.
Future<({List<SelectOption?> picked, List<String> created})> _openCreatable(
  WidgetTester tester, {
  required Future<SelectOption?> Function(String name) onCreate,
  List<SelectOption> options = const [],
  String? searchPlaceholder
}) async {
  final picked = <SelectOption?>[];
  final created = <String>[];

  await tester.pumpWidget(MaterialApp(
    home: Builder(builder: (context) {
      AppSize.instance(context);

      return Scaffold(body: Align(
        alignment: Alignment.topLeft,
        child: Builder(builder: (context) => GestureDetector(
          onTap: () async => picked.add(await showSelectMenu(
            context: context,
            options: options,
            searchPlaceholder: searchPlaceholder,
            emptyText: "Sin opciones",
            createText: "Nueva opcion",
            createPlaceholder: "Nombre de la opcion",
            onCreate: (name) {
              created.add(name);
              return onCreate(name);
            }
          )),
          child: const Text("abrir")
        ))
      ));
    })
  ));

  await tester.tap(find.text("abrir"));
  await tester.pumpAndSettle();

  return (picked: picked, created: created);
}

void main() {
  setUpAll(() {
    ThemeColor.light = lightScheme;
    ThemeColor.dark = darkScheme;
  });

  testWidgets('el desplegable no se estira mas alla del tope', (tester) async {
    await _open(tester);

    final list = tester.getSize(find.byType(ListView));
    final row = SelectOptionTile.heightOf(_options.first);

    // Cuatro opciones y no diecisiete: el resto se alcanza desplazando.
    expect(list.height, lessThanOrEqualTo(row * 4 + AppSize.gap * 2 + 1));
    expect(list.height, lessThan(tester.view.physicalSize.height));
  });

  testWidgets('cabe en la pantalla', (tester) async {
    await _open(tester);

    final menu = tester.getRect(find.byType(ListView));
    final screen = tester.getRect(find.byType(MaterialApp));

    expect(menu.top, greaterThanOrEqualTo(screen.top));
    expect(menu.bottom, lessThanOrEqualTo(screen.bottom));
  });

  testWidgets('se distingue del fondo', (tester) async {
    await _open(tester);

    final surface = tester.widget<Container>(find
      .ancestor(of: find.byType(ListView), matching: find.byType(Container))
      .first);

    final decoration = surface.decoration as BoxDecoration;

    // El borde del campo se confunde con el relleno sobre un modal: el del
    // desplegable es el de las separaciones, que se ve sobre cualquier fondo.
    expect((decoration.border as Border).top.color, ThemeColor.light.line);

    // Y una sombra corta, para que se lea como algo por encima.
    expect(decoration.boxShadow, isNotEmpty);
  });

  testWidgets('el buscador filtra las opciones', (tester) async {
    await _open(tester);

    // Con la lista entera, lo que no entra en el tope no esta construido.
    expect(find.text("Stock"), findsNothing);

    await tester.enterText(find.byType(TextField), "stock");
    await tester.pumpAndSettle();

    expect(find.text("Stock"), findsOneWidget);
    expect(find.text("Texto"), findsNothing);
  });

  testWidgets('el buscador ignora tildes y mayusculas', (tester) async {
    await _open(tester);

    await tester.enterText(find.byType(TextField), "TELÉFONO");
    await tester.pumpAndSettle();

    expect(find.text("Telefono"), findsOneWidget);
  });

  testWidgets('sin coincidencias se avisa', (tester) async {
    await _open(tester);

    await tester.enterText(find.byType(TextField), "zzz");
    await tester.pumpAndSettle();

    expect(find.text("Sin resultados"), findsOneWidget);
  });

  testWidgets('elegir una opcion la devuelve y cierra', (tester) async {
    final picked = await _open(tester);

    await tester.enterText(find.byType(TextField), "precio");
    await tester.pumpAndSettle();

    await tester.tap(find.text("Precio"));
    await tester.pumpAndSettle();

    expect(picked.single?.value, "PRECIO");
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('Enter elige la primera coincidencia', (tester) async {
    final picked = await _open(tester);

    await tester.enterText(find.byType(TextField), "fecha");
    await tester.pumpAndSettle();

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(picked.single?.value, "FECHA");
  });

  testWidgets('cerrar sin elegir no devuelve nada', (tester) async {
    final picked = await _open(tester);

    // Tocar fuera del desplegable lo cierra, como cualquier cosa flotante.
    await tester.tapAt(const Offset(400, 550));
    await tester.pumpAndSettle();

    expect(picked.single, isNull);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('la opcion puesta arranca marcada', (tester) async {
    await _open(tester, selected: "PRECIO");

    // La lista se abre en la opcion elegida, no en la primera.
    expect(find.text("Precio"), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('apretado, la misma lista ocupa bastante menos', (tester) async {
    // Colgando de la celda de una planilla —que mide una fila— la medida de un
    // campo de formulario convierte cuatro opciones en media pantalla.
    await _open(tester, dense: true);

    final dense = SelectOptionTile.heightOf(_options.first, dense: true);
    final normal = SelectOptionTile.heightOf(_options.first);

    expect(dense, lessThan(normal * 0.8));

    // Y lo que se dibuja son esas medidas, no las de siempre.
    final list = tester.getSize(find.byType(ListView));
    expect(list.height, lessThanOrEqualTo(dense * 4 + AppSize.gap * 2 + 1));
  });

  testWidgets('apretado no achica el desplegable de siempre', (tester) async {
    // El de un formulario sigue haciendo juego con el campo del que cuelga: lo
    // apretado es una opcion, no el modo nuevo de todos los desplegables.
    await _open(tester);

    final list = tester.getSize(find.byType(ListView));
    final row = SelectOptionTile.heightOf(_options.first);

    expect(list.height, greaterThan(row * 3));
  });

  testWidgets('sin quien la cree no hay fila de agregar', (tester) async {
    // El desplegable de siempre —el de los tipos de campo, el de un formulario—
    // ofrece elegir y nada mas.
    await _open(tester);

    expect(find.byIcon(Icons.add), findsNothing);
  });

  group('agregar una opcion', () {
    testWidgets('la fila esta aunque la lista este vacia', (tester) async {
      // Una columna de lista recien creada no tiene opciones: la primera se
      // escribe desde aca, que es lo que evita tener que definir la lista antes
      // de empezar a cargar.
      await _openCreatable(tester, onCreate: (_) async => null);

      expect(find.text("Sin opciones"), findsOneWidget);
      expect(find.text("Nueva opcion"), findsOneWidget);
    });

    testWidgets('tocarla abre el campo donde se escribe', (tester) async {
      // Sin buscador no hay ningun otro campo: el que aparece es el de la
      // opcion nueva.
      await _openCreatable(tester, onCreate: (_) async => null);

      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.text("Nueva opcion"));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('lo escrito se crea y queda elegido', (tester) async {
      // Crear una opcion es elegirla: se la escribio porque hace falta ahora.
      final boxes = await _openCreatable(
        tester,
        onCreate: (name) async =>
          SelectOption(value: name, placeholder: name)
      );

      await tester.tap(find.text("Nueva opcion"));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), "  Rojo  ");
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Llega recortado: lo que se manda a guardar es la opcion, no el espacio.
      expect(boxes.created, ["Rojo"]);
      expect(boxes.picked.single?.value, "Rojo");

      // Y el desplegable se cerro con ella.
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('una opcion en blanco no se manda', (tester) async {
      final boxes = await _openCreatable(tester, onCreate: (_) async => null);

      await tester.tap(find.text("Nueva opcion"));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), "   ");
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(boxes.created, isEmpty);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('si no se pudo crear, la fila sigue con lo escrito', (tester) async {
      // El error lo mostro quien la crea; aca lo que importa es no perder lo
      // que se escribio, para poder corregirlo y reintentar.
      final boxes = await _openCreatable(tester, onCreate: (_) async => null);

      await tester.tap(find.text("Nueva opcion"));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), "Rojo");
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(boxes.created, ["Rojo"]);
      expect(boxes.picked, isEmpty);

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller?.text, "Rojo");
    });

    testWidgets('Escape cancela lo escrito y no el desplegable', (tester) async {
      await _openCreatable(tester, onCreate: (_) async => null);

      await tester.tap(find.text("Nueva opcion"));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), "Rojo");
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Vuelve al boton, con el desplegable todavia abierto.
      expect(find.byType(TextField), findsNothing);
      expect(find.text("Nueva opcion"), findsOneWidget);
    });

    testWidgets('se puede elegir una de la lista sin crear nada', (tester) async {
      final boxes = await _openCreatable(
        tester,
        options: const [
          SelectOption(value: "Rojo", placeholder: "Rojo"),
          SelectOption(value: "Verde", placeholder: "Verde")
        ],
        onCreate: (_) async => null
      );

      await tester.tap(find.text("Verde"));
      await tester.pumpAndSettle();

      expect(boxes.created, isEmpty);
      expect(boxes.picked.single?.value, "Verde");
    });
  });
}
