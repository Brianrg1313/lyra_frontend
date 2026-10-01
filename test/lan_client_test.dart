import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lyra_protocol/lyra_protocol.dart';

import 'package:app/toolkit/deployment.dart';
import 'package:app/toolkit/lan.dart';
import 'package:app/services/lan/lan_device.dart';
import 'package:app/services/lan/lan_identity_store.dart';

/// The app's end of `/rpc` (`docs/offline/protocol-v1.md` §4): hello on every connect, the
/// session bound after sign in, a silent refresh, and failures in the api layer's shape. The
/// real transport and the real master are tested in `lyra_node/test/net_test.dart`.
void main() {
  test('lanAppVersion is the pubspec version', () {
    final pubspec = File("pubspec.yaml").readAsStringSync();
    final version = RegExp(r"^version: (\d+\.\d+\.\d+)", multiLine: true).firstMatch(pubspec)!.group(1);

    expect(lanAppVersion, version);
  });

  test('tries the known addresses in order and puts the one that answered first', () async {
    final store = MemoryLanIdentityStore();
    final master = FakeMaster();
    final client = LanClient(device(hosts: ["10.0.0.9", "192.168.1.5"]), store: store, connect: (device, host) async {
      if (host == "10.0.0.9") throw const SocketException("no route");
      return master.connect();
    });

    final hello = await client.connect();

    expect(hello.state, EngineState.ready);
    expect(master.received.first["op"], "hello");
    expect((master.received.first["args"] as Map)["app"], lanAppVersion);
    expect(store.stored!.hosts, ["192.168.1.5", "10.0.0.9"]);
  });

  test('no address answering is LanUnreachable', () async {
    final client = LanClient(device(), store: MemoryLanIdentityStore(), connect: (device, host) async {
      throw const SocketException("down");
    });

    await expectLater(client.connect(), throwsA(isA<LanUnreachable>()));
  });

  test('signs in, keeps only the refresh token, and binds the session', () async {
    final store = MemoryLanIdentityStore();
    final master = FakeMaster();
    final client = LanClient(device(), store: store, connect: (_, _) async => master.connect());

    expect(await client.signIn("ada", "correct horse battery"), isFalse);
    expect(store.refresh, "refresh-1");
    expect(master.received.map((frame) => frame["op"]), ["hello", "auth.signIn", "session.bind"]);
    expect(client.accountId, "owner");
  });

  test('a session the master says expired is refreshed once and the op sent again', () async {
    final store = MemoryLanIdentityStore();
    final master = FakeMaster();
    final client = LanClient(device(), store: store, connect: (_, _) async => master.connect());

    await client.signIn("ada", "correct horse battery");
    master.expireNext = true;

    expect(await client.call(Ops.devicesList), isEmpty);
    expect(store.refresh, "refresh-2");
    expect(
      master.received.map((frame) => frame["op"]).skip(3),
      ["devices.list", "auth.refresh", "session.bind", "devices.list"],
    );
  });

  group('a browser', () {
    test('signs the hello challenge with its key before anything else', () async {
      final key = EcKeyPair.generate();
      final master = FakeMaster()..browserKey = key.spki;
      final client = LanClient(device(), store: MemoryLanIdentityStore(), connect: (_, _) async => master.connect(),
        prove: (_, message) async => key.sign(message));

      await client.signIn("ada", "correct horse battery");

      expect(master.received.map((frame) => frame["op"]), ["hello", "device.prove", "auth.signIn", "session.bind"]);
      expect(master.proved, isTrue);
    });

    test('with no key left, or one the master refuses, is a removed device', () async {
      final master = FakeMaster()..browserKey = EcKeyPair.generate().spki;
      final lost = LanClient(device(), store: MemoryLanIdentityStore(), connect: (_, _) async => master.connect(),
        prove: (_, _) async => null);
      final other = LanClient(device(), store: MemoryLanIdentityStore(), connect: (_, _) async => master.connect(),
        prove: (_, message) async => EcKeyPair.generate().sign(message));

      await expectLater(lost.connect(), throwsA(containsPair("code", ErrorCodes.deviceRevoked)));
      await expectLater(other.connect(), throwsA(containsPair("code", ErrorCodes.deviceRevoked)));
    });
  });

  test('a refusal comes as the api layer throws it, {message, action, code}', () async {
    final master = FakeMaster();
    final client = LanClient(device(), store: MemoryLanIdentityStore(), connect: (_, _) async => master.connect());

    await expectLater(
      client.signIn("ada", "wrong"),
      throwsA(allOf(
        containsPair("code", "invalid_credentials"),
        containsPair("message", "Wrong username or password."),
      )),
    );
  });

  group('files (/f)', () {
    late FakeMaster master;
    late List<(String, String, String, Map<String, String>)> sent;
    late List<LanFileResponse> answers;

    LanClient client() => LanClient(device(), store: MemoryLanIdentityStore(), connect: (_, _) async => master.connect(),
      files: (device, host, method, path, {required token, headers = const {}, body}) async {
        sent.add((method, path, token, headers));
        return answers.removeAt(0);
      });

    LanFileResponse json(int status, Object body) => (status: status, body: Uint8List.fromList(utf8.encode(jsonEncode(body))));

    setUp(() {
      master = FakeMaster();
      sent = [];
      answers = [];
    });

    test('a download carries the session token and asks for the thumbnail by size', () async {
      final lan = client();
      await lan.signIn("ada", "correct horse battery");
      answers.add((status: 200, body: Uint8List.fromList([1, 2, 3])));

      expect(await lan.download("f1", size: 320), [1, 2, 3]);
      expect(sent.single.$1, "GET");
      expect(sent.single.$2, "/f/f1?size=320");
      expect(sent.single.$3, "access-1");
    });

    test('an upload names its purpose and answers the fileId', () async {
      final lan = client();
      await lan.signIn("ada", "correct horse battery");
      answers.add(json(200, {"fileId": "f9"}));

      expect(await lan.upload("product_image", Uint8List.fromList([9])), "f9");
      expect(sent.single.$4, {"X-Lyra-Purpose": "product_image"});
    });

    test('an expired token is refreshed once; a refusal comes in the api layer shape', () async {
      final lan = client();
      await lan.signIn("ada", "correct horse battery");
      answers
        ..add(json(401, {"code": "session_expired", "message": "Sign in again.", "action": "login"}))
        ..add((status: 200, body: Uint8List.fromList([7])))
        ..add(json(404, {"code": "not_found", "message": "It doesn't exist or you can't see it."}));

      expect(await lan.download("f1"), [7]);
      expect(sent.map((request) => request.$3), ["access-1", "access-2"]);
      await expectLater(lan.download("gone"), throwsA(predicate((Object? error) => error is Map && error["code"] == "not_found")));
    });

    test('a master that does not answer the file request is unreachable', () async {
      final lan = LanClient(device(), store: MemoryLanIdentityStore(), connect: (_, _) async => master.connect(),
        files: (device, host, method, path, {required token, headers = const {}, body}) async => throw const LanFileUnreachable());
      await lan.signIn("ada", "correct horse battery");

      await expectLater(lan.download("f1"), throwsA(isA<LanUnreachable>()));
    });
  });
}

LanDevice device({List<String> hosts = const ["127.0.0.1"]}) => LanDevice(
  role: DeploymentRole.client,
  instanceId: "i1",
  deviceId: "d1",
  code: "B",
  caCertificate: Uint8List(0),
  certificate: Uint8List(0),
  privateKeyPem: "",
  hosts: hosts,
  port: 4780,
);

/// A master that answers the handful of ops the client uses, over an in-memory socket.
class FakeMaster {
  final List<Map<String, Object?>> received = [];
  bool locked = false;

  /// Set: the client is a browser whose key this is; `hello` carries a challenge.
  Uint8List? browserKey;
  final Uint8List _challenge = Uint8List.fromList(List.generate(32, (i) => i));
  bool proved = false;
  bool expireNext = false;
  int _refreshes = 1;

  /// The last event seq emitted, and the oldest one still kept for a replay.
  int head = 0;
  int keptFrom = 0;
  _Socket? _socket;

  RpcClient connect() => RpcClient(_socket = _Socket(this));

  /// Sends an event to the open connection, as after `events.subscribe`.
  void emit(String event, Object? data) => _socket!._out.add(RpcEvent(event: event, seq: ++head, data: data).encode());

  /// Closes the connection from the master's side (a restart, a network change).
  Future<void> drop() => _socket!._out.close();

  Object? answer(Map<String, Object?> request) {
    final args = request["args"] as Map<String, Object?>? ?? const {};

    switch (request["op"]) {
      case "hello":
        return HelloAnswer(
          protocol: 1,
          engine: "0.2.0",
          minApp: "0.0.6",
          instanceId: "i1",
          state: locked ? EngineState.locked : EngineState.ready,
          challenge: browserKey == null ? null : _challenge,
        ).toJson();
      case "device.prove":
        final signature = base64.decode(args["signature"] as String);
        if (!P256.verify(browserKey!, DeviceProof.message("i1", _challenge), signature)) {
          throw const RpcError("forbidden", "Not a paired device.");
        }
        proved = true;
        return {"deviceId": args["deviceId"], "code": "B"};
      case "auth.signIn":
        if (args["password"] != "correct horse battery") {
          throw const RpcError("invalid_credentials", "Wrong username or password.");
        }
        return _tokens();
      case "auth.activate":
        if (args["code"] != "12345678") throw const RpcError("invalid_code", "That code isn't valid.");
        return _tokens();
      case "auth.refresh":
        return _tokens(++_refreshes);
      case "events.subscribe":
        final since = args["since"] as int?;
        if (since != null && since < keptFrom) throw const RpcError("resync_required", "");
        return {"head": head};
      case "session.bind":
        return {"accountId": "owner", "expires": "2030-01-01T00:00:00Z"};
      case "devices.browserCa":
        return {
          "certificate": base64.encode(utf8.encode("browser root")),
          "fingerprint": "ab" * 32,
          "thumbprint": "cd" * 20,
          "addresses": ["192.168.1.5"],
          "port": 4780,
        };
      case "devices.list":
        if (expireNext) {
          expireNext = false;
          throw const RpcError("session_expired", "Sign in again.", action: "login");
        }
        return const [];
    }

    throw const RpcError("unknown_op", "");
  }

  Map<String, Object?> _tokens([int n = 1]) => {
    "accessToken": "access-$n",
    "accessExpires": DateTime.now().add(const Duration(minutes: 15)).toUtc().toIso8601String(),
    "refreshToken": "refresh-$n",
    "refreshExpires": "2030-01-01T00:00:00Z",
    "accountId": "owner",
    "mustChangePassword": false,
  };
}

class _Socket implements FrameSocket {
  _Socket(this._master);

  final FakeMaster _master;
  final StreamController<String> _out = StreamController();

  @override
  Stream<String> get frames => _out.stream;

  @override
  void send(String frame) {
    final request = jsonDecode(frame) as Map<String, Object?>;
    _master.received.add(request);

    final id = request["id"] as int;
    try {
      _out.add(RpcResponse.ok(id, _master.answer(request)).encode());
    } on RpcError catch (error) {
      _out.add(RpcResponse.failed(id, error).encode());
    }
  }

  @override
  Future<void> close() => _out.close();
}
