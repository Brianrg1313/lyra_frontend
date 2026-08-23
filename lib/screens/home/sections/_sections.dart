import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

import './business_listener.dart';
import './no_business.dart';
import './placeholder.dart';
import 'business/_business_detail.dart';
import './channels/_channels.dart';
import './channels/form/_channel_form.dart';
import './connections/_connections.dart';
import './connections/form/_connection_form.dart';
import './inventory/table_list/_table_list.dart';
import './inventory/table_view/_table_view.dart';

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
  inventory(key: "inventory", path: "/home/inventory", icon: CI.shop),
  services(key: "services", path: "/home/services", icon: CI.task_list),
  channels(key: "channels", path: "/home/channels", icon: CI.ia),
  connections(key: "connections", path: "/home/connections", icon: CI.cloud_connected),
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

  /// Grupo de productos del side bar.
  static const List<HomeSection> home = [
    dashboard,
    business
  ];

  /// Grupo de productos del side bar.
  static const List<HomeSection> productos = [
    inventory,
    services,
    channels
  ];

  /// Grupo de reportes del side bar.
  static const List<HomeSection> reportes = [
    finance,
    marketing,
    report
  ];

  /// Grupo de conexiones del side bar.
  ///
  /// Las conexiones van primero porque son las cuentas propias de la empresa
  /// —lo que se conecta y se mira seguido—; los servicios externos son lo que
  /// la plataforma consume por detras.
  static const List<HomeSection> conexiones = [
    connections,
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
    inventory => S.of(context).inventory,
    services => S.of(context).services,
    channels => S.of(context).channels,
    connections => S.of(context).connections,
    finance => S.of(context).finance,
    marketing => S.of(context).marketing,
    report => S.of(context).report,
    externalServices => S.of(context).external_services
  };

  /// `true` si la seccion no se puede abrir sin una empresa activa.
  ///
  /// Casi todas lo son: lo que muestran —las tablas, los canales, las
  /// conexiones— cuelga de una empresa, y lo piden en su `initState` leyendo
  /// `BusinessService.active`, que da por sentado que la hay.
  ///
  /// Las dos que no son el dashboard, que es la portada del home y lo primero
  /// que un cliente sin empresas tiene que poder ver, y la seccion de empresas
  /// misma: bloquearla seria bloquear justamente el lugar donde se crea la
  /// primera. Sin ninguna no muestra un detalle sino el alta (ver [_screen]),
  /// que es el mismo camino que ofrece el selector del header.
  ///
  /// Lo miran los dos lados de la misma regla: el side bar, para bloquear la
  /// opcion (ver `options`), y el shell, para no montar la seccion aunque se
  /// llegue por URL (ver [homeContent]).
  bool get needsBusiness => this != dashboard && this != business;

  /// Contenido de la seccion.
  ///
  /// [business] no tiene caso: su contenido lo arma [homeContent], que es quien
  /// conoce la empresa de la URL y le da su identidad. Es la unica seccion que
  /// tambien es la pagina de sus sub-paginas —sus pestanas—, asi que armarla
  /// aca la dejaria sin key y cambiar de empresa no la volveria a montar.
  Widget build() => switch (this) {
    inventory => const InventorySection(),
    channels => const ChannelsSection(),
    connections => const ConnectionsSection(),
    _ => SectionPlaceholder(section: this)
  };
}

/// Contenido que el shell debe mostrar para la pantalla [currentKey], atado a la
/// empresa [businessId].
///
/// Normalmente es la propia [section] (resuelta ya en `Home`), pero cuando la
/// pantalla activa es una sub-pagina se muestra la sub-pagina en su lugar,
/// mientras la [section] que la contiene sigue marcando su opcion en el side
/// bar. Es el punto donde se enrutan las sub-paginas del home.
///
/// Lo que se ve dentro del home es siempre de una empresa, asi que el contenido
/// se identifica con ella: cambiar de empresa cambia la identidad de esta parte
/// del arbol y el `Navigator` la monta de nuevo en vez de actualizarla. Es lo
/// que hace que **cada seccion vuelva a pedir sus datos** —los que carga en su
/// `initState`— sin tener que escuchar a la empresa por su cuenta, incluidas las
/// secciones que todavia no existen.
///
/// Se monta de nuevo y no se refresca a proposito: de la empresa anterior no es
/// solo lo cargado, tambien es lo que se escribio en el buscador, donde estaba
/// parada la planilla o la celda que se estaba editando. Conservarlo seria
/// mezclar dos empresas en la misma pantalla.
///
/// Lo unico que esto no arregla son las sub-paginas atadas a un id de la empresa
/// anterior (`/home/inventory/:id`): montarlas de nuevo pediria una tabla que la
/// empresa nueva no tiene. Esas escuchan el cambio y se mueven solas, ver
/// [BusinessListener].
///
/// Sin [businessId] no hay empresa activa (un cliente recien registrado, o uno
/// que todavia no creo la suya) y las secciones que dependen de una no se
/// montan: piden sus datos en su `initState` —`BusinessService.active` da por
/// sentado que la hay—, asi que entrar a una sin empresa reventaria antes de
/// pintar. En su lugar va [NoBusinessSection], que ofrece el alta. Las que se
/// muestran igual son las de [HomeSection.needsBusiness] en `false`, las mismas
/// que el side bar deja habilitadas: el dashboard y la seccion de empresas, que
/// sin ninguna es tambien el alta (ver [_screen]).
///
/// Se comprueba aca ademas de en el side bar porque una seccion es una URL: con
/// las opciones bloqueadas todavia se puede llegar por deep link, recargando la
/// pagina o con el boton de atras del navegador.
Widget homeContent(
  String currentKey,
  HomeSection section,
  String? businessId
) => KeyedSubtree(
  key: ValueKey(businessId),
  child: businessId == null && section.needsBusiness
    ? const NoBusinessSection()
    : _screen(currentKey, section, businessId)
);

/// La pantalla que va dentro del shell: la [section] abierta, o la sub-pagina
/// suya que diga [currentKey].
Widget _screen(String currentKey, HomeSection section, String? businessId) {
  // La seccion de empresas y sus pestanas son la misma pantalla, y son las
  // pestanas las que traen el id en la URL: se resuelve por la seccion y no por
  // la pantalla abierta, que es una key distinta por pestana.
  if (section == HomeSection.business) {
    // Sin empresa activa no hay detalle que mostrar, pero la seccion se abre
    // igual: es el lugar natural para crear la primera. Se pide el alta en vez
    // de montar el detalle, que sin empresa buscaria un perfil que no existe.
    //
    // Se mira tambien la URL para no pisar el link de una empresa concreta: ese
    // id no es del cliente (si lo fuera seria la activa) y el detalle ya sabe
    // decirlo.
    if (businessId == null && Navis.currentArgs?["id"] == null) {
      return const NoBusinessSection();
    }

    // Una key por empresa: la pagina lee el id de la URL al montarse y desde
    // ahi alinea la empresa activa con el. Sin esto, ir de una empresa a otra
    // por el historial del navegador reusaria el `State` anterior y la pantalla
    // se quedaria esperando una empresa que nadie va a activar.
    //
    // Sin id en la URL la empresa es la activa, asi que esa es la key: la
    // seccion pelada y el link de la empresa que ya se esta mirando son la
    // misma pagina, y pasar de una al otro no tiene por que montarla de nuevo.
    return BusinessDetailSection(
      key: ValueKey("business_${Navis.currentArgs?["id"] ?? businessId}")
    );
  }

  return switch (currentKey) {
    TableViewSection.routeKey => const TableViewSection(),
    // Las dos rutas del formulario de un canal son la misma pantalla, asi que
    // se le da una key distinta a cada una: sin eso, pasar del alta a un canal
    // (o de un canal a otro) reusaria el `State` anterior, que ya leyo el id de
    // la URL en su `initState` y seguiria editando el canal de antes.
    ChannelFormSection.createRouteKey =>
      const ChannelFormSection(key: ValueKey("channel_new")),
    ChannelFormSection.editRouteKey => ChannelFormSection(
      key: ValueKey("channel_${Navis.currentArgs?["id"]}")
    ),
    // Lo mismo para el formulario de una conexion, y por el mismo motivo: las
    // dos rutas son la misma pantalla, que lee el id en su `initState`.
    ConnectionFormSection.createRouteKey =>
      const ConnectionFormSection(key: ValueKey("connection_new")),
    ConnectionFormSection.editRouteKey => ConnectionFormSection(
      key: ValueKey("connection_${Navis.currentArgs?["id"]}")
    ),
    _ => section.build()
  };
}
