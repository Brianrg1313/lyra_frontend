import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:core/api.dart';

// SERVICES
import 'package:app/toolkit/sockets.dart';
import 'package:app/services/database/database_service.dart';

// WIDGETS
export 'package:core/float_flag/controller.dart';


/// The machine running the backend in development. One constant for every
/// client —REST, desk, maps, assets **and the socket**— because they are one
/// server: the socket kept its own copy, the PC's address changed, and the
/// REST calls followed while the socket went on retrying an address nobody
/// answers, with no error on screen (no new chats, stages or tickets live).
const devHost = "192.168.1.103";

final api = _Api();
final assets = _Assets();

/// Conversation desk backend (`/aries/v1`): the inbox, the history and the
/// handover of the chats the assistant holds. Same host, session and business
/// header as [api]; only the path prefix differs.
final aries = _Aries();

/// Map backend (`/scorpius/v1`): the base map's tiles and the list of maps
/// the server holds. Same host as [api]. Its drawing routes are public —
/// a tile is fetched by the map layer, which sends none of our headers — so
/// the session and business headers it inherits are simply ignored there.
final scorpius = _Scorpius();

/// `{z}/{x}/{y}` template of one tileset's tiles on [scorpius], drawn by the
/// server with [style] (`light` or `dark`). Absolute because it is handed to
/// the map layer, which fetches it on its own; `{r}` becomes `@2x` on
/// high-density screens, where the server draws 512-pixel tiles.
String mapTilesUrl(String tileset, String style) {
  final implied =
    (scorpius.scheme == "http" && scorpius.port == 80) ||
    (scorpius.scheme == "https" && scorpius.port == 443);
  final origin = "${scorpius.scheme}://${scorpius.host}${implied ? "" : ":${scorpius.port}"}";

  return "$origin/${scorpius.name}/v1/raster/$tileset/$style/{z}/{x}/{y}{r}.png";
}

/// Where the api lives: scheme, host and port, without a path.
///
/// It's what's needed to complete an address the backend sends relative. The
/// only thing that sends one that way today is the image bases (see
/// `CdnService`): server-side `/rigel/media` is a valid address —the browser
/// resolves it against the page that fetched it—, but this isn't a page and
/// has nothing to resolve it against.
///
/// The port is omitted when it's the one the scheme already implies, which is
/// what anyone writing a URL by hand does.
String get apiOrigin {
  final port = api.port;
  final implied =
    (api.scheme == "http" && port == 80) ||
    (api.scheme == "https" && port == 443);

  return "${api.scheme}://${api.host}${implied ? "" : ":$port"}";
}

/// Whether our backend answers at all: any HTTP status counts, only a failed connection or
/// [timeout] does not. "Online" means our backend, not the internet at large, so it is asked
/// directly instead of a third party. The path is the api's own prefix, which the backend's CORS
/// answers like any route, so a browser reads the reply too.
Future<bool> cloudReachable({Duration timeout = const Duration(seconds: 5)}) async {
  try {
    await http.get(Uri.parse("$apiOrigin/${api.current.name}/v1/")).timeout(timeout);
    return true;
  } on Object {
    return false;
  }
}

/// Sets the active business on both apis and on the socket, or clears it when
/// signing out.
///
/// `BusinessService` calls it every time the active business changes: it's
/// the only thing that needs touching for every request to end up pointing at
/// the right business, without each endpoint having to remember to send it.
///
/// The socket is the exception to that "ends up pointing at": its handshake
/// already happened, so the new business only travels on the next one. That
/// is why `BusinessService` follows every change with
/// `ConnectionService().rebind()` — which is not done here because the same
/// call runs on sign out, where there is nothing to reconnect to.
void useBusiness(String? id) {
  api.business = id;
  assets.business = id;
  aries.business = id;
  scorpius.business = id;
  sockets.business = id;
}

/// Whether the session lives in an `HttpOnly` cookie instead of a stored
/// token. Web only: there the token would sit in browser storage, readable by
/// any script on the page (flutter_secure_storage has no OS vault on web).
/// Desktop keeps the token, which the OS credential store protects.
///
/// Off until the backend implements the contract in
/// `docs/task-cookie-session-backend.md` — without it no session could open on
/// web. Turned on at build time: `flutter build web --dart-define=LYRA_COOKIE_SESSION=true`.
const useCookieSession = kIsWeb && bool.fromEnvironment("LYRA_COOKIE_SESSION");

/// Keeps the credential a sign in or sign up answered with. With a cookie
/// session there is nothing to keep: the backend already set the cookie on
/// that same response, and any token in the body is ignored on purpose.
/// Throws when a token session got no token, like the callers did before.
Future<void> openSession(Object? token) async {
  if (useCookieSession) return;
  if (token is! String) throw "";

  api.token = token;
  await DatabaseService().toSecure(api.current.tokenName, token);
}

/// Called when the backend refuses the session itself: a `401` with
/// `action: "login"`, which is what `validate_session` answers for a token
/// that was closed, revoked or expired while the app was open. Without it the
/// screens would keep showing what they already loaded until a restart.
///
/// A hook and not a call because `ClientService`, which owns what ending a
/// session means, already imports this file. It sets it on construction.
void Function()? onSessionRejected;

/// Base of the app's apis: session token and active business travel the same
/// way on all of them, so the handling lives here once.
abstract class _SessionApi extends RestAPI {
  final _database = DatabaseService();

  /// Business that what's being requested belongs to. It's sent in the
  /// `business_id` header and not in the body because it isn't data being
  /// created but session context: the client can have several businesses and
  /// they all share the same endpoints.
  ///
  /// Null while none is chosen yet (session just opened with no businesses,
  /// or after signing out), and in that case the header doesn't travel.
  String? business;

  /// `session: cookie` tells the backend to answer a sign in with the cookie
  /// instead of a token in the body (see [useCookieSession]).
  @override
  Headers get extraHeaders => {
    "business_id": ?business,
    if (useCookieSession) "session": "cookie"
  };

  @override
  bool get cookieSession => useCookieSession;

  @override
  dynamic results(answer) {
    try {
      return super.results(answer);
    } catch (e) {
      if (answer.statusCode == 401 && e is Map && e["action"] == "login") {
        onSessionRejected?.call();
      }
      rethrow;
    }
  }

  @override
  Future<void> preRequest() async {
    if (token == null && !useCookieSession) {
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
    host: devHost,
    name: "lyra",
    port: 80,
    scheme: "http",
    tokenName: "Authorization"
  );

  @override
  ApiModel get prod => dev;
}

class _Aries extends _SessionApi {
  @override
  ApiModel get dev => ApiModel(
    host: devHost,
    name: "aries",
    port: 80,
    scheme: "http",
    tokenName: "Authorization"
  );

  @override
  ApiModel get prod => dev;
}

class _Scorpius extends _SessionApi {
  @override
  ApiModel get dev => ApiModel(
    host: devHost,
    name: "scorpius",
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
    host: devHost,
    name: "cetus",
    port: 81,
    scheme: "http",
    type: ApiMode.assets,
    tokenName: "Authorization"
  );

  @override
  ApiModel get prod => dev;
}
