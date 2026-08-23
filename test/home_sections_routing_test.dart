import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart';

import 'package:app/screens/home/sections/_sections.dart';
import 'package:app/screens/home/sections/business/_business_detail.dart';
import 'package:app/screens/home/sections/business/business_tab.dart';
import 'package:app/screens/home/sections/inventory/table_view/_table_view.dart';
import 'package:app/toolkit/settings/routes.dart';

void main() {
  setUpAll(() {
    // `defineRoutes` construye la pagina raiz, que necesita el binding vivo.
    TestWidgetsFlutterBinding.ensureInitialized();
    Navis.defineRoutes(routes);
  });

  test('cada seccion se registra con su propia url', () {
    for (final section in HomeSection.values) {
      final match = Navis().match(section.path);

      expect(match, isNotNull, reason: "${section.path} no resuelve");
      expect(match!.route.key, section.key);
    }
  });

  test('todas las secciones comparten una sola pagina', () {
    Navis.navigate(HomeSection.dashboard.path);
    final length = Navis().history.length;

    for (final section in HomeSection.values) {
      Navis.navigate(section.path);

      // El shell del home no se apila: cambiar de seccion actualiza la pagina.
      expect(Navis().history.length, length, reason: "${section.path} apilo");
      expect(Navis().history.last.name, section.path);
      expect(Navis.currentKey.value, section.key);
    }
  });

  test('la seccion abierta es la unica marcada', () {
    for (final current in HomeSection.values) {
      final marked = HomeSection.values
        .where((section) => section.isCurrent(current.key))
        .toList();

      expect(marked, [current]);
    }
  });

  test('el dashboard no se marca al estar en otra seccion', () {
    // Regresion: dashboard usaba la key "home" y el resto de secciones la
    // declaraban como parent, por lo que quedaba marcado en todas.
    expect(HomeSection.dashboard.isCurrent(HomeSection.business.key), isFalse);
    expect(HomeSection.dashboard.key, isNot("home"));
  });

  test('cada pestana de una empresa tiene su propia url', () {
    // Es lo que hace que el link de la barra sea el de lo que se esta mirando:
    // sin una ruta por pestana, las cinco compartirian la URL de la empresa.
    for (final tab in BusinessTab.values) {
      final path = tab.path("b986e16b");
      final match = Navis().match(path);

      expect(match, isNotNull, reason: "$path no resuelve");
      expect(match!.route.key, tab.routeKey);
      expect(match.args?["id"], "b986e16b");
    }
  });

  test('las pestanas no se apilan sobre la empresa', () {
    // Todas comparten el shell del home, asi que cambiar de pestana actualiza
    // la pagina en vez de apilar una nueva; lo que si cambia es la pantalla
    // activa, que es de donde la pagina lee que pestana mostrar.
    Navis.navigate("/home/business/b986e16b");
    final length = Navis().history.length;

    for (final tab in BusinessTab.values) {
      Navis.navigate(tab.path("b986e16b"));

      expect(Navis().history.length, length, reason: "${tab.key} apilo");
      expect(Navis.currentKey.value, tab.routeKey);
    }
  });

  test('una pestana mantiene marcada a la seccion de empresas', () {
    for (final tab in BusinessTab.values) {
      final marked = HomeSection.values
        .where((section) => section.isCurrent(tab.routeKey))
        .toList();

      expect(marked, [HomeSection.business], reason: "${tab.key} no marca");
    }
  });

  test('una sub-pagina mantiene marcada a su seccion', () {
    final marked = HomeSection.values
      .where((section) => section.isCurrent(BusinessDetailSection.routeKey))
      .toList();

    expect(marked, [HomeSection.business]);
  });

  test('una tabla es su propia url', () {
    // Es la unica ruta que cuelga de una tabla: sus ajustes son un panel
    // (`showTableSettings`) y no una pantalla, asi que abrirlos no toca la URL.
    final table = Navis().match("/home/inventory/b986e16b");

    expect(table, isNotNull);
    expect(table!.route.key, TableViewSection.routeKey);
    expect(table.args?["id"], "b986e16b");
  });

  test('una tabla abierta mantiene marcado el inventario', () {
    final marked = HomeSection.values
      .where((section) => section.isCurrent(TableViewSection.routeKey))
      .toList();

    expect(marked, [HomeSection.inventory]);
  });

  test('una key desconocida no marca ninguna seccion', () {
    final marked = HomeSection.values
      .where((section) => section.isCurrent("login"))
      .toList();

    expect(marked, isEmpty);
  });
}
