import 'dart:async';
import 'dart:convert';

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

  test('servers found by mDNS are listed', () async {
    final pairing = service(MemoryLanIdentityStore(), _ScriptedMaster("1"));

    await pairing.search();

    expect(pairing.found.single.host, "192.168.1.5");
  });
}

/// The master's side of `/pair`, scripted: hello, reply, then `paired` with a made-up CA.
class _ScriptedMaster implements PairingChannel {
  _ScriptedMaster(this.code, {String? seen}) : serverFingerprint = seen ?? _serverFingerprint;

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
          "certificate": base64.encode(utf8.encode("device certificate")),
          "deviceId": "d3",
          "deviceCode": "C",
        }, macKey));
    }
  }
}
