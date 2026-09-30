import 'dart:async';

import 'package:flutter/foundation.dart';

// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart';
import 'package:uuid/uuid.dart';

// SERVICES
import 'package:app/toolkit/deployment.dart';
import 'package:app/toolkit/lan.dart';
import 'package:app/services/local_server/local_server_service.dart';
import './lan_device.dart';
import './lan_identity_store.dart';

/// Where this install is with its master, as the LAN pages show it.
enum LanStatus {
  idle,
  connecting,

  /// No pairing on this device (or the master app has no certificate yet).
  unpaired,

  /// The master is in passphrase mode and nobody unlocked it.
  locked,

  /// Connected; nobody signed in on this device.
  signedOut,

  ready,

  /// No address of the master answered: it's off, or the network changed.
  unreachable,

  /// An admin removed this device: it must pair again (S-41).
  revoked,

  /// This app and the master don't speak the same version.
  updateRequired,

  /// The engine on this computer can't be started or can't prove it's ours.
  error,
}

/// This install's session with its master in `local` mode (plan §7.4): starting the engine
/// when this computer is the master, connecting, unlocking, signing in, and the admin ops of
/// phase 3 (devices, pairing). The domains arrive with plan phase 4.
///
/// App-wide (`initial_builder.dart`): the boot flow and every LAN page share one connection.
class LanService extends ChangeNotifier {
  LanService({LanIdentityStore? store, LocalServerService? server, LanConnect? connect})
    : _store = store ?? const SecureLanIdentityStore(),
      _server = server,
      _connect = connect;

  final LanIdentityStore _store;
  final LanConnect? _connect;
  LocalServerService? _server;
  LanClient? _client;

  LocalServerService get server => _server ??= LocalServerService(store: _store);

  LanStatus _status = LanStatus.idle;
  LanStatus get status => _status;

  /// The last refusal's `message`, ready to show.
  String? _error;
  String? get error => _error;

  LanDevice? get device => _client?.device;

  bool get isMaster => Deployment.role == DeploymentRole.master;

  String? get accountId => _client?.accountId;

  /// Opens the session: on the master, the engine first (started, or attached to), then the
  /// connection, then the stored session if there is one.
  Future<LanStatus> open() async {
    _set(LanStatus.connecting);

    if (isMaster) {
      final engine = await server.start();

      if (engine == LocalServerStatus.notSetUp) return _set(LanStatus.unpaired);
      if (engine != LocalServerStatus.ready && engine != LocalServerStatus.locked) {
        _error = server.error;
        return _set(LanStatus.error);
      }
    }

    final device = await _store.device();
    if (device == null) return _set(LanStatus.unpaired);

    await _drop();
    _client = LanClient(device, store: _store, connect: _connect);

    return _connectAndResume();
  }

  /// This computer is a master but the app lost its certificate (the key store was wiped, the
  /// app reinstalled): the engine certifies a new key. It needs the engine stopped, so it stops
  /// it first; [passphrase] opens it in passphrase mode.
  Future<LanStatus> enrollMaster({String? passphrase}) async {
    _set(LanStatus.connecting);
    await server.stop();

    if (!await server.enroll(passphrase: passphrase)) {
      _error = server.error;
      return _set(LanStatus.unpaired);
    }

    return open();
  }

  /// `engine.unlock` from the master's own app.
  Future<LanStatus> unlock(String passphrase) => _guard(() async {
    await _client!.unlock(passphrase);

    return await _client!.resume() ? LanStatus.ready : LanStatus.signedOut;
  });

  Future<LanStatus> signIn(String login, String password) => _guard(() async {
    await _client!.signIn(login, password);

    return LanStatus.ready;
  });

  Future<void> signOut() async {
    await _client?.signOut();
    _set(LanStatus.signedOut);
  }

  /// The paired devices (`devices.list`), newest first.
  Future<List<Map<String, Object?>>> devices() async =>
    ((await _client!.call(Ops.devicesList)) as List).cast<Map<String, Object?>>();

  /// Opens a pairing on the master (`pairing.start`): `{qr, code, expires}`.
  Future<Map<String, Object?>> startPairing() async =>
    (await _client!.call(Ops.pairingStart)) as Map<String, Object?>;

  Future<void> revoke(String deviceId) =>
    _client!.call(Ops.devicesRevoke, args: {"id": deviceId}, commandId: const Uuid().v7());

  /// Stops the engine on this computer (the admin screen warns first, plan §3).
  Future<bool> stopServer() async {
    await _drop();
    final stopped = await server.stop();
    if (stopped) _set(LanStatus.unreachable);

    return stopped;
  }

  /// Leaves LAN mode on this device: forgets the pairing and goes back to the cloud app.
  Future<void> leave() async {
    await _drop();
    await _store.clear();
    Deployment.choose(DeploymentMode.cloud);
    _set(LanStatus.idle);
  }

  Future<LanStatus> _connectAndResume() => _guard(() async {
    final client = _client!;
    final hello = await client.connect();

    _watch(client);

    if (hello.state == EngineState.locked) return LanStatus.locked;

    return await _client!.resume() ? LanStatus.ready : LanStatus.signedOut;
  });

  /// Closes the connection on purpose: forgotten first, so [_watch] doesn't reconnect it.
  Future<void> _drop() async {
    final client = _client;
    _client = null;
    await client?.close();
  }

  /// When the socket closes under an open page (the master stopped, this device was revoked,
  /// the network changed), reconnects once: that lands on `unreachable`, `revoked` or back
  /// where it was.
  void _watch(LanClient client) {
    unawaited(client.done.then((_) {
      if (!identical(client, _client)) return;
      if (const {LanStatus.ready, LanStatus.signedOut, LanStatus.locked}.contains(_status)) {
        unawaited(_connectAndResume());
      }
    }));
  }

  Future<LanStatus> _guard(Future<LanStatus> Function() body) async {
    try {
      _error = null;
      return _set(await body());
    } on LanUnreachable {
      return _set(LanStatus.unreachable);
    } on Map<String, Object?> catch (failure) {
      _error = failure["message"] as String?;

      return _set(switch (failure["code"]) {
        ErrorCodes.deviceRevoked => LanStatus.revoked,
        ErrorCodes.updateRequired || ErrorCodes.versionMismatch => LanStatus.updateRequired,
        ErrorCodes.locked => LanStatus.locked,
        ErrorCodes.sessionExpired || ErrorCodes.sessionRevoked => LanStatus.signedOut,
        _ => _status == LanStatus.connecting ? LanStatus.error : _status,
      });
    }
  }

  LanStatus _set(LanStatus status) {
    _status = status;
    notifyListeners();

    return status;
  }

  @override
  void dispose() {
    unawaited(_client?.close());
    super.dispose();
  }
}
