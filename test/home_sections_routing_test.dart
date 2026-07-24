import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart';

import 'package:app/screens/home/sections/_sections.dart';
import 'package:app/screens/home/sections/business/business_profile.dart';
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

  test('una sub-pagina mantiene marcada a su seccion', () {
    final marked = HomeSection.values
      .where((section) => section.isCurrent(BusinessProfileSection.routeKey))
      .toList();

    expect(marked, [HomeSection.business]);
  });

  test('una key desconocida no marca ninguna seccion', () {
    final marked = HomeSection.values
      .where((section) => section.isCurrent("login"))
      .toList();

    expect(marked, isEmpty);
  });
}
