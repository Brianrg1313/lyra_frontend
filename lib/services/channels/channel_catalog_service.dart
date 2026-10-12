import 'package:flutter/foundation.dart';

import 'package:app/services/channels/channel_provider_model.dart';
import 'package:app/toolkit/api.dart';

/// Status of the catalog read (`GET /channels/providers`).
enum ChannelCatalogStatus { idle, loading, ready, error }

/// Catalog of networks to which a channel can connect, and —the important
/// part— **which values each one needs**: tokens, app secrets, account ids,
/// webhook verification tokens.
///
/// A channel's form is drawn entirely from here: no network is written in this
/// app, so one that is added on the backend side shows up on its own, with its
/// fields and its hints on where to find them. The only thing the front does
/// decide is which ones can already be configured
/// ([ChannelProviderModel.supported]); the rest are shown disabled.
///
/// It is public configuration and not a company's data: it brings nobody's
/// credentials and is read the same for everyone. That is why **it is cached
/// once for the whole session** and not per company, unlike [ChannelsService]:
/// changing company does not change which fields WhatsApp asks for.
class ChannelCatalogService extends ChangeNotifier {
  ChannelCatalogStatus _status = ChannelCatalogStatus.idle;
  List<ChannelProviderModel> _providers = const [];

  ChannelCatalogStatus get status => _status;

  /// The whole catalog, in the order the backend sends it.
  List<ChannelProviderModel> get providers => List.unmodifiable(_providers);

  /// The ones this app already knows how to configure, first, and the ones it
  /// does not yet, later. It is the order in which the selector shows them:
  /// what can be chosen cannot end up below what cannot.
  List<ChannelProviderModel> get sorted => [
    for (final provider in _providers) if (provider.isSupported) provider,
    for (final provider in _providers) if (!provider.isSupported) provider
  ];

  /// The provider with that code, or `null` if the catalog has not loaded yet
  /// or does not have it.
  ///
  /// WhatsApp Personal ([ChannelProviderModel.whatsappPersonalCode]) is
  /// answered here too, even though it never comes from the backend catalog
  /// — see the field's own doc. Every caller that resolves "the schema for
  /// this provider code" goes through this method, so handling it once here
  /// is what lets the form, the card and the picker treat it like any other
  /// provider without each one special-casing it separately.
  ChannelProviderModel? byCode(String code) {
    if (code == ChannelProviderModel.whatsappPersonalCode) {
      return ChannelProviderModel.whatsappPersonal();
    }

    for (final provider in _providers) {
      if (provider.provider == code) return provider;
    }
    return null;
  }

  /// Loads the catalog if needed.
  ///
  /// Once read it is not requested again unless [force]: it is a backend
  /// constant, not data that changes while someone configures a channel.
  Future<void> load({bool force = false}) async {
    if (_status == ChannelCatalogStatus.loading) return;
    if (!force && _status == ChannelCatalogStatus.ready) return;

    _status = ChannelCatalogStatus.loading;
    notifyListeners();

    final data = await api
      .get(path: "/channels/providers/", version: "v1")
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

    // An empty catalog is not a loaded catalog: without providers not even a
    // channel can be created, so it is treated as an error and the screen
    // offers to retry instead of showing a blank selector.
    _status = _providers.isEmpty
      ? ChannelCatalogStatus.error
      : ChannelCatalogStatus.ready;

    notifyListeners();
  }

  /// Puts [providers] in as a loaded catalog, without the network. A seam for tests.
  @visibleForTesting
  void seed(List<ChannelProviderModel> providers) {
    _providers = providers;
    _status = ChannelCatalogStatus.ready;
    notifyListeners();
  }

  /// Empties the cache. For signing out, together with the rest of the services.
  void clear() {
    _providers = const [];
    _status = ChannelCatalogStatus.idle;
    notifyListeners();
  }
}
