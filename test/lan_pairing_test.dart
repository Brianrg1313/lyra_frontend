import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lyra_protocol/lyra_protocol.dart';

import 'package:app/toolkit/deployment.dart';
import 'package:app/toolkit/lan.dart';
import 'package:app/services/lan/lan_identity_store.dart';
import 'package:app/services/lan/lan_pairing_service.dart';

/// Pairing a client (plan §5.3) against a master that plays its side of `/pair` with the same
/// SPAKE2 the engine runs (`lyra_node/lib/src/net/pairing.dart`, tested there end to end).
void main() {
  tearDown(() => Deployment.use(DeploymentMode.cloud));

  LanPairingService service(MemoryLanIdentityStore store, _ScriptedMaster master) => LanPairingService(
    store: store,
    discover: () async => const [LanFound(name: "lyra-abc", host: "192.168.1.5", port: 4780)],
    open: (host, port) async => LanPairingSocket(master, () async {}),
  );

  test('the right code pairs: the device keeps its certificate and becomes a local client', () async {
    final store = MemoryLanIdentityStore();
    final master = _ScriptedMaster("12345678");

    final failure = await service(store, master).pair(host: "192.168.1.5", port: 4780, code: "12345678", name: "Counter");

    expect(failure, isNull);
    expect(store.stored!.role, DeploymentRole.client);
    expect(store.stored!.hosts, ["192.168.1.5"]);
    expect(store.stored!.code, "C");
    expect(master.enrolledName, "Counter");
    expect(Deployment.mode, DeploymentMode.local);
  });

  test('a wrong code pairs nothing', () async {
    final store = MemoryLanIdentityStore();

    final failure = await service(store, _ScriptedMaster("12345678"))
      .pair(host: "192.168.1.5", port: 4780, code: "87654321", name: "Counter");

    expect(failure, LanPairingError.wrongCode);
    expect(store.stored, isNull);
    expect(Deployment.mode, DeploymentMode.cloud);
  });

  test('a certificate other than the one TLS showed is someone in the middle', () async {
    final store = MemoryLanIdentityStore();
    final master = _ScriptedMaster("12345678", seen: "not-the-one-announced");

    final failure = await service(store, master).pair(host: "192.168.1.5", port: 4780, code: "12345678", name: "Counter");

    expect(failure, LanPairingError.wrongMaster);
    expect(store.stored, isNull);
  });

  group('a scanned QR', () {
    PairingOffer offer({String? caFingerprint}) => PairingOffer(
      instanceId: _ScriptedMaster.instanceId,
      addresses: const ["10.0.0.9", "192.168.1.5"],
      port: 4780,
      caFingerprint: caFingerprint ?? Fingerprint.of(utf8.encode("ca")),
      token: "the-qr-token",
    );

    test('pairs with its token, on the first of its addresses that answers', () async {
      final store = MemoryLanIdentityStore();
      final tried = <String>[];
      final pairing = LanPairingService(store: store, open: (host, port) async {
        tried.add(host);
        if (host == "10.0.0.9") throw StateError("no route");
        return LanPairingSocket(_ScriptedMaster("the-qr-token"), () async {});
      });

      expect(await pairing.pairScanned(offer(), name: "Phone"), isNull);
      expect(tried, ["10.0.0.9", "192.168.1.5"]);
      expect(store.stored!.hosts, ["192.168.1.5"]);
    });

    test('a CA other than the one in the QR is someone in the middle; no other address is tried', () async {
      final tried = <String>[];
      final pairing = LanPairingService(store: MemoryLanIdentityStore(), open: (host, port) async {
        tried.add(host);
        return LanPairingSocket(_ScriptedMaster("the-qr-token"), () async {});
      });

      expect(await pairing.pairScanned(offer(caFingerprint: "0" * 64), name: "Phone"), LanPairingError.wrongMaster);
      expect(tried, ["10.0.0.9"]);
    });
  });

  test('a browser keeps no certificate and no PEM: its WebCrypto key is kept apart', () async {
    final store = MemoryLanIdentityStore();
    final key = _BrowserKey();
    final pairing = LanPairingService(
      store: store,
      open: (host, port) async => LanPairingSocket(_ScriptedMaster("12345678", seen: null, browser: true), () async {}),
      newKey: () async => key,
    );

    expect(await pairing.pair(host: "192.168.1.5", port: 4780, code: "12345678", name: "Browser"), isNull);
    expect(key.kept, isTrue);
    expect(store.stored!.certificate, isEmpty);
    expect(store.stored!.privateKeyPem, isEmpty);
  });

  group('the password way', () {
    LanPairingService byPassword(MemoryLanIdentityStore store, _ScriptedMaster master) =>
      LanPairingService(store: store, open: (host, port) async => LanPairingSocket(master, () async {}));

    test("an account's login and password pair: no code, the device is a local client", () async {
      final store = MemoryLanIdentityStore();
      final master = _ScriptedMaster.password("correct horse battery");

      final failure = await byPassword(store, master)
        .pairWithPassword(host: "192.168.1.5", port: 4780, login: "ada@lyra.app", password: "correct horse battery");

      expect(failure, isNull);
      expect(master.login, "ada@lyra.app");
      expect(master.enrolledName, lanDeviceName);
      expect(store.stored!.role, DeploymentRole.client);
      expect(Deployment.mode, DeploymentMode.local);
    });

    test('a wrong password pairs nothing', () async {
      final store = MemoryLanIdentityStore();

      final failure = await byPassword(store, _ScriptedMaster.password("correct horse battery"))
        .pairWithPassword(host: "192.168.1.5", port: 4780, login: "ada@lyra.app", password: "wrong horse battery");

      expect(failure, LanPairingError.wrongCode);
      expect(store.stored, isNull);
    });

    test('a locked account says so', () async {
      final failure = await byPassword(MemoryLanIdentityStore(), _ScriptedMaster.password("x", locked: true))
        .pairWithPassword(host: "192.168.1.5", port: 4780, login: "ada@lyra.app", password: "x");

      expect(failure, LanPairingError.locked);
    });
  });

  test('servers found by mDNS are listed', () async {
    final pairing = service(MemoryLanIdentityStore(), _ScriptedMaster("1"));

    await pairing.search();

    expect(pairing.found.single.host, "192.168.1.5");
  });
}

/// The master's side of `/pair`, scripted: hello, reply, then `paired` with a made-up CA.
class _ScriptedMaster implements PairingChannel {
  _ScriptedMaster(this.code, {String? seen = "", this.browser = false})
    : serverFingerprint = seen == "" ? _serverFingerprint : seen;

  /// The password way: the secret is the password's digest under [salt], as the engine keeps it.
  factory _ScriptedMaster.password(String password, {bool locked = false}) =>
    _ScriptedMaster(salt.secretOf(password))..locked = locked;

  static final salt = PasswordSalt(salt: Uint8List.fromList(List.generate(16, (i) => i)), memory: 64, iterations: 1, parallelism: 1, length: 32);

  /// Answers `account_locked` to the account step.
  bool locked = false;
  String? login;

  /// A browser pairs through the page's TLS, which shows no certificate, and gets none.
  final bool browser;

  static const instanceId = "0192f0aa-1111-7000-8000-000000000001";
  static final _server = utf8.encode("server certificate");
  static final _serverFingerprint = Fingerprint.of(_server);

  final String code;
  final StreamController<Map<String, Object?>> _toDevice = StreamController();
  late final StreamIterator<Map<String, Object?>> _reader = StreamIterator(_toDevice.stream);
  Spake2? _spake;
  Spake2Keys? _keys;
  String? enrolledName;

  @override
  final String? serverFingerprint;

  bool _helloSent = false;

  @override
  Future<Map<String, Object?>> receive() async {
    if (!_helloSent) {
      _helloSent = true;
      return {"step": "hello", "instanceId": instanceId, "protocol": protocolVersion};
    }

    await _reader.moveNext();
    return _reader.current;
  }

  @override
  void send(Map<String, Object?> message) {
    switch (message["step"]) {
      case "account":
        login = message["login"] as String;
        _toDevice.add(locked ? {"step": "failed", "code": Pairing.accountLocked} : {"step": "salt", ...salt.toJson()});
      case "start":
        _spake = Spake2.b(Spake2.passwordScalar(code, instanceId: instanceId), idA: Pairing.idDevice, idB: instanceId, aad: Pairing.aad);
        _keys = _spake!.finish(base64.decode(message["pA"] as String));
        _toDevice.add({"step": "reply", "pB": base64.encode(_spake!.message)});
      case "enroll":
        if (!_keys!.checkPeer(base64.decode(message["confirm"] as String))) {
          _toDevice.add({"step": "failed", "code": Pairing.failed});
          return;
        }

        final macKey = _keys!.derive(Pairing.macPurpose);
        enrolledName = (Pairing.open(message, macKey)!["device"] as Map)["name"] as String;
        _toDevice.add(Pairing.seal({
          "step": "paired",
          "confirm": base64.encode(_keys!.confirmation),
          "instanceId": instanceId,
          "caCertificate": base64.encode(utf8.encode("ca")),
          "serverFingerprint": _serverFingerprint,
          "certificate": browser ? null : base64.encode(utf8.encode("device certificate")),
          "deviceId": "d3",
          "deviceCode": "C",
        }, macKey));
    }
  }
}

/// A browser's device key, as `lan_web.dart` makes it: no PEM, kept on its own.
class _BrowserKey implements LanDeviceKey {
  final _key = EcKeyPair.generate();
  bool kept = false;

  @override
  Uint8List get spki => _key.spki;

  @override
  Future<Uint8List> sign(List<int> message) async => _key.sign(message);

  @override
  String? get privateKeyPem => null;

  @override
  Future<void> keep() async => kept = true;
}
