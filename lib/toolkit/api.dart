import 'package:core/api.dart';

// SERVICES
import 'package:app/toolkit/sockets.dart';
import 'package:app/services/database/database_service.dart';

// WIDGETS
export 'package:core/float_flag/controller.dart';


final api = _Api();
final assets = _Assets();

/// Donde vive la api: esquema, host y puerto, sin ruta.
///
/// Es lo que hace falta para completar una direccion que el backend manda
/// relativa. La unica que manda asi hoy son las bases de las imagenes (ver
/// `CdnService`): del lado del servidor `/rigel/media` es una direccion valida
/// —el navegador la resuelve contra la pagina que la trajo—, pero esto no es
/// una pagina y no tiene contra que resolverla.
///
/// El puerto se omite cuando es el que ya implica el esquema, que es lo que
/// hace cualquiera que escriba una URL a mano.
String get apiOrigin {
  final port = api.port;
  final implied =
    (api.scheme == "http" && port == 80) ||
    (api.scheme == "https" && port == 443);

  return "${api.scheme}://${api.host}${implied ? "" : ":$port"}";
}

/// Deja la empresa activa en las dos apis y en el socket, o la saca al cerrar
/// sesion.
///
/// Lo llama `BusinessService` cada vez que cambia la empresa activa: es lo
/// unico que hay que tocar para que todas las peticiones queden apuntando a la
/// empresa correcta, sin que cada endpoint tenga que acordarse de mandarla.
///
/// El socket es la excepcion a ese "queda apuntando": su handshake ya se hizo,
/// asi que la empresa nueva recien viaja en la proxima reconexion. Si los
/// eventos que se estan escuchando son de la empresa activa hay que forzarla
/// con `ConnectionService().refresh()`.
void useBusiness(String? id) {
  api.business = id;
  assets.business = id;
  sockets.business = id;
}

/// Base de las apis de la app: token de sesion y empresa activa viajan igual en
/// todas, asi que el manejo vive una sola vez aca.
abstract class _SessionApi extends RestAPI {
  final _database = DatabaseService();

  /// Empresa a la que pertenece lo que se pide. Se manda en la cabecera
  /// `business_id` y no en el cuerpo porque no es un dato del alta sino el
  /// contexto de la sesion: el cliente puede tener varias empresas y todas
  /// comparten los endpoints.
  ///
  /// Nulo mientras no haya ninguna elegida (sesion recien abierta sin empresas,
  /// o despues de cerrar sesion), y en ese caso la cabecera no viaja.
  String? business;

  @override
  Headers get extraHeaders => {"business_id": ?business};

  @override
  Future<void> preRequest() async {
    if (token == null) {
      final t = await _database.fromSecure<String>(current.tokenName);
      if (t != null) {
        token = t;
        headers[current.tokenName] = token!;
      }
    }
  }
}

class _Api extends _SessionApi {
  @override
  ApiModel get dev => ApiModel(
    host: "192.168.1.103",
    name: "lyra",
    port: 80,
    scheme: "http",
    tokenName: "Authorization"
  );

  @override
  ApiModel get prod => dev;
}

class _Assets extends _SessionApi {
  @override
  ApiModel get dev => ApiModel(
    host: "192.168.1.103",
    name: "cetus",
    port: 81,
    scheme: "http",
    type: ApiMode.assets,
    tokenName: "Authorization"
  );

  @override
  ApiModel get prod => dev;
}
