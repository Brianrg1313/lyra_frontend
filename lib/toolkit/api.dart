import 'package:core/api.dart';

// SERVICES
import 'package:app/toolkit/sockets.dart';
import 'package:app/services/database/database_service.dart';

// WIDGETS
export 'package:core/float_flag/controller.dart';


final api = _Api();
final assets = _Assets();

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

/// Sets the active business on both apis and on the socket, or clears it when
/// signing out.
///
/// `BusinessService` calls it every time the active business changes: it's
/// the only thing that needs touching for every request to end up pointing at
/// the right business, without each endpoint having to remember to send it.
///
/// The socket is the exception to that "ends up pointing at": its handshake
/// already happened, so the new business only travels on the next
/// reconnection. If the events being listened to belong to the active
/// business, it has to be forced with `ConnectionService().refresh()`.
void useBusiness(String? id) {
  api.business = id;
  assets.business = id;
  sockets.business = id;
}

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
    host: "192.168.1.103",
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
    host: "192.168.1.103",
    name: "cetus",
    port: 81,
    scheme: "http",
    type: ApiMode.assets,
    tokenName: "Authorization"
  );

  @override
  ApiModel get prod => dev;
}
