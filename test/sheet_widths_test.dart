import 'package:flutter_test/flutter_test.dart';

import 'package:app/screens/home/sections/inventory/table_view/state/sheet_widths.dart';

SheetWidths _widths() =>
  SheetWidths(defaultWidth: 100, minWidth: 40, maxWidth: 400)
    ..setKeys(["a", "b", "c"]);

void main() {
  test('una columna que no se toco mide lo de siempre', () {
    final widths = _widths();

    expect(widths.valueOf("a"), 100);
    expect(widths.total.value, 300);
  });

  test('arrastrar solo avisa a la columna que se arrastra', () {
    // Es toda la razon de que cada columna tenga su propio notificador: un
    // arrastre manda un evento por frame, y con un aviso global cada uno de esos
    // frames volveria a construir todas las celdas de la pantalla.
    final widths = _widths();

    int a = 0;
    int b = 0;
    widths.of("a").addListener(() => a += 1);
    widths.of("b").addListener(() => b += 1);

    widths.resize("a", 25);

    expect(widths.valueOf("a"), 125);
    expect(a, 1);
    expect(b, 0, reason: "la columna de al lado solo se corre, no se rehace");
  });

  test('una columna no se puede colapsar hasta desaparecer', () {
    final widths = _widths();

    widths.resize("a", -500);

    expect(widths.valueOf("a"), 40);
  });

  test('en el minimo, seguir arrastrando no avisa', () {
    // Sin esta guarda, apoyarse contra el borde seguiria repintando esa columna
    // en cada frame del arrastre.
    final widths = _widths();
    widths.resize("a", -500);

    int notices = 0;
    widths.of("a").addListener(() => notices += 1);

    widths.resize("a", -50);

    expect(notices, 0);
  });

  test('el ancho total sigue a los arrastres', () {
    // Es lo que le da ancho a la banda desplazable: si no lo siguiera, la
    // planilla no se podria correr hasta el final de la ultima columna.
    final widths = _widths();

    widths.resize("b", 60);

    expect(widths.total.value, 360);
  });

  test('agregar una columna la suma al total', () {
    final widths = _widths();

    widths.setKeys(["a", "b", "c", "d"]);

    expect(widths.total.value, 400);
  });

  test('una columna tampoco se puede estirar sin fin', () {
    // El ancho se guarda y lo ve todo el mundo: una columna de miles de pixeles
    // dejaria la tabla asi para todos.
    final widths = _widths();

    widths.resize("a", 5000);

    expect(widths.valueOf("a"), 400);
  });

  test('la columna se abre con el ancho que quedo guardado', () {
    final widths = _widths();

    widths.adopt("a", 250);

    expect(widths.valueOf("a"), 250);
    expect(widths.total.value, 450);
  });

  test('una columna que nunca se arrastro mide lo de siempre', () {
    // Asi llegan las que no tienen ancho guardado: no hay nada que adoptar.
    final widths = _widths();

    widths.adopt("a", 0);

    expect(widths.valueOf("a"), 100);
  });

  test('lo guardado no pisa lo que se acaba de arrastrar', () {
    // La estructura se relee por cualquier cambio de columna (crear otra,
    // renombrarla) y llega con el ancho que estaba guardado cuando salio la
    // peticion: puede ser mas viejo que el arrastre que todavia esta viajando.
    final widths = _widths();

    widths.resize("a", 60);
    widths.adopt("a", 250);

    expect(widths.valueOf("a"), 160);
  });

  test('lo guardado se adopta una sola vez', () {
    // Segunda relectura de la estructura: la columna ya la decide la pantalla.
    final widths = _widths();

    widths.adopt("a", 250);
    widths.resize("a", -50);
    widths.adopt("a", 250);

    expect(widths.valueOf("a"), 200);
  });

  test('un ancho que no se pudo guardar vuelve al que tenia', () {
    final widths = _widths();

    widths.resize("a", 80);
    widths.restore("a", 100);

    expect(widths.valueOf("a"), 100);
    expect(widths.total.value, 300);
  });

  test('la posicion de una columna es lo que hay a su izquierda', () {
    // Lo usa el traer-a-la-vista al recorrer la planilla con el teclado.
    final widths = _widths();
    widths.resize("a", 50);

    expect(widths.offsetOf(0), 0);
    expect(widths.offsetOf(1), 150);
    expect(widths.offsetOf(2), 250);
    expect(widths.widthAt(0), 150);
  });
}
