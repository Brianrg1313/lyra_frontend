import 'package:core/socket.dart';

// SERVICES
import 'package:app/services/database/database_service.dart';

/// The app's socket connection.
///
/// It's the real-time equivalent of `api`: same host and same `tokenName`,
/// so it inherits from the shared storage the token that login left behind
/// without anyone having to copy it over. `ConnectionService` is the one that
/// manages it, resolving the lifecycle and exposing the state to the app;
/// this instance only declares what it connects to.
final sockets = _Sockets();

class _Sockets extends SocketAPI {
  final _database = DatabaseService();

  /// Business that what's being listened to belongs to, on the same criteria
  /// as in the REST api: it isn't handshake data but session context.
  /// `useBusiness` sets it every time the active business changes.
  ///
  /// It travels in [extraAuth] as well as in the header because the browser
  /// won't let you send custom headers on web, and because `auth` gets
  /// re-read on every reconnection while the headers stay frozen.
  String? business;

  /// `name` is the socket.io namespace, not a path prefix as it is in the REST
  /// api: the backend mounts every handler on the default namespace
  /// (`io.on("connection")`, no `io.of(...)` anywhere), so anything else here
  /// gets the handshake rejected with "Invalid namespace".
  @override
  ApiModel get dev => ApiModel(
    host: "192.168.1.103",
    name: "/",
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

  /// Same role as `preRequest` in the REST api: if the token isn't in memory
  /// yet (cold start, the session was opened in an earlier run) it's
  /// recovered from secure storage before the first handshake.
  @override
  Future<void> preConnect() async {
    token ??= await _database.fromSecure<String>(current.tokenName);
  }
}
