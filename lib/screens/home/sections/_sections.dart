import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

import './placeholder.dart';
import './business/business_list.dart';
import './business/business_profile.dart';
import './products/tables.dart';
import './products/table_view.dart';

/// Secciones que viven dentro del shell del home.
///
/// Cada seccion es una ruta propia (`/home/...`) por lo que se refleja en la
/// URL y se puede abrir directamente por deep link. El shell (side bar) es el
/// mismo para todas, solo cambia el contenido de [build].
enum HomeSection {
  // La key es la de la seccion, no la de la pagina home: el home es el shell
  // que contiene a todas, mientras que el dashboard es solo una mas de ellas.
  dashboard(key: "dashboard", path: "/home", icon: CI.home),
  business(key: "business", path: "/home/business", icon: CI.store),
  products(key: "products", path: "/home/products", icon: CI.shop),
  services(key: "services", path: "/home/services", icon: CI.task_list),
  myBots(key: "my_bots", path: "/home/my_bots", icon: Icons.smart_toy_outlined),
  finance(key: "finance", path: "/home/finance", icon: CI.wallet),
  marketing(key: "marketing", path: "/home/marketing", icon: Icons.campaign_outlined),
  report(key: "report", path: "/home/report", icon: CI.chart),
  externalServices(key: "external_services", path: "/home/external_services", icon: CI.link);

  const HomeSection({
    required this.key,
    required this.path,
    required this.icon
  });

  /// Identificador corto de la seccion, usado como key de su [ScreenRoute].
  final String key;

  /// URL de la seccion. Es la unica fuente del `url` de su [ScreenRoute]: la
  /// resolucion de path a pantalla la hace `Navis`, no esta clase, para que la
  /// tabla de rutas no quede duplicada.
  final String path;
  final IconData icon;

  /// Grupo principal del side bar.
  static const List<HomeSection> main = [
    dashboard,
    business,
    products,
    services,
    myBots,
    finance,
    marketing,
    report
  ];

  /// Grupo secundario del side bar.
  static const List<HomeSection> tools = [
    externalServices
  ];

  static final Map<String, HomeSection> _byKey = {
    for (final section in values) section.key: section
  };

  /// Seccion registrada con esa key, o `null` si la key no es de una seccion
  /// (por ejemplo, la de una sub-pagina).
  static HomeSection? byKey(String key) => _byKey[key];

  /// Seccion que contiene a la pantalla [currentKey], o `null` si ninguna.
  static HomeSection? containing(String currentKey) {
    for (final section in values) {
      if (section.isCurrent(currentKey)) return section;
    }
    return null;
  }

  /// `true` si la pantalla [currentKey] pertenece a esta seccion: o es la
  /// seccion misma, o es una sub-pagina suya. Asi `business_detail`, que
  /// declara `parents: ["business"]`, mantiene marcada a [business].
  bool isCurrent(String currentKey) => currentKey == key
    || (Navis.byKey(currentKey)?.isInside(key) ?? false);

  String title(BuildContext context) => switch (this) {
    dashboard => S.of(context).home,
    business => S.of(context).business,
    products => S.of(context).products,
    services => S.of(context).services,
    myBots => S.of(context).my_bots,
    finance => S.of(context).finance,
    marketing => S.of(context).marketing,
    report => S.of(context).report,
    externalServices => S.of(context).external_services
  };

  Widget build() => switch (this) {
    business => const BusinessListSection(),
    products => const ProductTablesSection(),
    _ => SectionPlaceholder(section: this)
  };
}

/// Contenido que el shell debe mostrar para la pantalla [currentKey].
///
/// Normalmente es la propia [section] (resuelta ya en `Home`), pero cuando la
/// pantalla activa es una sub-pagina se muestra la sub-pagina en su lugar,
/// mientras la [section] que la contiene sigue marcando su opcion en el side
/// bar. Es el punto donde se enrutan las sub-paginas del home.
Widget homeContent(String currentKey, HomeSection section) => switch (currentKey) {
  BusinessProfileSection.routeKey => const BusinessProfileSection(),
  TableViewSection.routeKey => const TableViewSection(),
  _ => section.build()
};
