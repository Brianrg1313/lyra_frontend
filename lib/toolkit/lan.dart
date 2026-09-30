import 'dart:async';

import 'package:flutter/foundation.dart';

// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart';

// SERVICES
import 'package:app/services/lan/lan_device.dart';
import 'package:app/services/lan/lan_identity_store.dart';
import 'lan_web.dart' if (dart.library.io) 'lan_io.dart' as transport;
import './lan_found.dart';

export './lan_found.dart';

/// This app's version as `hello` sends it (`protocol-v1.md` §4). `test/lan_client_test.dart`
/// keeps it equal to `pubspec.yaml`.
const String lanAppVersion = "0.0.6";

/// Whether this build can use LAN mode at all (native builds; the web client is still to come).
bool get lanSupported => transport.lanSupported;

/// The `platform` a device says it is (`PairingDevice.platforms`).
String get lanPlatform => kIsWeb ? "web" : defaultTargetPlatform.name.toLowerCase();

Future<List<LanFound>> discoverMasters() => transport.discover();

Future<LanPairingSocket> openPairingSocket(String host, int port) => transport.openPairing(host, port);

/// A refusal of the master in the shape the api layer throws (`{message, action}`, plus the
/// stable `code`), so `FloatFlag.showFromError` and `onSessionRejected` read it unchanged.
Map<String, Object?> lanFailure(RpcError error) => {
  "message": error.message,
  "action": error.action,
  "code": error.code,
  "data": error.data,
};

/// The master couldn't be reached on any address it was last seen at.
class LanUnreachable implements Exception {
  const LanUnreachable();

  @override
  String toString() => "LanUnreachable";
}

/// How a client opens `/rpc` to its master; a seam for tests.
typedef LanConnect = Future<RpcClient> Function(LanDevice device, String host);

/// The connection of this install to its master (plan §4 `lan.dart`, `protocol-v1.md` §4): one
/// `/rpc` socket, `hello` on every connect, the session bound to it, and its refresh.
///
/// Every failure of an op is thrown as [lanFailure]'s map, like the api layer does, so a
/// service reads LAN and cloud errors the same way.
class LanClient {
  LanClient(this._device, {LanIdentityStore store = const SecureLanIdentityStore(), LanConnect? connect})
    : _store = store,
      _connect = connect ?? transport.openRpc;

  final LanIdentityStore _store;
  final LanConnect _connect;
  LanDevice _device;
  RpcClient? _rpc;
  HelloAnswer? _hello;
  String? _accessToken;
  DateTime? _accessExpires;
  String? _accountId;

  LanDevice get device => _device;

  HelloAnswer? get hello => _hello;

  String? get accountId => _accountId;

  bool get isConnected => _rpc != null && !_rpc!.isClosed;

  bool get isSignedIn => _accessToken != null;

  /// Events of the bound session, after `events.subscribe`.
  Stream<RpcEvent> get events => _rpc?.events ?? const Stream.empty();

  /// Completes when the socket closes (the master stopped, the device was revoked).
  Future<void> get done => _rpc?.done ?? Future.value();

  /// Opens the socket on the first address that answers (the last one that did goes first)
  /// and says hello.
  Future<HelloAnswer> connect() async {
    if (isConnected && _hello != null) return _hello!;

    for (final host in _device.hosts) {
      final RpcClient rpc;
      try {
        rpc = await _connect(_device, host);
      } on RpcError catch (error) {
        throw lanFailure(error);
      } catch (error) {
        if (kDebugMode) print("lan: $host unreachable: $error");
        continue;
      }

      try {
        _hello = await rpc.hello(app: lanAppVersion, platform: lanPlatform);
      } on RpcError catch (error) {
        await rpc.close();
        throw lanFailure(error);
      }

      _rpc = rpc;
      _accessToken = null;

      if (_device.hosts.first != host) {
        _device = _device.copyWith(hosts: [host, ..._device.hosts.where((other) => other != host)]);
        await _store.saveDevice(_device);
      }

      return _hello!;
    }

    throw const LanUnreachable();
  }

  /// Unlocks a master in passphrase mode (only the master's own app may).
  Future<void> unlock(String passphrase) async {
    await _raw(Ops.engineUnlock, {"passphrase": passphrase});
    _hello = null;
    _hello = await _rpc!.hello(app: lanAppVersion, platform: lanPlatform);
  }

  /// `auth.identify` + `auth.signIn` + `session.bind`. Answers `mustChangePassword`.
  Future<bool> signIn(String login, String password) async {
    final tokens = await _raw(Ops.authSignIn, {"login": login, "password": password}) as Map<String, Object?>;

    await _adopt(tokens);

    return tokens["mustChangePassword"] == true;
  }

  /// Picks up the stored session (an app restart, a reconnect). False when there is none or it
  /// ended; then the person signs in again.
  Future<bool> resume() async {
    final refresh = await _store.refreshToken();
    if (refresh == null) return false;

    try {
      await _adopt(await _raw(Ops.authRefresh, {"refreshToken": refresh}) as Map<String, Object?>);
      return true;
    } on Map<String, Object?> {
      await _store.saveRefreshToken(null);
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      if (isSignedIn) await call(Ops.authSignOut);
    } on Object {
      // Signed out here either way; the master ends it when the token expires.
    }

    _accessToken = null;
    _accountId = null;
    await _store.saveRefreshToken(null);
  }

  /// Runs [op] as the signed-in session, refreshing it first when the access token is about to
  /// expire, and once more if the master says it did.
  Future<Object?> call(Op op, {Map<String, Object?> args = const {}, String? commandId}) async {
    if (_accessExpires != null && _accessExpires!.difference(DateTime.now()) < const Duration(minutes: 1)) {
      await resume();
    }

    try {
      return await _raw(op, args, commandId: commandId);
    } on Map<String, Object?> catch (failure) {
      if (failure["code"] != ErrorCodes.sessionExpired || !await resume()) rethrow;

      return _raw(op, args, commandId: commandId);
    }
  }

  Future<void> close() async {
    await _rpc?.close();
    _rpc = null;
    _hello = null;
    _accessToken = null;
  }

  Future<void> _adopt(Map<String, Object?> tokens) async {
    await _store.saveRefreshToken(tokens["refreshToken"] as String);

    final bound = await _raw(Ops.sessionBind, {"accessToken": tokens["accessToken"]}) as Map<String, Object?>;

    _accessToken = tokens["accessToken"] as String;
    _accessExpires = DateTime.tryParse(tokens["accessExpires"] as String? ?? "");
    _accountId = bound["accountId"] as String?;
  }

  Future<Object?> _raw(Op op, Map<String, Object?> args, {String? commandId}) async {
    if (!isConnected) await connect();

    try {
      return await _rpc!.call(op, args: args, commandId: commandId);
    } on RpcError catch (error) {
      throw lanFailure(error);
    } on RpcClosed {
      _rpc = null;
      _accessToken = null;
      throw const LanUnreachable();
    }
  }
}
