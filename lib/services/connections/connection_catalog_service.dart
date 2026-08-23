import 'package:flutter/foundation.dart';

import 'package:app/services/connections/connection_provider_model.dart';
import 'package:app/toolkit/api.dart';

/// Estado de la lectura del catalogo (`GET /connections/providers`).
enum ConnectionCatalogStatus { idle, loading, ready, error }

/// Catalogo de servicios a los que se les puede conectar una cuenta y —lo
/// importante— **que valores necesita cada uno**: tokens, secretos de app, ids de
/// cuenta, tokens de verificacion del webhook.
///
/// El formulario de una conexion se dibuja entero desde aca: ningun servicio esta
/// escrito en esta app, asi que uno que se agregue del lado del backend aparece
/// solo, con sus campos y sus pistas de donde encontrarlos. Lo unico que si
/// decide el front es cuales ya se pueden configurar
/// ([ConnectionProviderModel.supported]); el resto se muestra apagado.
///
/// Trae ademas los `scopes` de cada servicio: a que se puede poner a trabajar la
/// cuenta una vez conectada, que es tambien cuantos bots puede alimentar. Aca no
/// se elige ninguno —eso es de los bots— pero se muestra, porque es la diferencia
/// entre dos entradas parecidas: una pagina de Facebook contesta comentarios y
/// Messenger contesta mensajes, con credenciales distintas.
///
/// Es configuracion publica y no datos de una empresa: no trae credenciales de
/// nadie y se lee igual para todos. Por eso **se cachea una sola vez para toda la
/// sesion** y no por empresa, a diferencia de [ConnectionsService]: cambiar de
/// empresa no cambia que campos pide WhatsApp.
class ConnectionCatalogService extends ChangeNotifier {
  ConnectionCatalogStatus _status = ConnectionCatalogStatus.idle;
  List<ConnectionProviderModel> _providers = const [];

  ConnectionCatalogStatus get status => _status;

  /// El catalogo entero, en el orden que lo manda el backend.
  List<ConnectionProviderModel> get providers => List.unmodifiable(_providers);

  /// Los que esta app ya sabe configurar, primero, y los que todavia no,
  /// despues. Es el orden en que el selector los muestra: lo que se puede elegir
  /// no puede quedar debajo de lo que no.
  List<ConnectionProviderModel> get sorted => [
    for (final provider in _providers) if (provider.isSupported) provider,
    for (final provider in _providers) if (!provider.isSupported) provider
  ];

  /// El proveedor con ese codigo, o `null` si el catalogo todavia no cargo o no
  /// lo tiene.
  ConnectionProviderModel? byCode(String code) {
    for (final provider in _providers) {
      if (provider.provider == code) return provider;
    }
    return null;
  }

  /// Carga el catalogo si hace falta.
  ///
  /// Una vez leido no se vuelve a pedir salvo [force]: es una constante del
  /// backend, no un dato que cambie mientras alguien configura una cuenta.
  Future<void> load({bool force = false}) async {
    if (_status == ConnectionCatalogStatus.loading) return;
    if (!force && _status == ConnectionCatalogStatus.ready) return;

    _status = ConnectionCatalogStatus.loading;
    notifyListeners();

    final data = await api
      .get(path: "/connections/providers/", version: "v1")
      .catchError((error) {
        if (kDebugMode) print("loadConnectionProviders failed: $error");
        return null;
      });

    if (data == null) {
      _status = ConnectionCatalogStatus.error;
      notifyListeners();
      return;
    }

    _providers = ConnectionProviderModel.fromResponse(data);

    // Un catalogo vacio no es un catalogo cargado: sin proveedores no se puede
    // conectar ni una cuenta, asi que se trata como error y la pantalla ofrece
    // reintentar en vez de mostrar un selector en blanco.
    _status = _providers.isEmpty
      ? ConnectionCatalogStatus.error
      : ConnectionCatalogStatus.ready;

    notifyListeners();
  }

  /// Vacia la cache. Para el cierre de sesion, junto al resto de los servicios.
  void clear() {
    _providers = const [];
    _status = ConnectionCatalogStatus.idle;
    notifyListeners();
  }
}
