import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';
import 'package:core/navis/screen_route.dart';

/// Pantalla de relleno. Nunca se construye: los tests miran las paginas que
/// arma `Navis`, no lo que renderizan.
class _Screen extends PageBuilder {
  const _Screen();

  @override
  Widget build(BuildContext context) => const SizedBox();
}

final _routes = [
  ScreenRoute(key: "root", url: "/", page: (_) => const _Screen()),
  ScreenRoute(key: "loose", url: "/loose", page: (_) => const _Screen()),
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
  )
];

List<Page> get _history => Navis().history;

/// Vuelve a la raiz. Navegar a "/" trunca el historial, asi cada test arranca
/// desde el mismo estado del singleton.
void _reset() => Navis.navigate("/");

void main() {
  setUpAll(() {
    // `_createPage` lee accessibilityFeatures del binding.
    TestWidgetsFlutterBinding.ensureInitialized();
    Navis.defineRoutes(_routes);
  });

  setUp(_reset);

  test('las rutas de un mismo shell ocupan una sola pagina', () {
    Navis.navigate("/shell/alpha");
    expect(_history.length, 2);

    Navis.navigate("/shell/beta");

    // Regresion: antes cada path era una pagina propia y se apilaban, dejando
    // un armazon vivo por pantalla visitada.
    expect(_history.length, 2);
    expect(_history.last.name, "/shell/beta");
  });

  test('la pagina del shell conserva su identidad al cambiar de ruta', () {
    Navis.navigate("/shell/alpha");
    final key = _history.last.key;

    Navis.navigate("/shell/beta");

    // Es esta key la que hace que el Navigator actualice la pagina en vez de
    // recrearla, y con eso que el arbol (y su scroll) sobreviva.
    expect(key, const ValueKey("s"));
    expect(_history.last.key, key);
  });

  test('volver al shell desde fuera no duplica su pagina', () {
    Navis.navigate("/shell/alpha");
    Navis.navigate("/loose");
    Navis.navigate("/shell/beta");

    // Regresion: al apilarse una ruta sin shell encima, la vuelta al shell
    // agregaba una segunda pagina con su misma key y el Navigator lanza
    // "Duplicate keys found". El shell ocupa una sola posicion del historial.
    final keys = _history.map((page) => page.key).toList();
    expect(keys.toSet().length, keys.length);
    expect(_history.map((page) => page.name), ["/", "/shell/beta"]);
  });

  test('las rutas sin shell se siguen apilando', () {
    Navis.navigate("/shell/alpha");
    Navis.navigate("/loose");

    expect(_history.length, 3);
    expect(_history.map((page) => page.name), ["/", "/shell/alpha", "/loose"]);
  });

  test('currentKey sigue a la pantalla abierta', () {
    expect(Navis.currentKey.value, "root");

    Navis.navigate("/shell/alpha");
    expect(Navis.currentKey.value, "alpha");

    Navis.navigate("/shell/beta");
    expect(Navis.currentKey.value, "beta");
  });
}
