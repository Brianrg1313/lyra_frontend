import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart';

// SERVICES
import 'package:app/services/lan/lan_device.dart';
import 'package:app/services/lan/lan_identity_store.dart';
import 'lan_web.dart' if (dart.library.io) 'lan_io.dart' as transport;
import './lan_found.dart';
import './lan_key.dart';
import './lan_file.dart';
import './save_file.dart';

export './lan_found.dart';
export './lan_key.dart';
export './lan_file.dart';

/// This app's version as `hello` sends it (`protocol-v1.md` §4). `test/lan_client_test.dart`
/// keeps it equal to `pubspec.yaml`.
const String lanAppVersion = "0.0.6";

/// Whether this install can use LAN mode at all: every native build, and in a browser the page
/// a master serves (plan §3), never the cloud's.
bool get lanSupported => transport.lanSupported;

/// On web, the master that served this page: the only one a browser pairs with and talks to.
({String host, int port})? get lanServingMaster => kIsWeb && lanSupported ? (host: Uri.base.host, port: Uri.base.port) : null;

/// Phones scan the master's QR with their camera (plan §5.3); the others type the code.
bool get lanCanScan => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

/// A fresh device key for pairing: a PEM key natively, a non-extractable WebCrypto key in a browser.
Future<LanDeviceKey> newDeviceKey() => transport.newDeviceKey();

/// Signs a `device.prove` challenge with the key this browser kept at pairing; null without one.
Future<Uint8List?> signDeviceProof(LanDevice device, List<int> message) => transport.signProof(device, message);

/// Drops the browser's device key (leaving LAN mode); nothing natively.
Future<void> forgetDeviceKey() => transport.forgetDeviceKey();

/// Whether this computer can put the browsers' root in its trust store itself (Windows, macOS).
bool get canInstallBrowserCa => transport.canInstallBrowserCa;

Future<bool> installBrowserCa(Uint8List certificate) => transport.installBrowserCa(certificate);

/// Saves the browsers' root as a `.crt` file the person picks the place of (a USB drive, for
/// another computer, plan §5.3). False when they cancel.
Future<bool> saveBrowserCa(Uint8List certificate) => saveFile(
  certificate,
  name: "lyra-ca.crt",
  mimeType: "application/x-x509-ca-cert",
  extension: "crt",
  label: "Certificate"
);

/// The `platform` a device says it is (`PairingDevice.platforms`).
String get lanPlatform => kIsWeb ? "web" : defaultTargetPlatform.name.toLowerCase();

/// The name a device pairs with unless the person types one; the admin renames it in "Devices".
String get lanDeviceName => "Lyra ${lanPlatform[0].toUpperCase()}${lanPlatform.substring(1)}";

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

/// How a browser signs the `hello` challenge with its device key (`device.prove`); null when
/// it has no key any more. A seam for tests.
typedef LanProve = Future<Uint8List?> Function(LanDevice device, List<int> message);

/// How a client sends a `/f` request to its master; a seam for tests.
typedef LanFiles = Future<LanFileResponse> Function(
  LanDevice device,
  String host,
  String method,
  String path, {
  required String token,
  Map<String, String> headers,
  Uint8List? body,
});

/// The connection of this install to its master (plan §4 `lan.dart`, `protocol-v1.md` §4): one
/// `/rpc` socket, `hello` on every connect, the session bound to it, and its refresh.
///
/// Every failure of an op is thrown as [lanFailure]'s map, like the api layer does, so a
/// service reads LAN and cloud errors the same way.
class LanClient {
  LanClient(
    this._device, {
    LanIdentityStore store = const SecureLanIdentityStore(),
    LanConnect? connect,
    LanProve? prove,
    LanFiles? files,
  }) : _store = store,
      _connect = connect ?? transport.openRpc,
      _prove = prove ?? signDeviceProof,
      _files = files ?? transport.fileRequest;

  final LanIdentityStore _store;
  final LanConnect _connect;
  final LanProve _prove;
  final LanFiles _files;
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
        await _proveDevice(rpc, _hello!);
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

  /// A browser has no client certificate: it signs the challenge before anything else
  /// (`protocol-v1.md` §3). A key the master doesn't know, or no key at all, means this browser
  /// is no longer paired: it is told so as a revoked device, which pairs again.
  Future<void> _proveDevice(RpcClient rpc, HelloAnswer hello) async {
    final challenge = hello.challenge;
    // A locked master proves nobody yet; the browser waits on the locked page.
    if (challenge == null || hello.state == EngineState.locked) return;

    final signature = await _prove(_device, DeviceProof.message(hello.instanceId, challenge));
    if (signature == null) throw const RpcError(ErrorCodes.deviceRevoked, "");

    try {
      await rpc.call(Ops.deviceProve, args: {"deviceId": _device.deviceId, "signature": base64.encode(signature)});
    } on RpcError catch (error) {
      if (error.code == ErrorCodes.forbidden) throw RpcError(ErrorCodes.deviceRevoked, error.message, action: error.action);
      rethrow;
    }
  }

  /// Unlocks a master in passphrase mode (only the master's own app may).
  Future<void> unlock(String passphrase) async {
    await _raw(Ops.engineUnlock, {"passphrase": passphrase});
    _hello = null;
    _hello = await _rpc!.hello(app: lanAppVersion, platform: lanPlatform);
  }

  /// `auth.identify`: `password`, or `activation` for an invited account not activated yet. An
  /// unknown login answers `password` too, so the sign in tells nobody which accounts exist.
  Future<String?> identify(String login) async =>
    ((await _raw(Ops.authIdentify, {"login": login})) as Map?)?["method"] as String?;

  /// `auth.signIn` + `session.bind`. Answers `mustChangePassword`.
  Future<bool> signIn(String login, String password) async {
    final tokens = await _raw(Ops.authSignIn, {"login": login, "password": password}) as Map<String, Object?>;

    await _adopt(tokens);

    return tokens["mustChangePassword"] == true;
  }

  /// `auth.activate` + `session.bind` (`session.md` S-8): an invited person's code and their new
  /// password make the account active and sign it in, as [signIn] does.
  Future<void> activate(String login, String code, String password) async =>
    _adopt(await _raw(Ops.authActivate, {"login": login, "code": code, "password": password}) as Map<String, Object?>);

  /// `auth.grant` + `session.bind` (`session.md` S-12): the backend's signed statement opens the
  /// session without the password. Its sealed fields wait for [unseal].
  Future<void> grant(String grant) async =>
    _adopt(await _raw(Ops.authGrant, {"grant": grant}) as Map<String, Object?>);

  /// `auth.unseal` + `session.bind` (S-13): the password opens this session's sealed fields, under
  /// a rotated refresh token.
  Future<void> unseal(String password) async {
    final refresh = await _store.refreshToken();
    if (refresh == null) throw lanFailure(const RpcError(ErrorCodes.sessionExpired, ""));

    await _adopt(await _raw(Ops.authUnseal, {"refreshToken": refresh, "password": password}) as Map<String, Object?>);
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

  /// Downloads file [id] (`GET /f/<id>`, `protocol-v1.md` §6); [size] asks for its thumbnail.
  Future<Uint8List> download(String id, {int? size}) =>
    _file("GET", "/f/${Uri.encodeComponent(id)}${size == null ? "" : "?size=$size"}");

  /// Uploads [bytes] for [purpose] (`logo`, `product_image`…); answers the `fileId` an op then
  /// references.
  Future<String> upload(String purpose, Uint8List bytes) async {
    final answer = jsonDecode(utf8.decode(await _file("PUT", "/f", headers: {"X-Lyra-Purpose": purpose}, body: bytes)));
    final id = answer is Map ? answer["fileId"] : null;
    if (id is! String) throw lanFailure(const RpcError(ErrorCodes.internal, ""));

    return id;
  }

  /// A `/f` request as the signed-in session, on the address `/rpc` last answered on. A refusal
  /// is thrown like an op's; an expired token is refreshed once.
  Future<Uint8List> _file(String method, String path, {Map<String, String> headers = const {}, Uint8List? body}) async {
    if (!isConnected) await connect();
    if (_accessExpires != null && _accessExpires!.difference(DateTime.now()) < const Duration(minutes: 1)) await resume();

    for (var attempt = 0; ; attempt++) {
      final token = _accessToken;
      if (token == null) throw lanFailure(const RpcError(ErrorCodes.sessionExpired, ""));

      final LanFileResponse response;
      try {
        response = await _files(_device, _device.hosts.first, method, path, token: token, headers: headers, body: body);
      } on LanFileUnreachable {
        throw const LanUnreachable();
      }

      if (response.status == 200) return response.body;

      final error = _refusal(response);
      if (error.code == ErrorCodes.sessionExpired && attempt == 0 && await resume()) continue;

      throw lanFailure(error);
    }
  }

  static RpcError _refusal(LanFileResponse response) {
    try {
      final json = jsonDecode(utf8.decode(response.body));
      if (json is Map<String, Object?>) return RpcError.fromJson(json);
    } on FormatException {
      // Not the master's JSON: told as a generic failure below.
    }

    return RpcError(response.status == 404 ? ErrorCodes.notFound : ErrorCodes.internal, "");
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
