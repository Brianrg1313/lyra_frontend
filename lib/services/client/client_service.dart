import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:core/navis/navis.dart';
import 'package:app/services/client/client_model.dart';
import 'package:app/toolkit/api.dart';

// SERVICES
import 'package:app/services/database/database_service.dart';
import 'package:app/services/connection/connection_service.dart';
import 'package:app/services/catalog/country_catalog_service.dart';
import 'package:app/services/catalog/currency_catalog_service.dart';
import 'package:app/services/files/cdn_service.dart';
import 'package:app/toolkit/settings/initial_builder.dart' show businessService;

/// Estado del cliente autenticado.
///
/// La instancia se crea en `initialBuilder` y se registra ahi con
/// `ChangeNotifierProvider.value`, en el scope mas alto de la app, porque su
/// estado debe sobrevivir a la navegacion entre secciones.

/// La sesion se resuelve en [resolve] antes de levantar el arbol, desde
/// `initialValidator`. Para cuando el provider expone esta instancia el cliente
/// ya esta cargado y ningun widget tiene que esperar a un future.
///
/// `/init` no trae solo al cliente: trae todo lo que la app necesita antes de
/// dibujar nada —el perfil, las empresas a las que tiene acceso, los catalogos
/// de plataforma (paises y monedas) y de donde se bajan las imagenes—. Este
/// servicio es el unico que lee ese endpoint, asi que es el que reparte cada
/// bloque a quien lo administra: [BusinessService] las empresas,
/// [CountryCatalogService] y [CurrencyCatalogService] los catalogos, y
/// [CdnService] las bases de las imagenes. Aca no se guarda ninguno.
class ClientService extends ChangeNotifier {
  final DatabaseService _database = DatabaseService();

  ClientModel? _client;

  bool get isAuthenticated => _client != null;

  ClientModel get client {
    assert(_client != null, "ClientService leido sin una sesion iniciada");
    return _client!;
  }

  /// Carga el cliente si hay sesion vigente.
  ///
  /// Devuelve la ruta a la que hay que redirigir, o `null` si la sesion es
  /// valida y el cliente quedo cargado.
  Future<String?> resolve() async {
    final hasSession = await _database.hasInSecure(api.current.tokenName);

    if (!hasSession) {
      return "/login";
    }

    String? page;
    final clientData = await api.get(path: "/init/", version: "v1").catchError((E) {
      if (kDebugMode) {
        print(E);
      }
      // El backend manda `action` como identificador del destino (por ejemplo
      // "login" cuando la sesion ya no vale), que coincide con la key de la
      // ruta, no con su URL. Se traduce a la ruta real por su key; si no
      // coincide con ninguna, el login es el destino seguro ante un fallo de
      // sesion. Sin esta traduccion, devolver "login" a secas deja al parser
      // con un path sin coincidencia y la app se queda clavada en el splash.
      final action = E is Map ? E["action"] as String? : null;
      page = (action != null ? Navis.byKey(action)?.url : null) ?? "/login";
      return null;
    });

    if (page != null) {
      // La sesion guardada ya no sirve: se descarta el token para no arrastrar
      // una credencial muerta en las proximas peticiones ni reintentar `/init`
      // en el proximo arranque en frio (que volveria a fallar con 401), y se
      // corta el socket, que se autentica con ese mismo token.
      api.token = null;
      ConnectionService().close();
      await _database.deleteSecure(api.current.tokenName);
      return page;
    }

    if (clientData == null) {
      return "/login";
    }

    // La configuracion de plataforma va primero: es con lo que se leen los
    // datos que vienen despues (en que moneda factura cada empresa, en que pais
    // opera, de donde se baja su logo), asi que para cuando alguien los mire ya
    // tienen con que contestar.
    _seedCatalogs(clientData);

    // La coleccion de empresas la administra BusinessService; aqui solo se le
    // entrega el bloque que trajo la sesion.
    businessService.seed(clientData["businesses"]);

    update(ClientModel.fromJson(clientData));

    // La sesion quedo confirmada por el backend: recien aca el socket tiene
    // credenciales validas que presentar en el handshake. Sin esperarlo, porque
    // esto corre antes de levantar el arbol y la app no tiene por que quedarse
    // en el splash mientras se abre la conexion (ni fallar si no se abre: el
    // cliente reintenta solo y `ConnectionService` no lanza).
    unawaited(ConnectionService().open());

    return null;
  }

  /// Reparte la configuracion de plataforma que vino en `/init`: los dos
  /// catalogos y las bases con las que se arman las direcciones de las
  /// imagenes.
  ///
  /// Cada bloque se entrega solo si llego: una respuesta sin `countries` —un
  /// backend viejo, un despliegue a medias— deja el catalogo como estaba en vez
  /// de vaciarlo, que es lo que dejaria a los formularios sin nada que ofrecer,
  /// y una sin `cdn` deja las imagenes bajandose de donde ya se bajaban.
  void _seedCatalogs(Map clientData) {
    final countries = clientData["countries"];
    final currencies = clientData["currencies"];
    final cdn = clientData["cdn"];

    if (countries != null) CountryCatalogService().seed(countries);
    if (currencies != null) CurrencyCatalogService().seed(currencies);
    if (cdn != null) CdnService().seed(cdn);
  }

  /// Vuelve a leer la configuracion de plataforma con la app andando.
  ///
  /// Nada de esto es de esta app ni de esta sesion: se habilita una region —o
  /// se corrige el simbolo de una moneda, o se muda el CDN— del lado del
  /// backend, y lo que ya
  /// esta abierto tendria que enterarse sin que nadie publique una version nueva
  /// ni cierre sesion. Esto es lo que hace falta para eso: los servicios de
  /// catalogo notifican al recibir lo nuevo, asi que las pantallas montadas se
  /// repintan solas.
  ///
  /// Se relee `/init` entero porque es el endpoint que lo sirve, pero **solo se
  /// vuelve a sembrar esa parte**: el perfil y las empresas ya estan
  /// cargados y tienen quien los mantenga al dia, y volver a sembrarlos aca
  /// reiniciaria la empresa activa a la primera de la lista en medio de lo que
  /// se este haciendo.
  ///
  /// No lanza: que el catalogo no se pueda refrescar no es un error que le
  /// importe a quien esta trabajando —lo que hay sigue sirviendo—, asi que el
  /// fallo se ignora y se reintenta la proxima vez.
  Future<void> refreshCatalogs() async {
    if (!isAuthenticated) return;

    final data = await api.get(path: "/init/", version: "v1").catchError((E) {
      if (kDebugMode) {
        print("refreshCatalogs failed: $E");
      }
      return null;
    });

    if (data is! Map) return;

    _seedCatalogs(data);
  }

  void update(ClientModel value) {
    _client = value;
    notifyListeners();
  }

  void clear() {
    _client = null;
    // Sin sesion no hay nada que escuchar. `close` no suelta los listeners, asi
    // que el proximo inicio de sesion vuelve a recibir los mismos eventos.
    ConnectionService().close();
    notifyListeners();
  }

  String get email => client.email;
  String? get picture => client.picture;
  String get username => client.username;
  String get fullName => client.fullName;
}
