import 'package:flutter/foundation.dart';
import 'package:core/navis/navis.dart';
import 'package:app/services/client/client_model.dart';
import 'package:app/toolkit/api.dart';

// SERVICES
import 'package:app/services/database/database_service.dart';
import 'package:app/toolkit/settings/initial_builder.dart' show businessService;

/// Estado del cliente autenticado.
///
/// La instancia se crea en `initialBuilder` y se registra ahi con
/// `ChangeNotifierProvider.value`, en el scope mas alto de la app, porque su
/// estado debe sobrevivir a la navegacion entre secciones.

/// La sesion se resuelve en [resolve] antes de levantar el arbol, desde
/// `initialValidator`. Para cuando el provider expone esta instancia el cliente
/// ya esta cargado y ningun widget tiene que esperar a un future.
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
      // en el proximo arranque en frio (que volveria a fallar con 401).
      api.token = null;
      await _database.deleteSecure(api.current.tokenName);
      return page;
    }

    if (clientData == null) {
      return "/login";
    }

    // La coleccion de empresas la administra BusinessService; aqui solo se le
    // entrega el bloque que trajo la sesion.
    businessService.seed(clientData["businesses"]);

    update(ClientModel.fromJson(clientData));
    return null;
  }

  void update(ClientModel value) {
    _client = value;
    notifyListeners();
  }

  void clear() {
    _client = null;
    notifyListeners();
  }

  String get email => client.email;
  String? get picture => client.picture;
  String get username => client.username;
  String get fullName => client.fullName;
}
