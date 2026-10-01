import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lyra_protocol/lyra_protocol.dart';

import 'package:app/toolkit/deployment.dart';
import 'package:app/services/lan/lan_identity_store.dart';
import 'package:app/services/lan/lan_service.dart';

import 'lan_client_test.dart' show FakeMaster, device;

/// The LAN landing's states (plan §7.4): each outcome of connecting lands on the one page that
/// says what to do about it.
void main() {
  setUp(() => Deployment.use(DeploymentMode.local, role: DeploymentRole.client));
  tearDown(() => Deployment.use(DeploymentMode.cloud));

  test('without a pairing it is unpaired', () async {
    final lan = LanService(store: MemoryLanIdentityStore());

    expect(await lan.open(), LanStatus.unpaired);
  });

  test('paired and no session: signedOut; signing in makes it ready', () async {
    final master = FakeMaster();
    final lan = LanService(store: MemoryLanIdentityStore()..stored = device(), connect: (_, _) async => master.connect());

    expect(await lan.open(), LanStatus.signedOut);
    expect(await lan.signIn("ada", "correct horse battery"), LanStatus.ready);
  });

  test('a stored session is picked up without asking again', () async {
    final master = FakeMaster();
    final store = MemoryLanIdentityStore()
      ..stored = device()
      ..refresh = "refresh-1";
    final lan = LanService(store: store, connect: (_, _) async => master.connect());

    expect(await lan.open(), LanStatus.ready);
    expect(store.refresh, "refresh-2");
  });

  test("the master's events reach the services; a reconnect asks for what it missed (protocol-v1.md §5)", () async {
    final master = FakeMaster();
    final got = <(String, Object?)>[];
    var resyncs = 0;
    final lan = LanService(
      store: MemoryLanIdentityStore()
        ..stored = device()
        ..refresh = "refresh-1",
      connect: (_, _) async => master.connect(),
      deliver: (event, data) => got.add((event, data)),
      resync: () => resyncs++,
    );
    List<Object?> subscriptions() => [
      for (final request in master.received) if (request["op"] == "events.subscribe") request["args"],
    ];

    expect(await lan.open(), LanStatus.ready);
    master.emit("table/ready", {"id": "t1", "ok": true});
    master.emit("table/changed", {"id": "t1", "what": "records"});
    await pumpEventQueue();

    expect(got.map((event) => event.$1), ["table/ready", "table/changed"]);
    expect(subscriptions(), [{}]);

    // The connection drops and comes back: the master replays from the last one handed over.
    await master.drop();
    await pumpEventQueue();
    expect(lan.status, LanStatus.ready);
    expect(subscriptions().last, {"since": 2});
    expect(resyncs, 0);

    // Past what the master keeps: every screen reads again, and the stream starts over live.
    master.keptFrom = 10;
    await master.drop();
    await pumpEventQueue();
    expect(subscriptions().sublist(2), [{"since": 2}, {}]);
    expect(resyncs, 1);
  });

  test('a wrong password stays signed out and says why', () async {
    final master = FakeMaster();
    final lan = LanService(store: MemoryLanIdentityStore()..stored = device(), connect: (_, _) async => master.connect());

    await lan.open();

    expect(await lan.signIn("ada", "wrong"), LanStatus.signedOut);
    expect(lan.error, "Wrong username or password.");
  });

  test('a master that does not answer is unreachable; a revoked device is revoked', () async {
    final down = LanService(store: MemoryLanIdentityStore()..stored = device(), connect: (_, _) async {
      throw const SocketException("down");
    });
    final removed = LanService(store: MemoryLanIdentityStore()..stored = device(), connect: (_, _) async {
      throw const RpcError(ErrorCodes.deviceRevoked, "");
    });

    expect(await down.open(), LanStatus.unreachable);
    expect(await removed.open(), LanStatus.revoked);
  });

  test('leaving forgets the pairing and goes back to the cloud', () async {
    final store = MemoryLanIdentityStore()..stored = device();
    final lan = LanService(store: store, connect: (_, _) async => FakeMaster().connect());

    await lan.open();
    await lan.leave();

    expect(store.stored, isNull);
    expect(Deployment.mode, DeploymentMode.cloud);
  });
}
