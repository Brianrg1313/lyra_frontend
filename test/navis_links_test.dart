import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';
import 'package:core/navis/screen_route.dart';

/// Pantalla de relleno. Nunca se construye: los tests miran el historial que
/// lleva `Navis`, no lo que se renderiza.
class _Screen extends PageBuilder {
  const _Screen();

  @override
  Widget build(BuildContext context) => const SizedBox();
}

/// Tres modulos del mismo shell —una sola pagina del Navigator entre los
/// tres— y dos pantallas sueltas, que si se apilan.
final _routes = [
  ScreenRoute(key: "root", url: "/", page: (_) => const _Screen()),
  ScreenRoute(key: "loose", url: "/loose", page: (_) => const _Screen()),
  // Salir de aca limpia el stack: es como los tests vuelven a foja cero.
  ScreenRoute(
    key: "reset",
    url: "/reset",
    clearHistoryOnExit: true,
    page: (_) => const _Screen()
  ),
  ScreenRoute(
    key: "alpha",
    url: "/shell/alpha",
    shell: "s",
    page: (_) => const _Screen()
  ),
  ScreenRoute(
    key: "beta",
    url: "/shell/beta",
    shell: "s",
    page: (_) => const _Screen()
  ),
  ScreenRoute(
    key: "gamma",
    url: "/shell/gamma",
    shell: "s",
    page: (_) => const _Screen()
  )
];

({bool back, bool forward}) get _canNavigate => Navis.canNavigate.value;

void _reset() {
  Navis.navigate("/reset");
  Navis.navigate("/");
}

void main() {
  setUpAll(() {
    // `_createPage` lee accessibilityFeatures del binding.
    TestWidgetsFlutterBinding.ensureInitialized();
    Navis.defineRoutes(_routes);
  });

  setUp(_reset);

  test('recien abierta la app no tiene a donde ir', () {
    expect(_canNavigate, (back: false, forward: false));
  });

  test('cambiar de modulo deja a donde volver', () {
    Navis.navigate("/shell/alpha");
    Navis.navigate("/shell/beta");

    // Regresion: el historial se medía contra el stack de paginas, y como los
    // modulos de un shell comparten una sola pagina, el stack no crecia y las
    // flechas de la barra no aparecian nunca.
    expect(Navis().history.length, 2);
    expect(_canNavigate.back, true);
  });

  test('volver cambia de modulo sin descartar la pagina', () {
    Navis.navigate("/shell/alpha");
    Navis.navigate("/shell/beta");
    Navis.back();

    expect(Navis.currentPath, "/shell/alpha");
    expect(Navis.currentKey.value, "alpha");
    expect(Navis().history.length, 2);
    expect(_canNavigate, (back: true, forward: true));
  });

  test('avanzar vuelve al modulo del que se habia vuelto', () {
    Navis.navigate("/shell/alpha");
    Navis.navigate("/shell/beta");
    Navis.back();
    Navis.forward();

    expect(Navis.currentPath, "/shell/beta");
    expect(Navis.currentKey.value, "beta");
    expect(_canNavigate, (back: true, forward: false));
  });

  test('el historial recorre todos los modulos visitados', () {
    Navis.navigate("/shell/alpha");
    Navis.navigate("/shell/beta");
    Navis.navigate("/shell/gamma");

    Navis.back();
    Navis.back();
    expect(Navis.currentPath, "/shell/alpha");

    Navis.back();
    expect(Navis.currentPath, "/");
    expect(_canNavigate.back, false);
  });

  test('irse a otro lado descarta lo que quedaba adelante', () {
    Navis.navigate("/shell/alpha");
    Navis.navigate("/shell/beta");
    Navis.back();
    Navis.navigate("/shell/gamma");

    expect(_canNavigate.forward, false);
  });

  test('volver a mano al modulo anterior no agrega una parada', () {
    Navis.navigate("/shell/alpha");
    Navis.navigate("/shell/beta");

    // Tocar la opcion del side bar de la que uno venia es volver, aunque no
    // pase por la flecha: si contara como parada nueva, `beta` se perderia y
    // avanzar dejaria de estar disponible.
    Navis.navigate("/shell/alpha");

    expect(_canNavigate, (back: true, forward: true));

    Navis.forward();
    expect(Navis.currentPath, "/shell/beta");
  });

  test('las pantallas sueltas siguen entrando al historial', () {
    Navis.navigate("/shell/alpha");
    Navis.navigate("/loose");

    expect(Navis().history.length, 3);
    expect(_canNavigate.back, true);

    Navis.back();
    expect(Navis.currentPath, "/shell/alpha");
  });

  test('el pop conserva lo que quedo por delante', () {
    Navis.navigate("/loose");

    // Lo que hace el delegate cuando el Navigator descarta una pagina: un pop
    // por gesto, por `Navis.pop` o por la flecha.
    Navis().removePage(Navis().history.last);

    expect(Navis.currentPath, "/");
    expect(Navis.currentKey.value, "root");
    expect(_canNavigate, (back: false, forward: true));

    Navis.forward();
    expect(Navis.currentPath, "/loose");
  });

  test('limpiar el stack tambien limpia el historial de links', () {
    Navis.navigate("/shell/alpha");
    Navis.navigate("/reset");

    // Salir de una pantalla con `clearHistoryOnExit` no deja volver a ella:
    // por la flecha tampoco.
    Navis.navigate("/shell/beta");

    expect(Navis().history.length, 1);
    expect(_canNavigate, (back: false, forward: false));
  });
}
