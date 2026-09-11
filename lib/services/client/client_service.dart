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

/// State of the authenticated client.
///
/// The instance is created in `initialBuilder` and registered there with
/// `ChangeNotifierProvider.value`, in the highest scope of the app, because its
/// state must survive navigation between sections.

/// The session is resolved in [resolve] before raising the tree, from
/// `initialValidator`. By the time the provider exposes this instance the client
/// is already loaded and no widget has to wait on a future.
///
/// `/init` does not bring only the client: it brings everything the app needs
/// before drawing anything —the profile, the companies it has access to, the
/// platform catalogs (countries and currencies) and where the images are
/// downloaded from—. This service is the only one that reads that endpoint, so
/// it is the one that hands each block to whoever manages it: [BusinessService]
/// the companies, [CountryCatalogService] and [CurrencyCatalogService] the
/// catalogs, and [CdnService] the image bases. None is stored here.
class ClientService extends ChangeNotifier {
  final DatabaseService _database = DatabaseService();

  ClientModel? _client;

  bool get isAuthenticated => _client != null;

  ClientModel get client {
    assert(_client != null, "ClientService read without a session started");
    return _client!;
  }

  /// Loads the client if there is a valid session.
  ///
  /// Returns the route to redirect to, or `null` if the session is valid and
  /// the client ended up loaded.
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
      // The backend sends `action` as the destination identifier (for example
      // "login" when the session is no longer valid), which matches the route's
      // key, not its URL. It is translated to the real route by its key; if it
      // does not match any, login is the safe destination on a session
      // failure. Without this translation, returning "login" plain leaves the
      // parser with a path with no match and the app stays stuck on the splash.
      final action = E is Map ? E["action"] as String? : null;
      page = (action != null ? Navis.byKey(action)?.url : null) ?? "/login";
      return null;
    });

    if (page != null) {
      // The stored session is no longer useful: the token is discarded so as
      // not to drag a dead credential into the next requests nor retry `/init`
      // on the next cold start (which would fail again with 401), and the
      // socket is cut, which authenticates with that same token.
      api.token = null;
      ConnectionService().close();
      await _database.deleteSecure(api.current.tokenName);
      return page;
    }

    if (clientData == null) {
      return "/login";
    }

    // The platform configuration goes first: it is with it that the data that
    // comes later is read (in which currency each company invoices, in which
    // country it operates, where its logo is downloaded from), so by the time
    // someone looks at them they already have what to answer with.
    _seedCatalogs(clientData);

    // The companies collection is managed by BusinessService; here only the
    // block the session brought is handed to it.
    businessService.seed(clientData["businesses"]);

    update(ClientModel.fromJson(clientData));

    // The session was confirmed by the backend: only here does the socket have
    // valid credentials to present in the handshake. Without waiting for it,
    // because this runs before raising the tree and the app has no reason to
    // stay on the splash while the connection opens (nor to fail if it does not
    // open: the client retries on its own and `ConnectionService` does not
    // throw).
    unawaited(ConnectionService().open());

    return null;
  }

  /// Hands out the platform configuration that came in `/init`: the two
  /// catalogs and the bases with which the image addresses are built.
  ///
  /// Each block is handed only if it arrived: a response without `countries` —an
  /// old backend, a half deployment— leaves the catalog as it was instead of
  /// emptying it, which is what would leave the forms with nothing to offer,
  /// and one without `cdn` leaves the images downloading from where they were
  /// already downloading.
  void _seedCatalogs(Map clientData) {
    final countries = clientData["countries"];
    final currencies = clientData["currencies"];
    final cdn = clientData["cdn"];

    if (countries != null) CountryCatalogService().seed(countries);
    if (currencies != null) CurrencyCatalogService().seed(currencies);
    if (cdn != null) CdnService().seed(cdn);
  }

  /// Rereads the platform configuration with the app running.
  ///
  /// None of this belongs to this app or this session: a region is enabled —or
  /// a currency symbol is corrected, or the CDN moves— on the backend side, and
  /// what is already
  /// open would have to find out without anyone publishing a new version or
  /// signing out. This is what is needed for that: the catalog services notify
  /// on receiving the new data, so the mounted screens repaint on their own.
  ///
  /// The whole `/init` is reread because it is the endpoint that serves it, but
  /// **only that part is reseeded**: the profile and the companies are already
  /// loaded and have someone keeping them up to date, and reseeding them here
  /// would reset the active company to the first one in the list in the middle
  /// of whatever is being done.
  ///
  /// It does not throw: the catalog not being able to refresh is not an error
  /// that matters to whoever is working —what there is still serves—, so the
  /// failure is ignored and retried next time.
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
    // Without a session there is nothing to listen to. `close` does not release
    // the listeners, so the next sign in receives the same events again.
    ConnectionService().close();
    notifyListeners();
  }

  String get email => client.email;
  String? get picture => client.picture;
  String get username => client.username;
  String get fullName => client.fullName;
}
