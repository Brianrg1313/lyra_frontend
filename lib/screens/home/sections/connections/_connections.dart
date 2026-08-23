import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/home/home_service.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/services/connections/connection_catalog_service.dart';
import 'package:app/services/connections/connection_lite_model.dart';
import 'package:app/services/connections/connections_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/home/sections/section_message.dart';

import 'connection_row.dart';

/// Conexiones: es el contenido de la seccion `connections` del home.
///
/// Una conexion es **una cuenta de un servicio de afuera** —un numero de
/// WhatsApp, una pagina de Facebook, un perfil de Instagram— autenticada contra
/// la plataforma. Aca se registra esa cuenta y se cargan sus credenciales, y eso
/// es todo lo que se decide: la cuenta no atiende nada por si sola.
///
/// Lo que la cuenta contesta —los mensajes directos, los comentarios de una
/// publicacion, los de un anuncio— es un bot por trabajo sobre esta misma
/// conexion, y se arma en otra parte. Es la razon de que las dos cosas esten
/// separadas: un login de Instagram alcanza para cuatro trabajos sin necesitar
/// tres tokens mas, y cada uno de esos puede querer otra persona, otros datos y
/// otras herramientas.
///
/// La pantalla es un listado a lo ancho, con la misma forma que las tablas de
/// productos: la barra con el titulo y la accion arriba, y las filas debajo. No
/// es un panel angosto como el de los canales porque no hay nada al lado: de una
/// cuenta se lee de que servicio es, como se llama, si esta lista y cuanto esta
/// corriendo encima, y todo eso entra en un renglon.
///
/// Esta cortada en tres para que cada parte se repinte por su cuenta: la barra de
/// arriba no escucha nada y se dibuja una sola vez, el cuerpo escucha al servicio
/// (que es lo que cambia al cargar) y el listado escucha solo lo que se escribio
/// en el buscador. Por eso el texto de busqueda llega como [ValueListenable] y no
/// como estado de la pantalla: con `setState` cada letra volveria a construir
/// tambien la barra y su boton.
class ConnectionsSection extends StatefulWidget {
  const ConnectionsSection({super.key});

  @override
  State<ConnectionsSection> createState() => _ConnectionsSectionState();
}

class _ConnectionsSectionState extends State<ConnectionsSection> {
  /// Lo que se escribio en el buscador del header, ya normalizado. La seccion no
  /// tiene el suyo: la barra de arriba es la misma para todas y busca sobre la
  /// que se este mirando. Solo lo escucha el listado.
  late final ValueListenable<String> _query;

  @override
  void initState() {
    super.initState();
    _query = context.read<HomeService>().searchQuery;

    // Las cargas notifican a sus oyentes; se difieren al primer frame para no
    // disparar un rebuild mientras el arbol todavia se esta montando.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _load();

      // El catalogo se pide desde aca aunque quien lo dibuja sea el formulario:
      // el listado necesita el nombre y el icono de cada servicio para pintar sus
      // filas, y ademas asi ya esta cuando se toque "conectar cuenta".
      context.read<ConnectionCatalogService>().load();
    });
  }

  /// Pide las conexiones de la empresa activa. El servicio cachea por empresa,
  /// asi que esta llamada no vuelve a pegarle al backend si ya estan cargadas.
  void _load({bool force = false}) => context.read<ConnectionsService>().load(
    context.read<BusinessService>().active.id,
    force: force
  );

  @override
  Widget build(BuildContext context) => Surface(
    padding: EdgeInsets.all(AppSize.padding / 2),
    child: Column(children: [
      Row(children: [
        Expanded(child: TextMedium(
          S.of(context).connections,
          bold: true,
          ellipsis: true
        )),
        SizedBox(width: AppSize.gap),
        Button(
          width: null,
          title: S.of(context).create_connection,
          leftIcon: Icon(CI.plus, color: ThemeColor.of(context).button.text),
          action: _create
        )
      ]),
      Separator.horizontal(
        margin: EdgeInsets.symmetric(vertical: AppSize.spaceXS)
      ),
      Expanded(child: _Body(
        query: _query,
        onCreate: _create,
        onRetry: () => _load(force: true)
      ))
    ])
  );

  /// Abre la pagina de alta. Es una sub-pagina y no un modal: el formulario es un
  /// puñado de credenciales que se copian y pegan desde la consola del servicio,
  /// en otra ventana, y un modal se cierra de un clic afuera.
  void _create() => Navis.push(context, "/home/connections/new");
}

/// El cuerpo del listado: lo unico que escucha a [ConnectionsService], asi que
/// cargar, fallar o traer las cuentas no vuelve a construir la barra de arriba.
class _Body extends StatelessWidget {
  const _Body({
    required this.query,
    required this.onCreate,
    required this.onRetry
  });

  final ValueListenable<String> query;
  final void Function() onCreate;
  final void Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ConnectionsService>();

    return switch (service.status) {
      ConnectionsStatus.loading || ConnectionsStatus.idle =>
        const Center(child: Loading()),
      ConnectionsStatus.error => SectionMessage(
        icon: CI.info,
        title: S.of(context).connections_error_title,
        subtitle: S.of(context).connections_error_subtitle,
        action: onRetry,
        actionLabel: S.of(context).connections_retry
      ),
      ConnectionsStatus.empty => SectionMessage(
        icon: CI.cloud_disconected,
        title: S.of(context).connections_empty_title,
        subtitle: S.of(context).connections_empty_subtitle,
        action: onCreate,
        actionLabel: S.of(context).create_connection,
        actionIcon: CI.plus
      ),
      ConnectionsStatus.ready => _List(
        connections: service.connections,
        query: query
      )
    };
  }
}

/// El listado filtrado. Escucha solo el buscador: escribir en el no toca ni la
/// barra ni el servicio, solo vuelve a filtrar estas filas.
///
/// El filtro mira el nombre y la descripcion: una cuenta se busca por como la
/// llamo la empresa ("Cuenta principal"), que es lo que se recuerda, y no por el
/// codigo del servicio.
class _List extends StatelessWidget {
  const _List({required this.connections, required this.query});

  final List<ConnectionLiteModel> connections;
  final ValueListenable<String> query;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
    valueListenable: query,
    builder: (context, value, _) {
      final filtered = value.isEmpty
        ? connections
        : connections.where((connection) =>
            connection.name.toLowerCase().contains(value) ||
            connection.description.toLowerCase().contains(value)
          ).toList();

      if (filtered.isEmpty) {
        return SectionMessage(
          icon: CI.search,
          title: S.of(context).connections_search_empty
        );
      }

      return ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: filtered.length,
        separatorBuilder: (_, _) => SizedBox(height: AppSize.gap),
        itemBuilder: (context, index) => ConnectionListRow(
          connection: filtered[index]
        )
      );
    }
  );
}
