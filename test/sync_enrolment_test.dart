import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';
import 'package:lyra_protocol/lyra_protocol.dart';
import 'package:app/toolkit/backend/deployment.dart';
import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/services/connection/cloud_presence.dart';
import 'package:app/services/lan/hybrid_service.dart';
import 'package:app/services/lan/lan_identity_store.dart';
import 'package:app/services/lan/lan_service.dart';
import 'package:app/services/lan/sync_cloud_source.dart';
import 'package:app/services/lan/sync_service.dart';

/// The master enrols with the backend by itself (`business.md` B-33 to B-36): the owner online
/// with the company linked is enough; only a branch held by another server, or a server someone
/// unlinked, waits for the owner.
void main() {
  setUpAll(() => AppController.devMode = true);
  setUp(() => Deployment.use(DeploymentMode.cloud, paired: DeploymentRole.master));
  tearDown(() {
    Deployment.use(DeploymentMode.cloud);
    CapabilityService().internet = true;
    CapabilityService().linked = true;
  });

  Future<(SyncService, HybridService)> start(_Master master, _Cloud cloud, {bool owner = true}) async {
    final hybrid = HybridService(lan: master, presence: _Presence(true));
    final sync = SyncService(lan: master, hybrid: hybrid, cloud: cloud, owner: () => owner);
    addTearDown(() {
      sync.dispose();
      hybrid.dispose();
    });

    await hybrid.resume();
    await pumpEventQueue();
    return (sync, hybrid);
  }

  test('the owner online with the company linked enrols the master, once, asking nothing', () async {
    final master = _Master();
    final cloud = _Cloud();
    final (sync, _) = await start(master, cloud);

    expect(cloud.sent.single.key, {"publicKey": "pk", "instance": "i-1", "engine": "0.2.0", "name": "FRONT-DESK"});
    expect(cloud.sent.single.replace, isFalse);
    expect(master.enrolledWith, cloud.answer);
    expect(sync.state?.syncing, isTrue);
    expect(sync.taken, isFalse);

    CapabilityService().internet = false;
    CapabilityService().internet = true;
    await pumpEventQueue();
    expect(cloud.sent, hasLength(1));
  });

  test('an unlinked company waits for the link, then enrols', () async {
    CapabilityService().linked = false;
    final cloud = _Cloud();
    await start(_Master(), cloud);
    expect(cloud.sent, isEmpty);

    CapabilityService().linked = true;
    await pumpEventQueue();
    expect(cloud.sent, hasLength(1));
  });

  test("someone who isn't the owner, or a master already enrolled, enrols nothing", () async {
    final cloud = _Cloud();
    await start(_Master(), cloud, owner: false);
    expect(cloud.sent, isEmpty);

    Deployment.use(DeploymentMode.cloud, paired: DeploymentRole.master);
    await start(_Master(status: {"enrolled": true, "revoked": false, "lastSync": "2026-10-04T10:00:00Z"}), cloud);
    expect(cloud.sent, isEmpty);
  });

  test('a server someone unlinked is never enrolled again by itself, only by the owner (B-36)', () async {
    final master = _Master(status: {"enrolled": true, "revoked": true});
    final cloud = _Cloud();
    final (sync, _) = await start(master, cloud);

    expect(sync.state?.revoked, isTrue);
    expect(cloud.sent, isEmpty);

    expect(await sync.enrol(), isTrue);
    expect(cloud.sent, hasLength(1));
    expect(sync.state?.syncing, isTrue);
  });

  test("a branch another server syncs waits for the owner, who replaces it in one step", () async {
    final master = _Master();
    final cloud = _Cloud(taken: true);
    final (sync, _) = await start(master, cloud);

    expect(sync.taken, isTrue);
    expect(master.enrolledWith, isNull);

    expect(await sync.enrol(replace: true), isTrue);
    expect(cloud.sent.last.replace, isTrue);
    expect(sync.taken, isFalse);
    expect(master.enrolledWith, cloud.answer);
  });

  test('a failure of the network is tried again when the internet comes back', () async {
    final cloud = _Cloud(failures: 1);
    final (sync, _) = await start(_Master(), cloud);
    expect(sync.state?.enrolled, isFalse);
    expect(sync.taken, isFalse);

    CapabilityService().internet = false;
    CapabilityService().internet = true;
    await pumpEventQueue();
    expect(cloud.sent, hasLength(2));
    expect(sync.state?.syncing, isTrue);
  });
}

/// The master's engine as far as the sync ops go, with a session kept.
class _Master extends LanService {
  _Master({Map<String, Object?> status = const {"enrolled": false}}) : _status = status, super(store: MemoryLanIdentityStore());

  Map<String, Object?> _status;
  Map<String, Object?>? enrolledWith;
  LanStatus _now = LanStatus.idle;

  @override
  LanStatus get status => _now;

  @override
  Future<LanStatus> open() async => _now = LanStatus.ready;

  @override
  Future<Object?> call(Op op, {Map<String, Object?> args = const {}}) async {
    switch (op) {
      case Ops.syncStatus:
        return _status;
      case Ops.syncPrepare:
        return {"publicKey": "pk", "instance": "i-1", "engine": "0.2.0", "name": "FRONT-DESK"};
      case Ops.syncEnroll:
        enrolledWith = args;
        return _status = {"enrolled": true, "revoked": false, "device": args["device"]};
      default:
        return null;
    }
  }
}

/// `POST /edge/v1/devices`, answering as the backend does.
class _Cloud extends SyncCloudSource {
  _Cloud({this.taken = false, this.failures = 0});

  bool taken;
  int failures;
  final sent = <({Map<String, Object?> key, bool replace})>[];

  final answer = <String, Object?>{
    "device": "d-1", "company": "c-1", "site": "s-1",
    "edgeKey": {"kid": "2026-10", "publicKey": "k"}, "allowance": "within", "endpoint": "https://api.test/edge/v1"
  };

  @override
  Future<Map<String, Object?>> enrol(Map<String, Object?> key, {bool replace = false}) async {
    sent.add((key: key, replace: replace));
    if (failures > 0) {
      failures--;
      throw {"message": "No connection", "action": null};
    }
    if (taken && !replace) throw {"message": "That branch already has a linked server", "action": "site_has_master"};

    taken = false;
    return answer;
  }
}

class _Presence extends CloudPresence {
  _Presence([bool? live]) {
    this.live.value = live;
  }

  @override
  void start() {}

  @override
  void stop() {}
}
