import 'package:flutter_test/flutter_test.dart';

import 'package:app/toolkit/deployment.dart';
import 'package:app/services/lan/lan_device.dart';
import 'package:app/services/lan/lan_identity_store.dart';

import 'lan_client_test.dart' show device;

/// The mode is never chosen up front (`docs/plan-offline-lan.md` D9): a device is in LAN mode
/// while it holds a pairing, as the master or a client, and is the cloud app otherwise. Leaving
/// the LAN or pairing changes it while the app runs.
void main() {
  tearDown(() => Deployment.use(DeploymentMode.cloud));

  test('a device with no pairing is the cloud app', () async {
    Deployment.use(DeploymentMode.local, role: DeploymentRole.client);

    await Deployment.restore(MemoryLanIdentityStore());

    expect(Deployment.mode, DeploymentMode.cloud);
    expect(Deployment.role, isNull);
  });

  test('a paired device is a client, and the master its own role', () async {
    await Deployment.restore(MemoryLanIdentityStore()..stored = device());

    expect(Deployment.mode, DeploymentMode.local);
    expect(Deployment.role, DeploymentRole.client);

    final master = device();
    await Deployment.restore(MemoryLanIdentityStore()..stored = LanDevice(
      role: DeploymentRole.master,
      instanceId: master.instanceId,
      deviceId: master.deviceId,
      code: master.code,
      caCertificate: master.caCertificate,
      certificate: master.certificate,
      privateKeyPem: master.privateKeyPem,
      hosts: master.hosts,
      port: master.port
    ));

    expect(Deployment.mode, DeploymentMode.local);
    expect(Deployment.role, DeploymentRole.master);
  });

  test('a key store that cannot be read still opens the cloud app', () async {
    await Deployment.restore(_BrokenStore());

    expect(Deployment.mode, DeploymentMode.cloud);
  });

  test('pairing and leaving switch the mode while the app runs', () {
    Deployment.attach(DeploymentRole.client);
    expect((Deployment.mode, Deployment.role), (DeploymentMode.local, DeploymentRole.client));

    Deployment.detach();
    expect((Deployment.mode, Deployment.role), (DeploymentMode.cloud, null));
  });
}

class _BrokenStore extends MemoryLanIdentityStore {
  @override
  Future<LanDevice?> device() => Future.error(StateError("no key store"));
}
