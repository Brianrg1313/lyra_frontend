import 'dart:async';

import 'package:flutter/foundation.dart';

// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart';
import 'package:uuid/uuid.dart';

// SERVICES
import 'package:app/generated/l10n.dart';
import 'package:app/toolkit/api.dart' show onSessionRejected;
import 'package:app/toolkit/deployment.dart';
import 'package:app/toolkit/lan.dart';
import 'package:app/services/connection/connection_service.dart';
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
/// when this computer is the master, connecting, unlocking, signing in, the admin ops of
/// phase 3 (devices, pairing), and the master's events, handed to the services through
/// `ConnectionService` (`protocol-v1.md` §5).
///
/// App-wide (`initial_builder.dart`): the boot flow and every LAN page share one connection.
class LanService extends ChangeNotifier {
  LanService({
    LanIdentityStore? store,
    LocalServerService? server,
    LanConnect? connect,
    LanProve? prove,
    LanFiles? files,
    void Function(String event, Object? data)? deliver,
    void Function()? resync,
  }) : _store = store ?? const SecureLanIdentityStore(),
      _server = server,
      _connect = connect,
      _prove = prove,
      _files = files,
      _deliver = deliver ?? ConnectionService().receive,
      _resync = resync ?? ConnectionService().resync;

  final LanIdentityStore _store;
  final LanConnect? _connect;
  final LanProve? _prove;
  final LanFiles? _files;
  final void Function(String event, Object? data) _deliver;
  final void Function() _resync;
  LocalServerService? _server;
  LanClient? _client;

  /// The last event seq handed over: a reconnect asks the master to replay from it.
  int? _seq;
  StreamSubscription<RpcEvent>? _feed;

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
    _client = LanClient(device, store: _store, connect: _connect, prove: _prove, files: _files);

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

  /// The sign in's first step, as the cloud's `email/verify` (`auth.identify`): whether [login]
  /// still has to be activated with its code (S-8). `null` when the master didn't answer, with
  /// [error] or the status saying why.
  Future<bool?> needsActivation(String login) async {
    try {
      _error = null;
      return await _client!.identify(login) == "activation";
    } on LanUnreachable {
      _set(LanStatus.unreachable);
    } on Map<String, Object?> catch (failure) {
      _error = failure["message"] as String?;
      notifyListeners();
    }

    return null;
  }

  Future<LanStatus> signIn(String login, String password) => _guard(() async {
    await _client!.signIn(login, password);

    return LanStatus.ready;
  });

  /// An invited person's first sign in (`session.md` S-8): the code the company gave them and
  /// the password they choose.
  Future<LanStatus> activate(String login, String code, String password) => _guard(() async {
    await _client!.activate(login, code, password);

    return LanStatus.ready;
  });

  Future<void> signOut() async {
    await _stopEvents();
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

  /// Leaves LAN mode on this device: forgets the pairing (and a browser's key), which is what
  /// made it a LAN device (`Deployment.restore`), so it starts as the cloud app. A browser,
  /// whose page is the master's, can only pair again.
  Future<void> leave() async {
    await _drop();
    await _store.clear();
    await forgetDeviceKey();
    Deployment.detach();
    _set(LanStatus.idle);
  }

  /// Runs [op] as this session: what the LAN sources call (`Sources`). A write gets its
  /// `commandId` here. A refusal is thrown as the api layer throws one (`lanFailure`); a master
  /// that stopped answering is thrown the same way, with a message to show, so a screen treats
  /// it as any failed request while [open] tries again behind it.
  Future<Object?> call(Op op, {Map<String, Object?> args = const {}}) async {
    final client = _client;
    if (client == null || _status != LanStatus.ready) throw _unreachable;

    try {
      return await client.call(op, args: args, commandId: op.needsCommandId ? const Uuid().v7() : null);
    } on LanUnreachable {
      unawaited(_connectAndResume());
      throw _unreachable;
    }
  }

  /// File [id] from the master (`protocol-v1.md` §6), its thumbnail with [size]: what
  /// `LanFileImage` draws. Fails like [call].
  Future<Uint8List> download(String id, {int? size}) => _withClient((client) => client.download(id, size: size));

  /// Uploads [bytes] for [purpose]; answers the `fileId` the op that uses it references.
  Future<String> upload(String purpose, Uint8List bytes) => _withClient((client) => client.upload(purpose, bytes));

  Future<T> _withClient<T>(Future<T> Function(LanClient client) body) async {
    final client = _client;
    if (client == null || _status != LanStatus.ready) throw _unreachable;

    try {
      return await body(client);
    } on LanUnreachable {
      unawaited(_connectAndResume());
      throw _unreachable;
    }
  }

  static Map<String, Object?> get _unreachable =>
    {"message": S.current.lan_unreachable_title, "action": null, "code": "unreachable"};

  /// The browsers' root of this installation (`devices.browserCa`): `{certificate, fingerprint}`.
  Future<Map<String, Object?>> browserCa() async =>
    (await _client!.call(Ops.devicesBrowserCa)) as Map<String, Object?>;

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
    await _stopEvents();
    await client?.close();
  }

  /// Follows the master's events once the session is ready (`events.subscribe`). A reconnect
  /// asks for what came after the last one handed over, so nothing in between is lost; when the
  /// master no longer keeps that far back (`resync_required`), every screen reads again instead.
  ///
  /// A refusal here doesn't fail the session: screens still read, only not live.
  Future<void> _subscribe() async {
    final client = _client!;

    await _feed?.cancel();
    _feed = client.events.listen((event) {
      _seq = event.seq;
      _deliver(event.event, event.data);
    });

    try {
      Object? answer;
      try {
        answer = await client.call(Ops.eventsSubscribe, args: {"since": ?_seq});
      } on Map<String, Object?> catch (failure) {
        if (failure["code"] != ErrorCodes.resyncRequired) rethrow;

        _seq = null;
        answer = await client.call(Ops.eventsSubscribe);
        _resync();
      }

      final head = answer is Map ? answer["head"] : null;
      if (_seq == null && head is int) _seq = head;
    } on Map<String, Object?> catch (failure) {
      if (kDebugMode) print("lan: events.subscribe refused: $failure");
    }
  }

  /// Stops following: signing out ends the session the stream belonged to.
  Future<void> _stopEvents() async {
    await _feed?.cancel();
    _feed = null;
    _seq = null;
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
      final status = await body();
      if (status == LanStatus.ready) await _subscribe();

      return _set(status);
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

  /// Leaving [LanStatus.ready] ends the session the app runs on (`ClientService` through
  /// [onSessionRejected]): the LAN landing then says why and offers the way back.
  LanStatus _set(LanStatus status) {
    final left = _status == LanStatus.ready && status != LanStatus.ready && status != LanStatus.connecting;

    _status = status;
    notifyListeners();

    if (left) onSessionRejected?.call();

    return status;
  }

  @override
  void dispose() {
    unawaited(_feed?.cancel());
    unawaited(_client?.close());
    super.dispose();
  }
}
