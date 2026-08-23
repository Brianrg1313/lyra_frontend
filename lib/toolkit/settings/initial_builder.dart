import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/home/home_service.dart';
import 'package:app/services/client/client_service.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/services/connection/connection_service.dart';
import 'package:app/services/catalog/country_catalog_service.dart';
import 'package:app/services/catalog/currency_catalog_service.dart';
import 'package:app/services/files/cdn_service.dart';
import 'package:app/services/channels/channel_catalog_service.dart';
import 'package:app/services/channels/channels_service.dart';
import 'package:app/services/connections/connection_catalog_service.dart';
import 'package:app/services/connections/connections_service.dart';
import 'package:app/services/stock/tables/tables_service.dart';

/// Instancia unica del cliente.
///
/// Vive aca y no dentro del provider porque `initialValidator` corre fuera del
/// arbol de widgets, sin BuildContext, y necesita cargar la sesion sobre la
/// misma instancia que despues consumen las pantallas.
final clientService = ClientService();

/// Instancia unica de las empresas.
///
/// Vive junto al cliente y por el mismo motivo: `ClientService.resolve` la puebla
/// desde `/init` antes de levantar el arbol, sobre la misma instancia que
/// consumen el selector del side bar y la seccion de empresas.
final businessService = BusinessService();

// Wraps the whole app before it is handed to MaterialApp.
//
// Only services whose state must outlive navigation belong here. Flow scoped
// services (sign in / sign up) are provided by their own screens so the app
// does not register them while those flows are not in use.
Widget initialBuilder(Widget app) => MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => HomeService()),
    // `.value` porque el ciclo de vida de la instancia es de este archivo, no
    // del provider: no debe destruirse si el arbol se re-monta.
    ChangeNotifierProvider.value(value: clientService),
    ChangeNotifierProvider.value(value: businessService),
    // Tambien `.value`, y por un motivo mas fuerte: es un singleton y su
    // ciclo de vida es el de la conexion, no el del arbol. Se registra solo
    // para poder observar el estado con `context.watch`.
    ChangeNotifierProvider.value(value: ConnectionService()),
    // Los catalogos de plataforma: en que paises se opera y en que monedas se
    // puede cobrar, con como se escribe cada importe. Tambien `.value` y por lo
    // mismo que la conexion: son singletons que `ClientService.resolve` puebla
    // desde `/init` antes de que exista el arbol, y se registran solo para que
    // los formularios puedan observarlos con `context.watch` —lo que hace que
    // una region habilitada hoy aparezca sin publicar una version nueva—.
    ChangeNotifierProvider.value(value: CountryCatalogService()),
    ChangeNotifierProvider.value(value: CurrencyCatalogService()),
    // Y de donde se bajan las imagenes, que llega en la misma respuesta y por
    // el mismo motivo: ninguna respuesta trae direcciones de imagen, trae ids,
    // y la direccion es configuracion del backend. Mudarlas a un CDN no es una
    // version nueva de la app.
    ChangeNotifierProvider.value(value: CdnService()),
    // El estado (la cache del listado) debe sobrevivir a la navegacion entre el
    // listado de tablas y la pantalla de creacion, asi que vive en el scope de
    // la app y no en la seccion.
    ChangeNotifierProvider(create: (_) => TablesService()),
    // Por lo mismo que las tablas: la cache del listado tiene que sobrevivir a
    // la navegacion entre el listado de canales y el formulario de uno.
    ChangeNotifierProvider(create: (_) => ChannelsService()),
    // El catalogo de proveedores no es de una empresa ni de una pantalla: es
    // configuracion publica que se lee una vez por sesion y la consumen tanto
    // el listado (para el nombre y el icono de cada red) como el formulario
    // (que se dibuja entero a partir de el).
    ChangeNotifierProvider(create: (_) => ChannelCatalogService()),
    // Las conexiones (las cuentas de servicios de afuera) siguen el mismo par que
    // los canales, y por los mismos motivos: la cache del listado tiene que
    // sobrevivir a la navegacion entre el listado y el formulario de una cuenta...
    ChangeNotifierProvider(create: (_) => ConnectionsService()),
    // ...y el catalogo de proveedores es configuracion publica que se lee una vez
    // por sesion, no datos de una empresa. Es otro catalogo y no el de los
    // canales porque describe otra cosa: que valores pide cada servicio para
    // conectar una cuenta, y a que trabajos se la puede poner despues.
    ChangeNotifierProvider(create: (_) => ConnectionCatalogService())
  ],
  child: app
);
