import 'package:flutter/foundation.dart';

import 'package:app/services/channels/channel_provider_model.dart';
import 'package:app/toolkit/api.dart';

/// Estado de la lectura del catalogo (`GET /channels/set_up/providers`).
enum ChannelCatalogStatus { idle, loading, ready, error }

/// Catalogo de redes a las que se puede conectar un canal, y —lo importante—
/// **que valores necesita cada una**: tokens, secretos de app, ids de cuenta,
/// tokens de verificacion del webhook.
///
/// El formulario de un canal se dibuja entero desde aca: ninguna red esta
/// escrita en esta app, asi que una que se agregue del lado del backend aparece
/// sola, con sus campos y sus pistas de donde encontrarlos. Lo unico que si
/// decide el front es cuales ya se pueden configurar
/// ([ChannelProviderModel.supported]); el resto se muestra apagado.
///
/// Es configuracion publica y no datos de una empresa: no trae credenciales de
/// nadie y se lee igual para todos. Por eso **se cachea una sola vez para toda
/// la sesion** y no por empresa, a diferencia de [ChannelsService]: cambiar de
/// empresa no cambia que campos pide WhatsApp.
class ChannelCatalogService extends ChangeNotifier {
  ChannelCatalogStatus _status = ChannelCatalogStatus.idle;
  List<ChannelProviderModel> _providers = const [];

  ChannelCatalogStatus get status => _status;

  /// El catalogo entero, en el orden que lo manda el backend.
  List<ChannelProviderModel> get providers => List.unmodifiable(_providers);

  /// Los que esta app ya sabe configurar, primero, y los que todavia no,
  /// despues. Es el orden en que el selector los muestra: lo que se puede
  /// elegir no puede quedar debajo de lo que no.
  List<ChannelProviderModel> get sorted => [
    for (final provider in _providers) if (provider.isSupported) provider,
    for (final provider in _providers) if (!provider.isSupported) provider
  ];

  /// El proveedor con ese codigo, o `null` si el catalogo todavia no cargo o no
  /// lo tiene.
  ChannelProviderModel? byCode(String code) {
    for (final provider in _providers) {
      if (provider.provider == code) return provider;
    }
    return null;
  }

  /// Carga el catalogo si hace falta.
  ///
  /// Una vez leido no se vuelve a pedir salvo [force]: es una constante del
  /// backend, no un dato que cambie mientras alguien configura un canal.
  Future<void> load({bool force = false}) async {
    if (_status == ChannelCatalogStatus.loading) return;
    if (!force && _status == ChannelCatalogStatus.ready) return;

    _status = ChannelCatalogStatus.loading;
    notifyListeners();

    final data = await api
      .get(path: "/channels/set_up/providers/", version: "v1")
      .catchError((error) {
        if (kDebugMode) print("loadChannelProviders failed: $error");
        return null;
      });

    if (data == null) {
      _status = ChannelCatalogStatus.error;
      notifyListeners();
      return;
    }

    _providers = ChannelProviderModel.fromResponse(data);

    // Un catalogo vacio no es un catalogo cargado: sin proveedores no se puede
    // crear ni un canal, asi que se trata como error y la pantalla ofrece
    // reintentar en vez de mostrar un selector en blanco.
    _status = _providers.isEmpty
      ? ChannelCatalogStatus.error
      : ChannelCatalogStatus.ready;

    notifyListeners();
  }

  /// Vacia la cache. Para el cierre de sesion, junto al resto de los servicios.
  void clear() {
    _providers = const [];
    _status = ChannelCatalogStatus.idle;
    notifyListeners();
  }
}
