import 'package:core/api.dart';

// SERVICES
import 'package:app/services/database/database_service.dart';

// WIDGETS
export 'package:core/float_flag/controller.dart';


final api = _Api();
final assets = _Assets();

/// Deja la empresa activa en las dos apis, o la saca al cerrar sesion.
///
/// Lo llama `BusinessService` cada vez que cambia la empresa activa: es lo
/// unico que hay que tocar para que todas las peticiones queden apuntando a la
/// empresa correcta, sin que cada endpoint tenga que acordarse de mandarla.
void useBusiness(String? id) {
  api.business = id;
  assets.business = id;
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
    host: "192.168.1.101",
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
    host: "192.168.1.101",
    name: "cetus",
    port: 81,
    scheme: "http",
    type: ApiMode.assets,
    tokenName: "Authorization"
  );

  @override
  ApiModel get prod => dev;
}
