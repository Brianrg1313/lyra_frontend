import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/client/client_service.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/services/connection/connection_service.dart';

// WIDGETS
import 'package:app/screens/home/desktop/_body.dart';
import 'package:app/screens/home/header/_header.dart';
import 'package:app/screens/home/sections/_sections.dart';

/// Shell del home. Cada seccion entra por su propia URL (`/home/...`) pero
/// todas comparten esta unica pagina: al cambiar de seccion el arbol se
/// actualiza en vez de recrearse, por lo que el side bar conserva su estado
/// (scroll incluido) y no se apila un shell por seccion visitada.
///
/// Por eso la seccion no llega por constructor: el `Navigator` cachea el widget
/// de la pagina y no lo reconstruye al actualizarla. La fuente es
/// [Navis.currentKey].
class Home extends PageBuilder {
  const Home({super.key});

  /// Identificador del shell compartido por las rutas de las secciones.
  static const String shell = "home";

  /// Este shell contiene a todas las secciones autenticadas, asi que llegar
  /// hasta aca ya implica una sesion valida: es el punto donde tiene sentido
  /// asegurar la conexion.
  ///
  /// Normalmente no hace nada, porque `ClientService.resolve` ya la abrio al
  /// levantar la sesion y [ConnectionService.open] es idempotente. Cubre el
  /// caso contrario: entrar al home por un camino que no paso por `resolve`
  /// (un inicio de sesion dentro de la misma corrida), y volver a levantarla si
  /// se habia cerrado.
  ///
  /// Corre una sola vez por montaje del shell, no en cada cambio de seccion:
  /// todas comparten esta pagina del `Navigator`.
  ///
  /// Se mira el cliente y no la ruta porque lo que autoriza el handshake es la
  /// credencial, no estar parado en `/home`: sin sesion cargada el servidor
  /// rechazaria la conexion y el cliente se quedaria reintentando.
  @override
  void initialized(BuildContext context) {
    if (!context.read<ClientService>().isAuthenticated) return;
    unawaited(ConnectionService().open());
  }

  /// Se escucha la **empresa activa** ademas de la pantalla abierta: todo lo que
  /// vive dentro del home es de una empresa, asi que cambiarla deja vieja a la
  /// seccion que se este mirando. El contenido se identifica con ella
  /// ([homeContent]) y se monta de nuevo, que es lo que hace que cada seccion
  /// vuelva a pedir sus datos de la empresa que se acaba de elegir.
  ///
  /// Se mira solo el identificador y no el servicio entero: el resto de sus
  /// notificaciones (un alta, la carga del detalle de la seccion de empresas) no
  /// tienen por que reconstruir el shell.
  ///
  /// El [HomeHeader] entra por el `child` del builder y no dentro de el: es fijo
  /// como el side bar, asi que se construye una sola vez y cambiar de seccion no
  /// lo vuelve a armar. Es lo que le permite conservar lo que se escribio en el
  /// buscador mientras se navega.
  @override
  Widget build(BuildContext context) {
    final businessId = context.select<BusinessService, String?>(
      (service) => service.activeId
    );

    return ValueListenableBuilder<String>(
      valueListenable: Navis.currentKey,
      child: const HomeHeader(),
      builder: (context, currentKey, header) {
        // Una sub-pagina no es una seccion, pero vive dentro de una: se muestra
        // la seccion que la contiene para que el shell siga siendo coherente.
        final section = HomeSection.byKey(currentKey)
          ?? HomeSection.containing(currentKey)
          ?? HomeSection.dashboard;

        // La seccion resuelta marca la opcion del side bar; el contenido puede
        // ser el de la seccion o el de una sub-pagina suya (p. ej. una pestana
        // de la empresa dentro de `business`).
        final content = homeContent(currentKey, section, businessId);

        return DeviceSelector(
          phone: (context) => _HomeBody(header: header!, content: content),
          desktop: (context) => DesktopBody(
            section: section,
            header: header!,
            content: content
          )
        );
      }
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.header, required this.content});

  /// Barra superior, la misma para todas las secciones.
  final Widget header;

  final Widget content;

  /// La barra va dentro del cuerpo y no en el `header` del skeleton: ese slot
  /// flota por encima del contenido, y aca tiene que ocupar su lugar para que la
  /// seccion empiece debajo. El [SafeArea] es por el mismo motivo de siempre en
  /// telefono: sin el, la barra queda tapada por la del estado.
  @override
  Widget build(BuildContext context) => Skeleton.simple(
    padding: EdgeInsets.all(AppSize.spaceM),
    body: SafeArea(child: Column(children: [
      Padding(
        padding: EdgeInsets.all(AppSize.padding),
        child: header
      ),
      Expanded(child: content)
    ]))
  );
}
