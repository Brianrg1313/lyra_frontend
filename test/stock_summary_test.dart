import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/catalog/currency_model.dart';
import 'package:app/services/home/home_service.dart';
import 'package:app/services/inventory/table_field_type.dart';
import 'package:app/services/stock/summary/stock_summary_model.dart';
import 'package:app/services/stock/summary/stock_summary_service.dart';
import 'package:app/services/stock/movements/stock_movement_model.dart';
import 'package:app/services/stock/sources/stock_source.dart';
import 'package:app/screens/home/sections/inventory/table_list/inventory_bar.dart';
import 'package:app/screens/home/sections/inventory/table_list/stock_summary/_stock_summary.dart';
import 'package:app/screens/home/sections/inventory/table_list/stock_summary/summary_layout.dart';
import 'package:app/screens/home/sections/inventory/table_list/stock_summary/summary_value.dart';
import 'package:app/screens/home/sections/inventory/table_list/stock_summary/summary_header.dart';
import 'package:app/screens/home/sections/inventory/table_list/stock_summary/summary_line.dart';
import 'package:app/screens/home/sections/inventory/table_list/stock_summary/summary_product_row.dart';

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

  group('the order', () {
    const name = "11111111-1111-4111-8111-111111111111";
    const price = "22222222-2222-4222-8222-222222222222";

    test("the company's columns and a named stock order it; the rest don't", () {
      final columns = StockSummaryPage.fromResponse(_response()).columns;

      // image, name, price, stock ("Cantidad": a stock column behind it), reserved, performance.
      expect(columns.map((column) => column.sortable), [false, true, true, true, false, false]);

      // Without a stock column behind it the backend has nothing stored to order by.
      expect(const StockSummaryColumn(key: StockSummaryColumn.stockKey, fixed: true).sortable, isFalse);
    });

    test('a click orders down, the next one up, a third one drops the order', () {
      const down = StockSummarySort(price, descending: true);
      const up = StockSummarySort(price);

      expect(StockSummarySort.after(null, price), down);
      expect(StockSummarySort.after(down, price), up);
      expect(StockSummarySort.after(up, price), isNull);

      // Another column starts over, whichever step the last one was on.
      expect(StockSummarySort.after(up, name), const StockSummarySort(name, descending: true));
    });

    test('the order travels to the source and back to the first page', () async {
      final source = _Source(answer: _response());
      final service = StockSummaryService(source: source);
      addTearDown(service.dispose);

      await service.load();
      await service.sortBy(price);
      await service.sortBy(price);
      await service.sortBy(StockSummaryColumn.reservedKey);

      // The reserved count has nothing to order by: that click reads nothing.
      expect(source.sorts, [
        null,
        const StockSummarySort(price, descending: true),
        const StockSummarySort(price)
      ]);
      expect(service.sort, const StockSummarySort(price));

      // The third click reads the summary in the backend's own order again.
      await service.sortBy(price);

      expect(source.sorts.last, isNull);
      expect(service.sort, isNull);
      expect(service.status, StockSummaryStatus.ready);
    });

    test('a search keeps the order', () async {
      final source = _Source(answer: _response());
      final service = StockSummaryService(source: source);
      addTearDown(service.dispose);

      await service.load();
      await service.sortBy(name);
      await service.search("yerba");

      expect(source.sorts.last, const StockSummarySort(name, descending: true));
    });

    test('an order the backend refuses is dropped, not retried forever', () async {
      final source = _Source(answer: _response(), refuseSort: true);
      final service = StockSummaryService(source: source);
      addTearDown(service.dispose);

      await service.load();
      await service.sortBy(price);

      expect(source.sorts, [null, const StockSummarySort(price, descending: true), null]);
      expect(service.sort, isNull);
      expect(service.status, StockSummaryStatus.ready);
    });

    testWidgets('a title orders its column and the ordered one carries the arrow', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1400, 900);
      addTearDown(tester.view.reset);

      final page = StockSummaryPage.fromResponse(_response());
      final taps = <String>[];

      await tester.pumpWidget(_app((context) => SizedBox(
        height: SummaryLayout.headerTitles,
        child: SummaryHeader(
          layout: SummaryLayout.of(context, page.columns),
          sort: const StockSummarySort(price, descending: true),
          onSort: taps.add
        )
      )));

      await tester.tap(find.text("Nombre"));
      await tester.tap(find.text("Precio"));
      await tester.tap(find.text("Reserved"));

      expect(taps, [name, price]);
      expect(find.byIcon(CI.arrow_down), findsOneWidget);
      expect(find.byIcon(CI.arrow_top), findsNothing);
    });
  });

  group('the widths', () {
    testWidgets('a price and a code measure their values; the text takes the rest', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1400, 900);
      addTearDown(tester.view.reset);

      final response = _response();
      (response["columns"] as List).insert(3, {
        "key": "33333333-3333-4333-8333-333333333333",
        "name": "SKU",
        "type": "sku",
        "width": 300,
        "options": [],
        "fixed": false
      });

      final page = StockSummaryPage.fromResponse(response);

      await tester.pumpWidget(_app((context) => SummaryHeader(
        layout: SummaryLayout.of(context, page.columns)
      )));

      double widthOf(String title, Type box) => tester.getSize(find.ancestor(
        of: find.text(title),
        matching: find.byType(box)
      ).first).width;

      final priceWidth = widthOf("Precio", SizedBox);
      final skuWidth = widthOf("SKU", SizedBox);

      // The sheet's width no longer decides theirs: the code was dragged to 300 there.
      expect(priceWidth, SummaryLayout.widthOf(page.columns[2]));
      expect(skuWidth, SummaryLayout.widthOf(page.columns[3]));
      expect(priceWidth, lessThan(skuWidth));

      // And the name, the only text, is wider than both.
      expect(widthOf("Nombre", Expanded), greaterThan(skuWidth));
    });

    testWidgets("short columns that don't fit are left out, not overflowed", (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1400, 900);
      addTearDown(tester.view.reset);

      final response = _response();
      for (final (index, title) in ["SKU", "Barcode", "Phone"].indexed) {
        (response["columns"] as List).insert(3 + index, {
          "key": "3333333$index-3333-4333-8333-333333333333",
          "name": title,
          "type": "sku",
          "options": [],
          "fixed": false
        });
      }

      final page = StockSummaryPage.fromResponse(response);
      // Wide enough for the photo, the name, the price, a code and the three numbers; the
      // second code (the fourth column the desktop shows) doesn't fit.
      late SummaryLayout layout;

      await tester.pumpWidget(_app((context) {
        final all = SummaryLayout.of(context, page.columns);
        final width = SummaryLayout.imageSize + SummaryLayout.minFlexible
          + SummaryLayout.widthOf(page.columns[2])! + SummaryLayout.widthOf(page.columns[3])!
          + SummaryLayout.gap * 4 + SummaryLayout.numberWidth * 3 + SummaryLayout.gap * 2;

        expect(all.fields, hasLength(4));
        layout = SummaryLayout.of(context, page.columns, width: width);

        return Center(child: SizedBox(
          width: width + SummaryLayout.headerPadding.horizontal,
          child: SummaryHeader(layout: layout)
        ));
      }));

      expect(tester.takeException(), isNull);
      // The table's last column goes first; every number stays.
      expect(layout.fields.map((column) => column.name), ["Nombre", "Precio", "SKU"]);
      expect(layout.numbers, hasLength(3));
      expect(find.text("Barcode"), findsNothing);
    });

    testWidgets('a narrower list leaves out the last numbers, then the photo', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1400, 900);
      addTearDown(tester.view.reset);

      final page = StockSummaryPage.fromResponse(_response());
      final layouts = <SummaryLayout>[];

      await tester.pumpWidget(_app((context) {
        final image = SummaryLayout.imageSize + SummaryLayout.gap;

        layouts
          ..clear()
          ..add(SummaryLayout.of(context, page.columns, width: image + SummaryLayout.numberWidth * 2 + SummaryLayout.gap))
          ..add(SummaryLayout.of(context, page.columns, width: SummaryLayout.numberWidth));

        return const SizedBox();
      }));

      // No text fits: the table's columns go, then performance, and stock stays.
      expect(layouts[0].fields, isEmpty);
      expect(layouts[0].numbers.map((column) => column.key), [StockSummaryColumn.stockKey, StockSummaryColumn.reservedKey]);
      expect(layouts[0].image, isNotNull);

      expect(layouts[1].numbers.map((column) => column.key), [StockSummaryColumn.stockKey]);
      expect(layouts[1].image, isNull);
    });

    testWidgets('without a text column the numbers stay at the right end', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1400, 900);
      addTearDown(tester.view.reset);

      final response = _response();
      (response["columns"] as List).removeAt(1);
      final page = StockSummaryPage.fromResponse(response);

      await tester.pumpWidget(_app((context) => SummaryHeader(
        layout: SummaryLayout.of(context, page.columns)
      )));

      expect(tester.takeException(), isNull);

      final header = tester.getRect(find.byType(SummaryHeader));
      final last = tester.getRect(find.text("Performance"));
      expect(last.right, closeTo(header.right - SummaryLayout.headerPadding.right, 1));
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

    testWidgets('the titles fit in the height the header declares',
      (tester) async {
        final page = StockSummaryPage.fromResponse(_response());

        // What the view pins on top of the rows: the header and its line, inside
        // the height it declares. A header asking for more comes out clipped —or
        // squashed, which is the same with nothing warning—.
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

        // And fills it: the bottom line is the one pixel between it and the
        // first row.
        expect(
          tester.getSize(find.byType(SummaryHeader)).height,
          SummaryLayout.headerHeight - 1
        );

        // The picture column keeps its width though the header puts nothing in
        // it, which is what lands each title over its column; not its height,
        // which would stretch the header to a row's.
        expect(SummaryLayout.headerHeight, lessThan(SummaryLayout.rowHeight));
      }
    );

    testWidgets('the view reads the table it is given, under the section bar',
      (tester) async {
        final source = _Source();
        final home = HomeService();
        addTearDown(home.dispose);

        await tester.pumpWidget(_app((context) =>
          ChangeNotifierProvider<HomeService>.value(
            value: home,
            child: SizedBox(
              height: 600,
              child: StockSummarySection(
                tableId: "t-2",
                source: source,
                parts: const InventoryBarParts(selector: Text("Prices"), controls: [])
              )
            )
          )
        ));

        // The read is deferred to the first frame and its page never comes: the
        // wait is what is drawn.
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(source.tables, ["t-2"]);
        expect(find.text("Prices"), findsOneWidget);
        expect(find.byType(Loading), findsOneWidget);
      }
    );
  });
}

/// A summary source noting which table and order each read asked for. Its pages never
/// come unless it is given an [answer]; [refuseSort] refuses any ordered read the way the
/// cloud does.
class _Source implements StockSource {
  _Source({this.answer, this.refuseSort = false});

  final Map<String, dynamic>? answer;
  final bool refuseSort;

  final tables = <String>[];
  final sorts = <StockSummarySort?>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<StockSummaryPage> summary({
    required int page,
    required int size,
    String match = "",
    String tableId = "",
    StockSummarySort? sort
  }) async {
    tables.add(tableId);
    sorts.add(sort);

    if (sort != null && refuseSort) throw {"message": "invalid_search", "action": null};

    final answer = this.answer;
    if (answer == null) return Completer<StockSummaryPage>().future;

    return StockSummaryPage.fromResponse(answer);
  }

  @override
  Future<StockBalance> move(StockMovement movement, {required String tableId, required String productId}) =>
    Completer<StockBalance>().future;
}
