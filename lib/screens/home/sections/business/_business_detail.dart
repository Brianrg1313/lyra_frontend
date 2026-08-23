import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';
import 'package:app/services/business/business_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/business_listener.dart';
import 'package:app/screens/home/sections/section_message.dart';

import 'business_tab.dart';
import 'detail_header.dart';

/// La empresa: es el contenido de la seccion `business` del home.
///
/// No hay un listado por delante. Todo lo que se ve dentro del home es de una
/// empresa —la que dice el selector del header—, asi que la seccion de empresas
/// muestra **esa**: entrar a ella es abrir la empresa con la que se esta
/// trabajando, no elegir cual mirar. Para cambiarla esta el selector, que se ve
/// desde todas las secciones.
///
/// Lo que hay de la empresa esta repartido en pestanas (ver [BusinessTab]) y
/// **cada pestana es una URL** (`/home/business/:id/statistics`): se copia el
/// link de lo que se esta mirando y se abre ahi mismo. Cual esta abierta no es
/// estado de esta pantalla sino la ruta activa; por eso cambiar de pestana es
/// navegar y no un `setState`, y el boton de atras del navegador vuelve a la
/// pestana anterior.
///
/// La pagina esta partida en dos: la barra de pestanas apoyada sobre el fondo,
/// y el cuerpo, que es **la unica superficie**. Las pestanas no son cinco
/// tarjetas una al lado de la otra: son cinco caras de la misma hoja, y esa
/// hoja es el cuerpo. Por eso ninguna trae su propia superficie y la pestana
/// activa se dibuja con el color de la del cuerpo, como una lengueta.
///
/// Cual empresa se resuelve del id en la URL, no por constructor: la pantalla
/// comparte el shell del home, que reusa una sola pagina del `Navigator` y no
/// reconstruye el arbol al navegar. Sin id —la seccion pelada,
/// `/home/business`, que es a donde lleva el side bar— es la activa.
///
/// El detalle lo contesta `GET /business/profile/`, que **no recibe un id**:
/// contesta por la empresa de la cabecera `business_id`, o sea la activa. Eso
/// no es una limitacion del endpoint sino como esta pensado el acceso: leer una
/// empresa no es pedirla por id, es tenerla y elegirla. Asi que entrar por el
/// link de una empresa que no es la activa **la activa** (ver [_sync]); el
/// shell vuelve a montar el contenido con la empresa nueva y esta pantalla, ya
/// alineada, pide el perfil.
class BusinessDetailSection extends StatefulWidget {
  const BusinessDetailSection({super.key});

  /// Key de la ruta de la empresa sin pestana (`/home/business/:id`). Es la
  /// unica fuente: la usan tanto la tabla de rutas como el shell.
  ///
  /// Es el link de una empresa "a secas", el que ya andaba dando vueltas antes
  /// de que las pestanas tuvieran URL propia: abre la que diga
  /// [BusinessTab.initial]. Cada pestana tiene la suya (ver
  /// [BusinessTab.routeKey]).
  static const String routeKey = "business_detail";

  @override
  State<BusinessDetailSection> createState() => _BusinessDetailSectionState();
}

class _BusinessDetailSectionState extends State<BusinessDetailSection>
    with BusinessListener<BusinessDetailSection> {
  @override
  void initState() {
    super.initState();

    // Se difiere al primer frame porque las dos ramas de [_sync] notifican al
    // servicio, y notificar mientras el arbol se esta montando es un rebuild en
    // pleno build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sync();
    });
  }

  /// Deja la empresa de la URL como la activa y pide su perfil.
  ///
  /// Son los dos caminos por los que se llega aca: por el link de una empresa
  /// que no es la activa, y a la que ya lo es (entre ellos, la seccion pelada,
  /// que es la activa por definicion). En el primer caso solo se la elige y no
  /// se pide nada: elegirla vuelve a montar el contenido del home —el shell lo
  /// identifica por la empresa— y esta pantalla se monta de nuevo, ya por el
  /// segundo camino.
  ///
  /// El perfil se pide aca y no en la pestana de ajustes porque es la otra
  /// mitad de lo mismo: alinear la empresa activa con la de la URL y traer lo
  /// que hay de ella. Partirlo dejaria la pestana pidiendo el detalle de una
  /// empresa que esta pantalla todavia esta terminando de elegir.
  ///
  /// Un id que el cliente no tiene lo ignora [BusinessService.selectBusiness],
  /// y entonces no hay nada que pedir: el cuerpo muestra que esa empresa no
  /// esta en su lista.
  void _sync() {
    final service = context.read<BusinessService>();
    final id = _businessId(service);

    if (service.activeId != id) {
      service.selectBusiness(id);
      return;
    }

    service.loadProfile();
  }

  /// Esta pantalla muestra la empresa que dice la URL. Elegir otra en el
  /// selector es pedir ver **esa**, asi que se abre su link, lo que ademas deja
  /// la URL coherente con la empresa que se esta mirando. Se abre en la misma
  /// pestana: cambiar de empresa no es cambiar de tema.
  ///
  /// Cuando el cambio de empresa lo disparo [_sync], la URL ya nombra a la
  /// nueva y no hay a donde ir: navegar de nuevo apilaria la misma pagina.
  @override
  void onBusinessChanged(String businessId) {
    if (_urlId == businessId) return;

    Navis.push(context, _tab.path(businessId));
  }

  /// Empresa que nombra la URL, o `null` si es la seccion pelada.
  String? get _urlId => Navis.currentArgs?["id"];

  /// Empresa que se esta mirando: la de la URL, y sin ella la activa.
  String _businessId(BusinessService service) =>
    _urlId ?? service.activeId ?? "";

  /// Pestana abierta, que es la pantalla activa: cada pestana es una ruta. El
  /// link de una empresa sin pestana abre la inicial.
  BusinessTab get _tab =>
    BusinessTab.byRouteKey(Navis.currentKey.value) ?? BusinessTab.initial;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<BusinessService>();
    final id = _businessId(service);

    // La coleccion de `/init` ya tiene todas las empresas del cliente, asi que
    // alcanza para saber si el id es de una suya sin esperar al perfil.
    final business = service.byId(id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BusinessDetailHeader(tab: _tab, onTab: _openTab),
        SizedBox(height: AppSize.gap),
        Expanded(child: Surface(
          padding: EdgeInsets.all(AppSize.padding),
          child: _body(context, service, id, business)
        ))
      ]);
  }

  /// Abre otra pestana de la misma empresa.
  ///
  /// Es una navegacion y no un `setState` porque la pestana abierta es la URL:
  /// asi el link de la barra del navegador es el de lo que se esta mirando, y
  /// el boton de atras vuelve a la pestana anterior. La pagina no se monta de
  /// nuevo —todas las pestanas son la misma pantalla del shell—, solo cambia el
  /// cuerpo.
  void _openTab(BusinessTab tab) {
    if (tab == _tab) return;

    Navis.push(context, tab.path(_businessId(context.read<BusinessService>())));
  }

  /// El cuerpo es de la pestana abierta, pero antes hay dos estados que son de
  /// la pagina entera —la empresa no es del cliente, o todavia se la esta
  /// activando— y en los que ninguna pestana tiene nada que mostrar.
  Widget _body(
    BuildContext context,
    BusinessService service,
    String id,
    BusinessModel? business
  ) {
    // El id no es de ninguna empresa del cliente: ni existe, ni le dieron
    // acceso, ni se la dejo de dar. Solo se llega por un link ajeno o viejo,
    // asi que la salida es la empresa con la que se venia trabajando.
    if (business == null) {
      return SectionMessage(
        icon: CI.info,
        title: S.of(context).business_profile_not_found_title,
        subtitle: S.of(context).business_profile_not_found_subtitle,
        action: service.activeId != null ? _openActive : null,
        actionLabel: S.of(context).business_profile_active
      );
    }

    // Se la esta activando: lo que hay cargado (si hay) es de la empresa
    // anterior, asi que no se muestra nada hasta que el shell vuelva a montar
    // esta pantalla con la empresa nueva.
    if (service.activeId != id) return const Center(child: Loading());

    return _tab.build();
  }

  /// Vuelve a la empresa activa. Se va a la seccion pelada y no a su link con
  /// id porque son lo mismo —la seccion es la empresa activa— y ahi el id no
  /// puede quedar viejo.
  void _openActive() => Navis.push(context, "/home/business");
}
