import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/stock/tables/table_lite_model.dart';
import 'package:app/services/stock/tables/tables_service.dart';
import 'package:app/screens/home/sections/inventory/table_list/primary_mark.dart';
import 'package:app/screens/home/sections/inventory/table_list/table_card.dart';
import 'package:app/screens/home/sections/inventory/table_list/table_row.dart';

/// Una tabla del listado como la manda el backend, con lo peor de cada caso: un
/// titulo que no entra y una descripcion larga son lo normal en una planilla
/// importada, y son lo que puede desbordar una tarjeta de alto fijo.
TableLiteModel _table({bool primary = false}) => TableLiteModel(
  id: "550e8400-e29b-41d4-a716-446655440000",
  title: "Precios mayoristas de temporada 2026",
  description:
    "Todo lo que se vende por caja cerrada, con el precio que le queda a "
    "cada cliente segun cuanto lleve y desde cuando compra.",
  fields: 12,
  records: 340,
  primary: primary
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

    return Scaffold(body: ChangeNotifierProvider<TablesService>(
      create: (_) => TablesService(),
      child: body(context)
    ));
  })
);

/// Una tarjeta en una celda de la grilla: el ancho que le toque y el alto que la
/// grilla le impone (`mainAxisExtent`), que es donde una tarjeta que pide de
/// mas desborda.
Widget _cell(TableLiteModel table, {double? width}) => Align(
  alignment: Alignment.topLeft,
  child: SizedBox(
    width: width ?? TableCard.maxWidth,
    height: TableCard.height,
    child: TableCard(table: table)
  )
);

void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  group('la tabla del listado', () {
    test('lee la marca de principal como la mande el backend', () {
      bool read(dynamic raw) =>
        TableLiteModel.fromJson({"id": "x", "title": "T", "primary": raw})
          .primary;

      // Booleano, numero o texto: MySQL manda una bandera de las tres formas.
      expect(read(true), isTrue);
      expect(read(1), isTrue);
      expect(read("1"), isTrue);
      expect(read("true"), isTrue);

      expect(read(false), isFalse);
      expect(read(0), isFalse);
      expect(read("0"), isFalse);
    });

    test('sin el dato no hay tabla principal', () {
      // Al reves que otras banderas: lo que no vino se lee como que no. La
      // principal es una sola y marcar de mas seria peor que no marcar nada.
      expect(TableLiteModel.fromJson({"id": "x", "title": "T"}).primary, isFalse);
      expect(
        TableLiteModel.fromJson({"id": "x", "title": "T", "primary": null})
          .primary,
        isFalse
      );

      // Y en mayusculas, que es como viaja el contrato del alta.
      expect(
        TableLiteModel.fromJson({"id": "x", "TITLE": "T", "PRIMARY": 1}).primary,
        isTrue
      );
    });

    test('renombrarla no le saca la marca', () {
      // El listado corrige la fila sin volver a pedirla, asi que la copia tiene
      // que llevarse todo lo que no se edito.
      final renamed = _table(primary: true).withText(title: "Otro nombre");

      expect(renamed.title, "Otro nombre");
      expect(renamed.primary, isTrue);
    });
  });

  group('la tarjeta de la grilla', () {
    testWidgets('entra en el alto que la grilla le da', (tester) async {
      await tester.pumpWidget(_app((_) => _cell(_table(primary: true))));
      await tester.pump();

      // Un renglon de mas en una tarjeta de alto fijo no se ve como un renglon
      // de mas: se ve como la raya amarilla del desborde.
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(TableCard)).height,
        TableCard.height
      );
    });

    testWidgets('tambien en las columnas que reparte la grilla de verdad',
      (tester) async {
        // No es un ancho inventado: la grilla parte lo que hay en tantas
        // columnas como entren sin pasar de [TableCard.maxWidth], asi que la
        // tarjeta casi nunca mide ese techo. Se prueba con la misma reparticion
        // que dibuja el listado ([TableCard.grid]) en los anchos donde la
        // grilla existe: desde el tablet (500) hasta un monitor.
        // Los anchos incomodos son los que caen apenas pasado un multiplo del
        // techo (570, 850): ahi la grilla suma una columna mas y todas quedan
        // en lo mas angosto que pueden quedar.
        for (final width in const [
          500.0, 570.0, 760.0, 850.0, 1280.0, 1920.0
        ]) {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(_app((_) => CustomScrollView(slivers: [
            SliverGrid.builder(
              itemCount: 6,
              gridDelegate: TableCard.grid,
              itemBuilder: (context, index) =>
                TableCard(table: _table(primary: index == 0))
            )
          ])));

          await tester.pump();

          expect(tester.takeException(), isNull, reason: "en $width");
        }
      }
    );

    testWidgets('una tabla sin descripcion no desborda ni se estira',
      (tester) async {
        await tester.pumpWidget(_app((_) => _cell(const TableLiteModel(
          id: "x",
          title: "Productos",
          fields: 3
        ))));

        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byType(TableCard)).height,
          TableCard.height
        );
      }
    );

    testWidgets('la marca es solo de la principal', (tester) async {
      await tester.pumpWidget(_app((_) => Column(children: [
        _cell(_table(primary: true)),
        _cell(_table())
      ])));

      await tester.pump();

      expect(find.byType(PrimaryTableMark), findsOneWidget);
      expect(find.text("Primary"), findsOneWidget);
    });
  });

  group('la fila del telefono', () {
    testWidgets('lleva la misma marca', (tester) async {
      await tester.pumpWidget(_app((_) => Column(children: [
        TableListRow(table: _table(primary: true)),
        TableListRow(table: _table())
      ])));

      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(PrimaryTableMark), findsOneWidget);
    });
  });
}
