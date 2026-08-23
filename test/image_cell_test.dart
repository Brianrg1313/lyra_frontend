import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// PACKAGES
import 'package:provider/provider.dart';

import 'package:core/kit/app_size.dart';
import 'package:core/kit/icons.dart';
import 'package:core/kit/theme_color.dart';

import 'package:app/services/files/cdn_service.dart';
import 'package:app/services/inventory/product_image.dart';
import 'package:app/services/inventory/table_field_type.dart';
import 'package:app/services/stock/tables/table_structure_model.dart';
import 'package:app/services/stock/tables/table_view_service.dart';

import 'package:app/screens/home/sections/inventory/table_view/cells/_cells.dart';
import 'package:app/screens/home/sections/inventory/table_view/sheet_style.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_controller.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_metrics.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_widths.dart';

import 'package:app/toolkit/theme/dark.dart';
import 'package:app/toolkit/theme/light.dart';

const double _kRowHeight = 32;

/// Una columna bien ancha: es contra esto que se mide que la foto **no** se
/// estira con ella.
const double _kCellWidth = 240;

/// Grosor de la linea de la cuadricula que la celda dibuja a su derecha y abajo.
const double _kLine = 1;

const Key _kCell = Key("celda");

/// Dos ids de archivo con forma de uuid, que es lo que la celda reconoce como
/// una foto nuestra.
const String _kCover = "11111111-2222-3333-4444-555555555555";
const String _kSecond = "66666666-7777-8888-9999-000000000000";

/// Una tabla que no sale a la red. La celda no le pregunta nada —lo suyo se lo
/// dan hecho— pero el controlador que la acompana necesita una.
class _FakeTable extends TableViewService {
  @override
  List<TableFieldModel> get fields => const [
    TableFieldModel(id: "f-image", name: "Imagen", type: "IMAGE")
  ];

  @override
  int get records => 1;
}

/// Monta una celda de imagen suelta, con el mismo estilo y el mismo aire que le
/// baja la planilla.
Future<SheetStyle> _cell(
  WidgetTester tester, {
  required dynamic raw,
  TableFieldType type = TableFieldType.image,
  int row = 0
}) async {
  late SheetStyle style;

  await tester.pumpWidget(MaterialApp(
    home: Builder(builder: (context) {
      AppSize.instance(context);

      style = SheetStyle(
        scheme: ThemeColor.of(context),
        rowHeight: _kRowHeight,
        gutterWidth: 40
      );

      final controller = SheetController(
        service: _FakeTable(),
        metrics: const SheetMetrics(rowHeight: _kRowHeight, gutterWidth: 40),
        widths: SheetWidths(defaultWidth: _kCellWidth, minWidth: 60),
        context: () => context
      );

      return Provider<SheetController>.value(
        value: controller,
        child: SheetTheme(
          style: style,
          child: Scaffold(body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              key: _kCell,
              width: _kCellWidth,
              height: _kRowHeight,
              child: Container(
                alignment: Alignment.centerLeft,
                padding: type.picker ? style.framePadding : style.cellPadding,
                decoration: style.cell(row: row, selected: false),
                child: SheetCells.value(
                  type: type,
                  value: raw?.toString() ?? "",
                  raw: raw,
                  style: style.value,
                  alignment: type.alignment,
                  row: row,
                  column: 0,
                  columnKey: "col_0"
                )
              )
            )
          ))
        )
      );
    })
  ));

  return style;
}

/// La direccion con la que se pinto la foto.
String _drawn(WidgetTester tester) =>
  (tester.widget<Image>(find.byType(Image)).image as NetworkImage).url;

void main() {
  setUpAll(() {
    ThemeColor.light = lightScheme;
    ThemeColor.dark = darkScheme;
  });

  setUp(() => CdnService().seed({
    "media": "https://cdn.test/rigel/media",
    "assets": "https://cdn.test/rigel/assets"
  }));

  tearDown(() => CdnService().clear());

  testWidgets('la celda es un cuadrado aunque la columna sea ancha', (tester) async {
    // Es la razon de ser de esta celda: una foto es cuadrada, asi que su celda
    // mide siempre lo mismo. Estirandose con la columna, cada ancho daria un
    // recorte distinto y una foto vertical se veria como una franja.
    final style = await _cell(tester, raw: [_kCover]);

    final cell = tester.getRect(find.byKey(_kCell));
    final frame = tester.getRect(find.byType(ImageCell));
    final inset = style.framePadding.top;

    expect(frame.width, closeTo(frame.height, 0.5));
    expect(frame.height, closeTo(_kRowHeight - inset * 2 - _kLine, 0.5));

    // Y queda contra el borde izquierdo: lo que sobra de la columna queda vacio,
    // no repartido a los costados.
    expect(frame.left - cell.left, closeTo(inset, 0.5));
    expect(frame.width, lessThan(_kCellWidth / 2));
  });

  testWidgets('el cuadrado no cambia con el valor', (tester) async {
    await _cell(tester, raw: [_kCover]);
    final withPicture = tester.getRect(find.byType(ImageCell));

    await _cell(tester, raw: null);
    final empty = tester.getRect(find.byType(ImageCell));

    expect(empty.size, withPicture.size);
  });

  testWidgets('se dibuja la miniatura y no la foto entera', (tester) async {
    // La celda mide cuarenta pixeles: pedir la grande seria bajar megas por fila
    // para dibujar un cuadradito.
    await _cell(tester, raw: [_kCover]);

    expect(
      _drawn(tester),
      "https://cdn.test/rigel/media/$_kCover@$kProductImageWidth"
    );
  });

  testWidgets('de la galeria se ve la portada', (tester) async {
    // En una fila de planilla no entran tres fotos, y la que define al producto
    // es la primera.
    await _cell(tester, raw: [_kCover, _kSecond]);

    expect(find.byType(Image), findsOneWidget);
    expect(_drawn(tester), contains(_kCover));
  });

  testWidgets('un id suelto se lee igual que una galeria de uno', (tester) async {
    // Es lo que quedo guardado antes de que hubiera galerias, y sigue siendo una
    // foto.
    await _cell(tester, raw: _kCover);

    expect(_drawn(tester), contains(_kCover));
  });

  testWidgets('una direccion importada se baja de donde esta', (tester) async {
    // No es un archivo nuestro: no se la puede pedir por id ni tiene miniatura.
    await _cell(tester, raw: "https://tienda.test/foto.jpg");

    expect(_drawn(tester), "https://tienda.test/foto.jpg");
  });

  testWidgets('sin foto se ve donde tocar para poner una', (tester) async {
    // Una celda en blanco no dice que ahi va una imagen. Esto no es un aviso de
    // que falte algo —una foto es opcional— sino el lugar donde se pone.
    final style = await _cell(tester, raw: null);

    expect(find.byType(Image), findsNothing);
    expect(find.byIcon(CI.add_image), findsOneWidget);

    final frame = tester
      .widget<Container>(find
        .descendant(of: find.byType(ImageCell), matching: find.byType(Container))
        .first)
      .decoration as BoxDecoration;

    expect(frame.color, style.frameFill(row: 0));
  });

  testWidgets('el cuadro se despega del fondo de su fila', (tester) async {
    // Con la cebra la planilla usa sus dos superficies fila por medio: con un
    // color fijo, el cuadro desapareceria en la mitad de las filas.
    final style = await _cell(tester, raw: null);

    expect(style.frameFill(row: 0), isNot(style.frameFill(row: 1)));
  });

  testWidgets('una columna de imagenes no abre editor de texto', (tester) async {
    // Lo decide el tipo y no la celda: es la misma pregunta que hacen el toque y
    // el teclado para saber si abren el editor o el desplegable.
    expect(TableFieldType.image.picker, isTrue);
    expect(TableFieldType.image.editable, isTrue);
  });
}
