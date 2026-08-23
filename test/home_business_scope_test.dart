import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/screens/home/sections/_sections.dart';
import 'package:app/screens/home/sections/business/_business_detail.dart';
import 'package:app/screens/home/sections/business/business_tab.dart';
import 'package:app/screens/home/sections/inventory/table_list/_table_list.dart';
import 'package:app/screens/home/sections/inventory/table_view/_table_view.dart';

Key? _keyOf(String currentKey, HomeSection section, String? businessId) =>
  homeContent(currentKey, section, businessId).key;

void main() {
  test('el contenido cambia de identidad al cambiar de empresa', () {
    // Es lo que hace que la seccion se monte de nuevo en vez de actualizarse, y
    // con eso que vuelva a pedir sus datos: sin esto se queda mostrando los de
    // la empresa anterior.
    final one = _keyOf("inventory", HomeSection.inventory, "1842");
    final other = _keyOf("inventory", HomeSection.inventory, "77");

    expect(one, isNotNull);
    expect(one, isNot(other));
  });

  test('la misma empresa conserva la identidad del contenido', () {
    // Si no, cualquier reconstruccion del shell (plegar el side bar, cambiar de
    // seccion y volver) desmontaria la seccion y tiraria lo que tenia cargado.
    expect(
      _keyOf("inventory", HomeSection.inventory, "1842"),
      _keyOf("inventory", HomeSection.inventory, "1842")
    );
  });

  test('cada seccion queda dentro del alcance de la empresa', () {
    for (final section in HomeSection.values) {
      expect(
        _keyOf(section.key, section, "1842"),
        isNot(_keyOf(section.key, section, "77")),
        reason: "${section.key} no sigue a la empresa"
      );
    }
  });

  test('el contenido sigue siendo el de la pantalla abierta', () {
    // El alcance de la empresa envuelve al contenido, no lo reemplaza.
    Widget childOf(String currentKey, HomeSection section) =>
      (homeContent(currentKey, section, "1842") as KeyedSubtree).child;

    expect(
      childOf(HomeSection.inventory.key, HomeSection.inventory),
      isA<InventorySection>()
    );
    expect(
      childOf(TableViewSection.routeKey, HomeSection.inventory),
      isA<TableViewSection>()
    );
    expect(
      childOf(BusinessDetailSection.routeKey, HomeSection.business),
      isA<BusinessDetailSection>()
    );
    // La seccion de empresas es la pagina de la empresa: no hay listado por
    // delante, y sus pestanas son la misma pantalla.
    expect(
      childOf(HomeSection.business.key, HomeSection.business),
      isA<BusinessDetailSection>()
    );
    expect(
      childOf(BusinessTab.settings.routeKey, HomeSection.business),
      isA<BusinessDetailSection>()
    );
  });
}
