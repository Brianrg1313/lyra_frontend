import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/catalog/currency_model.dart';
import 'package:app/services/inventory/table_field_type.dart';
import 'package:app/services/stock/summary/stock_summary_model.dart';
import 'package:app/services/stock/summary/stock_summary_service.dart';
import 'package:app/screens/home/sections/inventory/table_list/stock_summary/_stock_summary.dart';
import 'package:app/screens/home/sections/inventory/table_list/stock_summary/summary_layout.dart';
import 'package:app/screens/home/sections/inventory/table_list/stock_summary/summary_row.dart';
import 'package:app/screens/home/sections/inventory/table_list/stock_summary/summary_value.dart';

/// Una respuesta de `POST /inventory/stock/summary/` como la arma el backend:
/// las columnas por separado y las filas comprimidas en `{keys, values}`, con el
/// id del registro en la primera clave.
Map<String, dynamic> _response({
  int total = 2,
  List<List<dynamic>>? values
}) => {
  "table": "550e8400-e29b-41d4-a716-446655440000",
  "total": total,
  "page": 1,
  "size": 30,
  "columns": [
    {
      "key": "image",
      "name": "Foto",
      "type": "image",
      "width": null,
      "options": [],
      "fixed": true
    },
    {
      "key": "11111111-1111-4111-8111-111111111111",
      "name": "Nombre",
      "type": "text",
      "width": 240,
      "options": [],
      "fixed": false
    },
    {
      "key": "22222222-2222-4222-8222-222222222222",
      "name": "Precio",
      "type": "price",
      "width": 120,
      "options": [],
      "fixed": false
    },
    {
      "key": "stock",
      "name": "Cantidad",
      "type": "stock",
      "width": 90,
      "options": [],
      "fixed": true
    },
    {
      "key": "reserved",
      "name": null,
      "type": "counter",
      "width": null,
      "options": [],
      "fixed": true
    },
    {
      "key": "performance",
      "name": null,
      "type": "performance",
      "width": null,
      "options": [],
      "fixed": true
    }
  ],
  "data": {
    "keys": [
      "id",
      "image",
      "11111111-1111-4111-8111-111111111111",
      "22222222-2222-4222-8222-222222222222",
      "stock",
      "reserved",
      "performance"
    ],
    "values": values ?? [
      [
        "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
        {
          "id": "ffffffff-ffff-4fff-8fff-ffffffffffff",
          "scope": "media",
          "url": "/rigel/media/ffffffff-ffff-4fff-8fff-ffffffffffff"
        },
        "Yerba 1kg",
        "1500",
        12,
        3,
        null
      ],
      [
        "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb",
        null,
        "Mate de calabaza",
        "8200",
        0,
        0,
        null
      ]
    ]
  }
};

const CurrencyModel _currency = CurrencyModel(
  code: "ARS",
  name: "Peso",
  symbol: "\$"
);

Widget _app(Widget Function(BuildContext context) body) => MaterialApp(
  localizationsDelegates: const [
    S.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate
  ],
  supportedLocales: S.delegate.supportedLocales,
  home: Builder(builder: (context) {
    AppSize.instance(context);

    return Scaffold(body: body(context));
  })
);

void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  group('la pagina del resumen', () {
    test('lee las columnas fijas y las de la empresa', () {
      final page = StockSummaryPage.fromResponse(_response());

      expect(page.table, "550e8400-e29b-41d4-a716-446655440000");
      expect(page.total, 2);
      expect(page.columns.length, 6);

      // La foto abre la fila y los tres numeros la cierran: es el contrato de
      // esta vista y lo que hace que dos tablas distintas se comparen.
      expect(page.columns.first.isImage, isTrue);
      expect(page.columns[3].isStock, isTrue);
      expect(page.columns[4].isReserved, isTrue);
      expect(page.columns.last.isPerformance, isTrue);

      // Una columna fija sin nada detras llega sin nombre: lo pone la app.
      expect(page.columns[3].name, "Cantidad");
      expect(page.columns[4].name, "");

      expect(page.columns[2].type, TableFieldType.price);
      expect(page.columns[1].width, 240);
    });

    test('el id del registro no entra en los valores de la fila', () {
      final rows = StockSummaryPage.fromResponse(_response()).rows;

      expect(rows.length, 2);
      expect(rows.first.id, "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa");
      expect(rows.first.values.containsKey("id"), isFalse);
      expect(rows.first["11111111-1111-4111-8111-111111111111"], "Yerba 1kg");
    });

    test('la portada sale de la foto ya resuelta', () {
      final rows = StockSummaryPage.fromResponse(_response()).rows;

      // La columna `image` no trae lo guardado en la celda sino el archivo ya
      // resuelto, asi que se lee su id y no el objeto entero.
      expect(rows.first.cover?.id, "ffffffff-ffff-4fff-8fff-ffffffffffff");
      expect(rows.last.cover, isNull);
    });

    test('cero y nulo no son la misma respuesta', () {
      final rows = StockSummaryPage.fromResponse(_response()).rows;

      // Cero es "no queda nada"; nulo, "nadie lo esta contando".
      expect(rows.first.stock, 12);
      expect(rows.last.stock, 0);
      expect(rows.first[StockSummaryColumn.performanceKey], isNull);
    });

    test('una respuesta sin columnas no es un resumen vacio', () {
      expect(StockSummaryPage.fromResponse(null).isEmpty, isTrue);
      expect(StockSummaryPage.fromResponse(_response()).isEmpty, isFalse);
    });
  });

  group('el listado', () {
    testWidgets('el encabezado y las filas se reparten igual', (tester) async {
      // A lo ancho de un monitor entran las tres columnas de numeros; en un
      // telefono se muestra solo el stock, que es lo unico que una fila de ese
      // ancho puede decir sin cortarse (ver [SummaryLayout]).
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1400, 900);
      addTearDown(tester.view.reset);

      final page = StockSummaryPage.fromResponse(_response());

      await tester.pumpWidget(_app((context) {
        final layout = SummaryLayout.of(context, page.columns);

        return CustomScrollView(slivers: [
          SliverToBoxAdapter(child: SummaryHeader(layout: layout)),
          SliverList.builder(
            itemCount: page.rows.length,
            itemBuilder: (context, index) => SummaryProductRow(
              row: page.rows[index],
              layout: layout,
              currency: _currency
            )
          )
        ]);
      }));

      await tester.pump();

      expect(tester.takeException(), isNull);

      // Las dos cosas se dibujan con el mismo esqueleto: si no, cada titulo
      // quedaria sobre la columna equivocada.
      expect(find.byType(SummaryLine), findsNWidgets(3));

      // El nombre de la columna de stock es el que le puso la empresa; el de lo
      // reservado, que no tiene ninguna columna detras, lo escribe la app.
      expect(find.text("Cantidad"), findsOneWidget);
      expect(find.text("Reserved"), findsOneWidget);

      expect(find.text("Yerba 1kg"), findsOneWidget);
      expect(find.text("12"), findsOneWidget);
    });

    testWidgets('el texto inteligente va con el color de la marca',
      (tester) async {
        late SchemeColor scheme;

        await tester.pumpWidget(_app((context) {
          scheme = ThemeColor.of(context);

          return const Column(children: [
            SummaryValue(
              column: StockSummaryColumn(
                key: "33333333-3333-4333-8333-333333333333",
                name: "Resumen",
                type: TableFieldType.description
              ),
              raw: "Yerba organica de 1kg",
              currency: _currency
            ),
            SummaryValue(
              column: StockSummaryColumn(
                key: "11111111-1111-4111-8111-111111111111",
                name: "Nombre",
                type: TableFieldType.text
              ),
              raw: "Yerba 1kg",
              currency: _currency
            )
          ]);
        }));

        await tester.pump();

        Color? colorOf(String text) =>
          tester.widget<Text>(find.text(text)).style?.color;

        // Lo que no escribio nadie —salio de leer el producto— se distingue por
        // el color, y no por otro tratamiento: sigue siendo texto de la fila.
        expect(colorOf("Yerba organica de 1kg"), scheme.primary);

        // Y una columna cargada a mano sigue con el color de siempre: si el
        // color no fuera solo del texto inteligente, no estaria diciendo nada.
        expect(colorOf("Yerba 1kg"), isNot(scheme.primary));
      }
    );

    testWidgets('las filas alternan las dos bandas de la cebra', (tester) async {
      final page = StockSummaryPage.fromResponse(_response());
      late SchemeColor scheme;

      await tester.pumpWidget(_app((context) {
        scheme = ThemeColor.of(context);
        final layout = SummaryLayout.of(context, page.columns);

        // Como las arma el panel: la banda la decide la posicion en el listado.
        return Column(children: [
          for (var index = 0; index < 4; index++)
            SummaryProductRow(
              row: page.rows[index % page.rows.length],
              layout: layout,
              currency: _currency,
              zebra: index.isOdd
            )
        ]);
      }));

      await tester.pump();

      // La banda es la caja de la fila, que es la primera de cada una: mas
      // adentro estan las de los botones de los contadores, que van sobre su
      // propio color y no sobre el de la cebra.
      final colors = [
        for (var index = 0; index < 4; index++)
          tester
            .widgetList<Container>(find.descendant(
              of: find.byType(SummaryProductRow).at(index),
              matching: find.byType(Container)
            ))
            .first
            .color
      ];

      // Los dos colores son los que el esquema tiene para esto, y son los mismos
      // que usa la planilla: el resumen y la tabla de un producto se ven igual.
      expect(colors, [
        scheme.table.background,
        scheme.table.even,
        scheme.table.background,
        scheme.table.even
      ]);

      // Y son distintos entre si, que es lo unico que hace que la cebra sirva.
      expect(scheme.table.even, isNot(scheme.table.background));
    });

    testWidgets('los titulos entran en el alto que el encabezado declara',
      (tester) async {
        final page = StockSummaryPage.fromResponse(_response());

        // Lo que arma el panel para clavarlo arriba: el encabezado y la linea,
        // adentro del alto que declara. El sliver lo aprieta contra ese numero,
        // asi que un encabezado que pida mas sale recortado —o aplastado, que
        // es lo mismo pero sin que nada avise—.
        await tester.pumpWidget(_app((context) => SizedBox(
          height: SummaryLayout.headerHeight,
          child: Column(children: [
            Expanded(child: SummaryHeader(
              layout: SummaryLayout.of(context, page.columns)
            )),
            Separator.horizontal()
          ])
        )));

        await tester.pump();

        expect(tester.takeException(), isNull);

        // Y lo ocupa entero: la linea de abajo es el uno que lo separa de la
        // primera fila.
        expect(
          tester.getSize(find.byType(SummaryHeader)).height,
          SummaryLayout.headerHeight - 1
        );

        // La columna de la foto guarda su ancho aunque el encabezado no ponga
        // nada en ella: es lo que hace que cada titulo caiga sobre su columna.
        // Lo que no guarda es su alto, que estiraria el encabezado al de una
        // fila.
        expect(SummaryLayout.headerHeight, lessThan(SummaryLayout.rowHeight));
      }
    );

    testWidgets('el panel entra en el scroll de la seccion', (tester) async {
      final service = StockSummaryService();
      addTearDown(service.dispose);

      await tester.pumpWidget(_app((context) =>
        ChangeNotifierProvider<StockSummaryService>.value(
          value: service,
          child: const CustomScrollView(slivers: [StockSummarySection()])
        )
      ));

      await tester.pump();

      // Es una tira de slivers y no un widget con su propio scroll: lo que se
      // prueba aca es que se pueda meter en el mismo desplazamiento que la
      // grilla de tablas sin que el viewport lo rechace.
      expect(tester.takeException(), isNull);
      expect(find.text("Stock summary"), findsOneWidget);
      expect(find.byType(Loading), findsOneWidget);
    });
  });
}
