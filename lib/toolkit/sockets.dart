import 'package:core/socket.dart';

// SERVICES
import 'package:app/services/database/database_service.dart';

/// Conexion por socket de la app.
///
/// Es el equivalente en tiempo real de `api`: mismo host y mismo `tokenName`,
/// asi que hereda del registro compartido el token que dejo el login sin que
/// nadie tenga que copiarselo. Quien la maneja es `ConnectionService`, que
/// resuelve el ciclo de vida y expone el estado a la app; esta instancia solo
/// declara contra que se conecta.
final sockets = _Sockets();

class _Sockets extends SocketAPI {
  final _database = DatabaseService();

  /// Empresa a la que pertenece lo que se escucha, con el mismo criterio que en
  /// la api REST: no es un dato del handshake sino el contexto de la sesion. Lo
  /// deja `useBusiness` cada vez que cambia la empresa activa.
  ///
  /// Viaja en [extraAuth] ademas de en la cabecera porque el navegador no deja
  /// mandar cabeceras propias en web, y porque el `auth` se vuelve a leer en
  /// cada reconexion mientras que las cabeceras quedan congeladas.
  String? business;

  @override
  ApiModel get dev => ApiModel(
    host: "192.168.1.103",
    name: "lyra",
    port: 80,
    scheme: "http",
    type: ApiMode.socket,
    tokenName: "Authorization"
  );

  @override
  ApiModel get prod => dev;

  @override
  Headers get extraHeaders => {"business_id": ?business};

  @override
  Map<String, dynamic> get extraAuth => {"business_id": ?business};

  /// Mismo papel que `preRequest` en la api REST: si el token todavia no esta
  /// en memoria (arranque en frio, la sesion se abrio en una corrida anterior)
  /// se recupera del almacenamiento seguro antes del primer handshake.
  @override
  Future<void> preConnect() async {
    token ??= await _database.fromSecure<String>(current.tokenName);
  }
}
