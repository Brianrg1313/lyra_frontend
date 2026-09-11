import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';
import 'package:app/screens/home/sections/inventory/table_list/sticky_bar.dart';

/// El contenido de la barra, con una llave para poder preguntar donde quedo.
/// Ocupa todo lo que le den para que su borde de arriba sea el de la barra.
const Key _bar = Key('sticky-bar-child');

/// El contenido de una segunda barra, clavada, para mirar como conviven.
const Key _pinned = Key('sticky-bar-pinned');

/// Lo que mide cualquiera de las barras de estas pruebas.
const double _height = 50;

Widget _scroll(ScrollController controller, List<Widget> slivers) => MaterialApp(
  home: Builder(builder: (context) {
    AppSize.instance(context);

    return Scaffold(body: CustomScrollView(
      controller: controller,
      slivers: slivers
    ));
  })
);

Widget _filler(int count) => SliverList.builder(
  itemCount: count,
  itemBuilder: (context, index) => SizedBox(height: 100, child: Text('$index'))
);

/// Donde tiene el borde de arriba la barra [key], contando **la que no esta**
/// como del todo afuera.
///
/// Una barra escondida no esta en el arbol, y sin este cero convenido la
/// diferencia entre "casi afuera" y "afuera" seria un salto en el medio de una
/// serie que justamente se mira para ver si es pareja.
double _top(WidgetTester tester, Key key) {
  final finder = find.byKey(key);

  return finder.evaluate().isEmpty
    ? -_height
    : tester.getTopLeft(finder).dy;
}

/// Scrollea con la rueda del mouse, que es lo que se usa en escritorio.
///
/// No es lo mismo que arrastrar: la rueda no tiene dedo que soltar, asi que
/// nada avisa que el movimiento termino, y sus ticks vienen mezclados con
/// rebotes de dos o tres pixeles para el otro lado.
Future<void> _wheel(WidgetTester tester, TestPointer pointer, double delta) async {
  await tester.sendEventToBinding(pointer.scroll(Offset(0, delta)));
  await tester.pump(const Duration(milliseconds: 16));
}

void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  group('la barra pegada', () {
    testWidgets('clavada se queda arriba con el contenido pasando por debajo',
      (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(_scroll(controller, [
          const SliverToBoxAdapter(child: SizedBox(height: 400)),
          const StickyBar(
            pinned: true,
            height: _height,
            child: SizedBox.expand(key: _bar)
          ),
          _filler(20)
        ]));

        // Antes de llegar arriba viaja con el resto: esta donde la dejo lo que
        // tiene encima.
        expect(tester.getTopLeft(find.byKey(_bar)).dy, 400);

        controller.jumpTo(1000);
        await tester.pump();

        // Y a partir de ahi no se mueve mas, aunque su lugar en el listado haya
        // quedado seiscientos pixeles mas arriba.
        expect(tester.getTopLeft(find.byKey(_bar)).dy, 0);
        expect(find.byKey(_bar), findsOneWidget);
      }
    );

    testWidgets('flotante se va al bajar y vuelve al subir un poco',
      (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(_scroll(controller, [
          const StickyBar(
            floating: true,
            height: _height,
            child: SizedBox.expand(key: _bar)
          ),
          _filler(20)
        ]));

        expect(tester.getTopLeft(find.byKey(_bar)).dy, 0);

        await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
        await tester.pumpAndSettle();

        // Se va del todo: el framework ni la dibuja ni la deja en el arbol.
        expect(find.byKey(_bar), findsNothing);

        // Y vuelve arrastrando para el otro lado, sin tener que subir hasta el
        // principio: el listado sigue estando en la mitad de donde estaba.
        await tester.drag(find.byType(CustomScrollView), const Offset(0, 60));
        await tester.pumpAndSettle();

        expect(tester.getTopLeft(find.byKey(_bar)).dy, 0);
        expect(controller.offset, greaterThan(100));
      }
    );

    testWidgets('flotante no parpadea con los rebotes de la rueda',
      (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(_scroll(controller, [
          const StickyBar(
            floating: true,
            height: _height,
            child: SizedBox.expand(key: _bar)
          ),
          _filler(40)
        ]));

        final pointer = TestPointer(1, PointerDeviceKind.mouse);
        await tester.sendEventToBinding(
          pointer.hover(tester.getCenter(find.byType(CustomScrollView)))
        );

        // Bajando la barra se va y **no vuelve a asomar en el camino**, aunque
        // entre tick y tick la rueda mande unos pixeles para el otro lado. Que
        // los atienda es el parpadeo: la barra entraba y salia en cuadros
        // seguidos, y de paso sacudia a lo que se clava debajo suyo.
        var previous = _top(tester, _bar);

        for (final delta in [60.0, 60.0, -3.0, 60.0, -2.0, 60.0, 60.0, -4.0, 60.0]) {
          await _wheel(tester, pointer, delta);

          final top = _top(tester, _bar);
          expect(top, lessThanOrEqualTo(previous), reason: 'asomo con d=$delta');
          previous = top;
        }

        await tester.pumpAndSettle();
        expect(find.byKey(_bar), findsNothing);
        previous = _top(tester, _bar);

        // Y volviendo pasa lo mismo al reves: entra de una, sin retroceder
        // porque la rueda haya frenado con un tick hacia abajo.
        for (final delta in [-60.0, 2.0, -60.0, 3.0, -60.0, 4.0]) {
          await _wheel(tester, pointer, delta);

          final top = _top(tester, _bar);
          expect(top, greaterThanOrEqualTo(previous), reason: 'se fue con d=$delta');
          previous = top;
        }

        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.byKey(_bar)).dy, 0);

        // Y volvio sin haber tenido que subir hasta el principio.
        expect(controller.offset, greaterThan(100));
      }
    );

    testWidgets('la clavada se apila debajo de la flotante, no atras',
      (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(_scroll(controller, [
          const StickyBar(
            floating: true,
            height: _height,
            child: SizedBox.expand(key: _bar)
          ),
          const StickyBar(
            pinned: true,
            height: _height,
            child: SizedBox.expand(key: _pinned)
          ),
          _filler(40)
        ]));

        controller.jumpTo(1000);
        await tester.pumpAndSettle();

        // Bajando, la barra de acciones se fue y el encabezado se clavo arriba
        // de todo.
        expect(find.byKey(_bar), findsNothing);
        expect(tester.getTopLeft(find.byKey(_pinned)).dy, 0);

        await tester.drag(find.byType(CustomScrollView), const Offset(0, 60));
        await tester.pumpAndSettle();

        // Y al volver la barra, el encabezado baja y se clava debajo suyo. Que
        // la barra le pasara por encima seria taparle los titulos a las filas
        // que se estan leyendo.
        expect(tester.getTopLeft(find.byKey(_bar)).dy, 0);
        expect(tester.getTopLeft(find.byKey(_pinned)).dy, _height);
      }
    );

    testWidgets('clavada se suelta cuando termina la parte a la que pertenece',
      (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);

        // La forma de la seccion de inventario: la barra de acciones flotando
        // arriba de todo, y adentro del cuerpo el resumen con su encabezado
        // clavado. Es lo que prueba esta armazon: un grupo dentro de otro con
        // una barra clavada adentro y otra flotando encima.
        await tester.pumpWidget(_scroll(controller, [
          const StickyBar(
            floating: true,
            height: _height,
            child: SizedBox.expand()
          ),
          SliverMainAxisGroup(slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 300)),
            SliverMainAxisGroup(slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
              const StickyBar(
                pinned: true,
                height: 30,
                child: SizedBox.expand(key: _bar)
              ),
              _filler(10)
            ])
          ]),
          const SliverToBoxAdapter(child: SizedBox(height: 800))
        ]));

        controller.jumpTo(500);
        await tester.pumpAndSettle();

        // Con filas suyas debajo se queda arriba, aunque le hayan pasado por
        // encima las tablas y su propio titulo.
        expect(tester.getTopLeft(find.byKey(_bar)).dy, 0);

        controller.jumpTo(controller.position.maxScrollExtent);
        await tester.pumpAndSettle();

        // Y se va con el resumen cuando el resumen se termina: un encabezado
        // clavado sobre otra cosa estaria diciendo que columna es cada una de
        // unas filas que ya no estan.
        expect(find.byKey(_bar), findsNothing);
      }
    );
  });
}
