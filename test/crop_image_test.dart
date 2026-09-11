import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/screens/modals/shared/crop_image/_crop_image.dart';

/// Una imagen apaisada con una franja al medio: es el caso que el recorte tiene
/// que resolver —de un rectangulo sale un cuadrado— y la franja dice **cual**
/// parte quedo, que es lo unico que no se puede comprobar midiendo.
///
/// Mide 400x200 y la franja va de 150 a 250, o sea el cuadrado central: si el
/// recorte abre centrado, lo que sale es la franja entera y nada de los lados.
Future<Uint8List> _stripe() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 400, 200),
    Paint()..color = const Color(0xFFFF0000)
  );
  canvas.drawRect(
    const Rect.fromLTWH(150, 0, 100, 200),
    Paint()..color = const Color(0xFF00FF00)
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(400, 200);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);

  picture.dispose();
  image.dispose();

  return data!.buffer.asUint8List();
}

/// El color de un pixel del recorte, para preguntarle que parte de la imagen
/// original quedo adentro.
Future<Color> _pixel(ui.Image image, int x, int y) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final offset = (y * image.width + x) * 4;

  return Color.fromARGB(
    data!.getUint8(offset + 3),
    data.getUint8(offset),
    data.getUint8(offset + 1),
    data.getUint8(offset + 2)
  );
}

/// Una pantalla que abre el modal y se queda con lo que devuelve, que es como
/// lo abre la ficha de la empresa: el recorte vuelve por `Navigator.pop`.
Widget _app(Uint8List bytes, void Function(Object? result) onResult) =>
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

      return Scaffold(body: Center(child: TextButton(
        onPressed: () async => onResult(
          await Navigator.of(context).push<Object?>(MaterialPageRoute(
            builder: (context) => Scaffold(
              body: Center(child: CropImageModal(bytes: bytes))
            )
          ))
        ),
        child: const Text("open")
      )));
    })
  );

void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  /// Le da lugar al trabajo que no pasa por el reloj falso de las pruebas:
  /// leer la imagen y dibujar el recorte los hace el motor, no el arbol de
  /// widgets, asi que sin esto la prueba espera para siempre un cargando que no
  /// termina nunca.
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100))
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// Abre el modal con la imagen ya leida.
  Future<void> open(WidgetTester tester, Uint8List bytes) async {
    await tester.tap(find.text("open"));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await settle(tester);
  }

  testWidgets('acepta sin tocar nada y devuelve el cuadrado del medio', (tester) async {
    late final Uint8List bytes;
    await tester.runAsync(() async => bytes = await _stripe());

    Object? result;

    await tester.pumpWidget(_app(bytes, (value) => result = value));
    await open(tester, bytes);

    expect(find.byType(CropImageModal), findsOneWidget);

    await tester.tap(find.text("Save"));
    await tester.pump();
    await settle(tester);

    expect(tester.takeException(), isNull);
    expect(result, isA<Uint8List>());

    late final ui.Image cropped;
    late final Color center;
    late final Color left;
    late final Color right;
    late final Color inside;

    await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(result! as Uint8List);
      cropped = (await codec.getNextFrame()).image;

      center = await _pixel(cropped, 100, 100);
      left = await _pixel(cropped, 2, 100);
      right = await _pixel(cropped, 197, 100);
      inside = await _pixel(cropped, 55, 100);
    });

    // Cuadrado y del lado corto de la original: se recorta lo que sobra, no se
    // agranda nada para llegar al maximo.
    expect(cropped.width, 200);
    expect(cropped.height, 200);

    // Y es el cuadrado del medio: de la original (400 de ancho) quedo lo que
    // va de 100 a 300, asi que la franja verde —de 150 a 250— cae justo en el
    // medio del recorte y los bordes son el rojo que la rodeaba.
    expect(center, const Color(0xFF00FF00));
    expect(inside, const Color(0xFF00FF00));
    expect(left, const Color(0xFFFF0000));
    expect(right, const Color(0xFFFF0000));

    cropped.dispose();
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('mover la imagen mueve lo que queda adentro', (tester) async {
    late final Uint8List bytes;
    await tester.runAsync(() async => bytes = await _stripe());

    Object? result;

    await tester.pumpWidget(_app(bytes, (value) => result = value));
    await open(tester, bytes);

    // El marco es cuadrado y del ancho del modal, asi que su centro esta a
    // media anchura de su borde de arriba.
    final origin = tester.getTopLeft(find.byType(CropImageModal));
    final frame = tester.getSize(find.byType(CropImageModal)).width;

    // Correr la imagen a la derecha es quedarse con lo que estaba mas a la
    // izquierda: la ventana no se mueve, se mueve lo que hay debajo.
    await tester.dragFrom(
      origin + Offset(frame / 2, frame / 2),
      const Offset(40, 0)
    );
    await tester.pump();

    await tester.tap(find.text("Save"));
    await tester.pump();
    await settle(tester);

    expect(result, isA<Uint8List>());

    late final Color moved;

    await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(result! as Uint8List);
      final cropped = (await codec.getNextFrame()).image;

      moved = await _pixel(cropped, 170, 100);

      cropped.dispose();
    });

    // Ahi, sin tocar nada, estaba el rojo de la derecha de la franja; despues
    // de correrla, la franja verde llega hasta ahi.
    expect(moved, const Color(0xFF00FF00));
  }, timeout: const Timeout(Duration(seconds: 60)));

  testWidgets('cerrar el modal no devuelve ningun recorte', (tester) async {
    late final Uint8List bytes;
    await tester.runAsync(() async => bytes = await _stripe());

    Object? result;
    var closed = false;

    await tester.pumpWidget(_app(bytes, (value) {
      closed = true;
      result = value;
    }));

    await open(tester, bytes);

    // Lo mismo que hace el boton de cerrar del modal.
    Navigator.of(tester.element(find.byType(CropImageModal))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(closed, isTrue);
    expect(result, isNull);
  }, timeout: const Timeout(Duration(seconds: 60)));
}
