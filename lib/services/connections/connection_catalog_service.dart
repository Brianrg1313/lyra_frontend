import 'package:flutter/foundation.dart';

import 'package:app/services/connections/connection_provider_model.dart';
import 'package:app/toolkit/api.dart';

/// Status of reading the catalog (`GET /connections/providers`).
enum ConnectionCatalogStatus { idle, loading, ready, error }

/// Catalog of services an account can be connected to and — the important
/// part — **what values each one needs**: tokens, app secrets, account ids,
/// webhook verification tokens.
///
/// A connection's form is drawn entirely from here: no service is hardcoded
/// in this app, so one added on the backend side shows up on its own, with
/// its fields and its hints on where to find them. The only thing the front
/// end does decide is which ones can already be configured
/// ([ConnectionProviderModel.supported]); the rest are shown greyed out.
///
/// It also brings each service's `scopes`: what the account can be put to
/// work on once connected, which is also how many bots it can feed. None is
/// chosen here — that's up to the bots — but it's shown, because it's the
/// difference between two similar-looking entries: a Facebook page answers
/// comments and Messenger answers messages, with different credentials.
///
/// It's public configuration, not a business's data: it doesn't carry
/// anyone's credentials and reads the same for everyone. That's why **it's
/// cached only once for the whole session** and not per business, unlike
/// [ConnectionsService]: switching business doesn't change what fields
/// WhatsApp asks for.
class ConnectionCatalogService extends ChangeNotifier {
  ConnectionCatalogStatus _status = ConnectionCatalogStatus.idle;
  List<ConnectionProviderModel> _providers = const [];

  ConnectionCatalogStatus get status => _status;

  /// The entire catalog, in the order the backend sends it.
  List<ConnectionProviderModel> get providers => List.unmodifiable(_providers);

  /// The ones this app already knows how to configure, first, and the ones
  /// it doesn't yet, after. It's the order the selector shows them in: what
  /// can be picked can't end up below what can't.
  List<ConnectionProviderModel> get sorted => [
    for (final provider in _providers) if (provider.isSupported) provider,
    for (final provider in _providers) if (!provider.isSupported) provider
  ];

  /// The provider with that code, or `null` if the catalog hasn't loaded yet
  /// or doesn't have it.
  ConnectionProviderModel? byCode(String code) {
    for (final provider in _providers) {
      if (provider.provider == code) return provider;
    }
    return null;
  }

  /// Loads the catalog if needed.
  ///
  /// Once read, it isn't requested again unless [force]: it's a backend
  /// constant, not data that changes while someone is configuring an
  /// account.
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

    // An empty catalog isn't a loaded catalog: without providers not even
    // one account can be connected, so it's treated as an error and the
    // screen offers a retry instead of showing a blank selector.
    _status = _providers.isEmpty
      ? ConnectionCatalogStatus.error
      : ConnectionCatalogStatus.ready;

    notifyListeners();
  }

  /// Empties the cache. For sign-out, along with the rest of the services.
  void clear() {
    _providers = const [];
    _status = ConnectionCatalogStatus.idle;
    notifyListeners();
  }
}
