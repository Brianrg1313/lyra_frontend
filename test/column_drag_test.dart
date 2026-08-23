import 'package:flutter_test/flutter_test.dart';

import 'package:app/screens/home/sections/inventory/table_view/state/sheet_drag.dart';

/// Un arrastre ya empezado sobre cuatro columnas de 100 y una libre detras,
/// agarrando la columna [source] de su borde izquierdo.
SheetDrag _drag({int source = 0, double grab = 0}) {
  final drag = SheetDrag();

  drag.start(
    source: source,
    label: "Precio",
    grab: grab,
    edges: const [0, 100, 200, 300, 400, 500],
    fields: 4
  );

  return drag;
}

void main() {
  test('al empezar, la columna esta donde estaba', () {
    final drag = _drag(source: 1);

    expect(drag.active.value, isTrue);
    expect(drag.x.value, 100);
    expect(drag.edge.value, 1);
    expect(drag.width, 100);
  });

  test('el fantasma no salta bajo el puntero', () {
    // Se la agarro por el medio, asi que el fantasma tiene que quedar con su
    // medio bajo el puntero y no con su borde izquierdo.
    final drag = _drag(source: 1, grab: 50);

    drag.moveTo(150);

    expect(drag.x.value, 100);
  });

  test('la linea la decide el fantasma y no el puntero', () {
    // Agarrada de la punta derecha, el fantasma va bien a la izquierda del
    // puntero: mirar el puntero dejaria la linea atrasada media columna.
    final drag = _drag(source: 3, grab: 100);

    // El puntero esta sobre la columna 2, pero el fantasma la tapo entera.
    drag.moveTo(250);

    expect(drag.x.value, 150);
    expect(drag.edge.value, 2);
  });

  test('mover el puntero sin cambiar de vecina no mueve la linea', () {
    // Es lo que mantiene barato el arrastre: la linea se repinta unas pocas
    // veces y no una vez por frame.
    final drag = _drag(source: 0);

    drag.moveTo(10);
    final before = drag.edge.value;

    int notices = 0;
    drag.edge.addListener(() => notices += 1);

    drag.moveTo(20);
    drag.moveTo(30);
    drag.moveTo(40);

    expect(drag.edge.value, before);
    expect(notices, 0);
  });

  test('no se puede soltar sobre las columnas libres', () {
    // Detras de los campos no hay donde poner una columna de la tabla.
    final drag = _drag(source: 0);

    drag.moveTo(9999);

    expect(drag.edge.value, 4);
  });

  test('soltar devuelve de donde salio y donde cae, y apaga todo', () {
    final drag = _drag(source: 0);

    // El fantasma queda entre 220 y 320, con su medio pasado el de la tercera
    // columna: cae en el borde de detras de ella.
    drag.moveTo(220);

    expect(drag.stop(), (0, 3));
    expect(drag.active.value, isFalse);
    expect(drag.source, -1);
  });

  test('soltar sin haber arrastrado no mueve nada', () {
    final drag = SheetDrag();

    expect(drag.stop(), (-1, -1));
  });
}
