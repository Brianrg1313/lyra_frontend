import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext, WidgetsBinding;
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';
import 'package:app/services/client/client_model.dart';
import 'package:app/services/client/client_task.dart';
import 'package:app/services/client/employment_invitation_model.dart';
import 'package:app/services/client/sources/session_source.dart';
import 'package:app/toolkit/api.dart';
import 'package:app/toolkit/deployment.dart';

// SERVICES
import 'package:app/services/database/database_service.dart';
import 'package:app/services/preferences/preferences_service.dart';
import 'package:app/services/connection/connection_service.dart';
import 'package:app/services/catalog/country_catalog_service.dart';
import 'package:app/services/catalog/currency_catalog_service.dart';
import 'package:app/services/files/cdn_service.dart';
import 'package:app/services/permissions/permissions_service.dart';
import 'package:app/services/home/home_service.dart';
import 'package:app/services/baileys/baileys_service.dart';
import 'package:app/services/channels/channels_service.dart';
import 'package:app/services/channels/channel_catalog_service.dart';
import 'package:app/services/connections/connections_service.dart';
import 'package:app/services/connections/connection_catalog_service.dart';
import 'package:app/services/stock/tables/tables_service.dart';
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
/// catalogs, [CdnService] the image bases and [PermissionsService] what the
/// person may do in each company. None is stored here.
class ClientService extends ChangeNotifier {
  ClientService({SessionSource? source}) : _injected = source {
    onSessionRejected = _expire;
  }

  final SessionSource? _injected;

  SessionSource get _source => _injected ?? Sources.session;

  final DatabaseService _database = DatabaseService();

  ClientModel? _client;

  List<ClientTask> _tasks = const [];

  /// What the person must do before the dashboard, in order (`/init`'s `tasks`).
  List<ClientTask> get tasks => _tasks;

  /// The invitations of the pending `employment.invitation` task, if any.
  List<EmploymentInvitation> get invitations => [
    for (final task in _tasks)
      if (task.key == ClientTaskKey.invitation) ...task.invitations
  ];

  bool get isAuthenticated => _client != null;

  ClientModel get client {
    assert(_client != null, "ClientService read without a session started");
    return _client!;
  }

  /// Loads the client if there is a valid session.
  ///
  /// Returns the route to redirect to, or `null` if the session is valid, the
  /// client ended up loaded and nothing is pending. A pending task with a
  /// screen wins over the dashboard and over a deep link: the backend lists
  /// what must be done before either.
  ///
  /// `/login` signs in again in either mode: on a master's device it is the
  /// master's sign in (`AuthMaster`).
  Future<String?> resolve() async {
    const signIn = "/login";

    if (!await _source.hasSession()) {
      return signIn;
    }

    String? page;
    final Map<String, dynamic>? clientData = await _source.bootstrap().then<Map<String, dynamic>?>((data) => data).catchError((E) {
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
      page = (action != null && action != "login" ? Navis.byKey(action)?.url : null) ?? signIn;
      return null;
    });

    if (page != null) {
      // The stored session is no longer useful: without discarding it, the
      // next cold start would retry `/init` with it and fail again with 401.
      await _dropSession();
      return page;
    }

    if (clientData == null) {
      return signIn;
    }

    // The platform configuration goes first: it is with it that the data that
    // comes later is read (in which currency each company invoices, in which
    // country it operates, where its logo is downloaded from), so by the time
    // someone looks at them they already have what to answer with.
    _seedCatalogs(clientData);

    final client = ClientModel.fromJson(clientData);

    // Before the businesses: seeding them activates the one this account last
    // worked in, which is a per-account preference.
    PreferencesService().bindUser(client.username);

    // The companies collection is managed by BusinessService; here only the
    // block the session brought is handed to it.
    businessService.seed(clientData["businesses"]);
    _seedPermissions(clientData);

    _tasks = ClientTask.listFromJson(clientData["tasks"]);
    update(client);

    // The session was confirmed by the backend: only here does the socket have
    // valid credentials to present in the handshake. Without waiting for it,
    // because this runs before raising the tree and the app has no reason to
    // stay on the splash while the connection opens (nor to fail if it does not
    // open: the client retries on its own and `ConnectionService` does not
    // throw).
    unawaited(ConnectionService().open());

    for (final task in _tasks) {
      // Someone who already works at a company does not owe an answer before
      // the dashboard: the invitation waits, and they go in.
      if (task.key == ClientTaskKey.invitation && businessService.hasBusiness) continue;

      final route = task.key.route;
      if (route != null) return route;
    }

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

  /// Hands `/init`'s `permissions` to [PermissionsService]. Absent (an older
  /// backend) leaves it unloaded, which hides nothing.
  void _seedPermissions(Map clientData) {
    final permissions = clientData["permissions"];

    if (permissions != null) PermissionsService().seed(permissions);
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

    final data = await _source.bootstrap().then<Map<String, dynamic>?>((data) => data).catchError((E) {
      if (kDebugMode) {
        print("refreshCatalogs failed: $E");
      }
      return null;
    });

    if (data == null) return;

    _seedCatalogs(data);
    // Grants change mid-session (a role edited by an admin); seeding them
    // does not touch the active company.
    _seedPermissions(data);
  }

  /// Accepts an invitation: the job becomes active and the company can read
  /// the person's profile. Throws the api error; whoever calls it shows it.
  /// The pending task is not touched here: the caller re-`resolve()`s so
  /// `/init` says what is left.
  Future<void> acceptInvitation(String id) => _source.acceptInvitation(id);

  bool _signingOut = false;

  /// Closes the session: on the backend first, then everything this app holds
  /// from it, and lands on `/login`.
  ///
  /// The backend is told while the token still exists (the logout route reads
  /// it from the Authorization header) and it closes the session in MySQL,
  /// evicts it from the Redis cache and disconnects its sockets. Its failure
  /// does not keep anyone signed in: whoever presses "sign out" expects to
  /// leave, and a token this app forgets is one nobody sends again — the
  /// backend expires it on its own. Hence the timeout too: an unreachable
  /// server must not leave the button hanging.
  ///
  /// It takes a [BuildContext] only to reach the services provided with
  /// `create:` in `initialBuilder`, which have no global instance. They are
  /// read **before** anything awaits, because the context is home's and home
  /// goes away with the navigation.
  ///
  /// The services are emptied only after leaving home, never before: the
  /// shell reads the client (profile card) and the active business while it
  /// is mounted, and emptying them under it would draw a shell without a
  /// session for a frame — or trip [client]'s assert.
  Future<void> signOut(BuildContext context) => _end(context, expired: false);

  /// The backend refused the session mid-use ([onSessionRejected]): the same
  /// teardown as [signOut], without telling the backend what it already
  /// knows, and with a flag so landing on `/login` is not a mystery.
  ///
  /// Only for a loaded session: a `401` while signing in or inside [resolve]
  /// is already handled by whoever made that call. The navigator's context is
  /// below the providers (`initialBuilder` wraps the app), so it reaches the
  /// same services the home's context does.
  void _expire() {
    final context = Navis.delegate.navigatorKey.currentContext;
    if (context == null || !isAuthenticated) return;

    unawaited(_end(context, expired: true));
  }

  Future<void> _end(BuildContext context, {required bool expired}) async {
    if (_signingOut || !isAuthenticated) return;
    _signingOut = true;

    final home = context.read<HomeService>();
    final baileys = context.read<BaileysService>();
    final tables = context.read<TablesService>();
    final channels = context.read<ChannelsService>();
    final channelCatalog = context.read<ChannelCatalogService>();
    final connections = context.read<ConnectionsService>();
    final connectionCatalog = context.read<ConnectionCatalogService>();

    try {
      if (!expired) {
        var closed = true;

        await _source
          .signOut()
          .timeout(const Duration(seconds: 5))
          .catchError((E) {
            if (kDebugMode) print("signOut: backend logout failed: $E");
            // A session the backend already refuses is as closed as it gets.
            if (!(E is Map && E["action"] == "login")) closed = false;
            return null;
          });

        // With a cookie session only the backend can forget the credential
        // (the cookie is `HttpOnly`): leaving for `/login` anyway would look
        // signed out while the next reload walks straight back in.
        if (!closed && useCookieSession) {
          FloatFlag.of().error(message: S.current.sign_out_failed);
          return;
        }
      }

      await baileys.signOut();
      await _dropSession();

      if (context.mounted) Navis.pushAndClearStack(context, "/login");
      await WidgetsBinding.instance.endOfFrame;

      if (expired) FloatFlag.of().alert(message: S.current.session_expired);

      home.clearSearch();
      tables.clear();
      channels.clear();
      channelCatalog.clear();
      connections.clear();
      connectionCatalog.clear();
      businessService.clear();
      CountryCatalogService().clear();
      CurrencyCatalogService().clear();
      CdnService().clear();
      PermissionsService().clear();
      clear();
    } finally {
      _signingOut = false;
    }
  }

  /// Forgets the credential: from memory (shared by every api through the
  /// token registry, socket included), from secure storage, and the socket
  /// that authenticated with it.
  Future<void> _dropSession() async {
    api.token = null;
    ConnectionService().close();
    await _database.deleteSecure(api.current.tokenName);
  }

  void update(ClientModel value) {
    _client = value;
    notifyListeners();
  }

  void clear() {
    _client = null;
    PreferencesService().bindUser(null);
    _tasks = const [];
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
