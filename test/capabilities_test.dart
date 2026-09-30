import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/services/permissions/permissions_service.dart';
import 'package:app/toolkit/deployment.dart';

/// Which areas each deployment mode has (`docs/plan-offline-lan.md` §2). The mode is read
/// before any grant, so an area a mode lacks is closed even to an owner, and a cloud area
/// in hybrid waits for the internet instead of disappearing.
void main() {
  tearDown(() {
    Deployment.use(DeploymentMode.cloud);
    CapabilityService().internet = true;
    PermissionsService().clear();
  });

  test('the table is the modes of docs/app-areas.json', () {
    // The json is what the backend and the engine read; the table is what the app reads.
    // Drifting apart would hide in one what the other serves.
    final json = jsonDecode(File("docs/app-areas.json").readAsStringSync()) as Map;
    final declared = <String, Set<String>>{};

    void walk(List areas) {
      for (final area in areas.cast<Map>()) {
        final modes = area["modes"];
        expect(modes, isA<List>(), reason: "${area["key"]} declares no modes");

        declared[area["key"] as String] = {...(modes as List).cast<String>()};
        walk(area["children"] as List? ?? const []);
      }
    }

    walk(json["areas"] as List);

    expect(
      {
        for (final entry in CapabilityService.modes.entries)
          entry.key: {for (final mode in entry.value) mode.name}
      },
      declared
    );
  });

  test('in the cloud every area is open but the local server', () {
    final capabilities = CapabilityService();

    for (final area in CapabilityService.modes.keys) {
      expect(
        capabilities.of(area),
        area == "local_server" ? Capability.hidden : Capability.available,
        reason: area
      );
    }
  });

  test('in local the cloud-only areas are hidden, not waiting', () {
    Deployment.use(DeploymentMode.local, role: DeploymentRole.master);
    final capabilities = CapabilityService();

    expect(capabilities.of("messages"), Capability.hidden);
    expect(capabilities.of("deliveries"), Capability.hidden);
    expect(capabilities.of("finance.receivables"), Capability.hidden);
    expect(capabilities.of("pos"), Capability.available);
    expect(capabilities.of("finance.payments"), Capability.available);
    expect(capabilities.of("local_server"), Capability.available);
  });

  test('in hybrid a cloud area waits for the internet, a master one does not', () {
    Deployment.use(DeploymentMode.hybrid, role: DeploymentRole.client);
    final capabilities = CapabilityService();

    expect(capabilities.of("messages"), Capability.available);
    expect(capabilities.of("deliveries"), Capability.available);

    capabilities.internet = false;

    expect(capabilities.of("messages"), Capability.needsInternet);
    expect(capabilities.shows("messages"), isTrue);
    expect(capabilities.of("deliveries"), Capability.available);
    expect(capabilities.of("pos"), Capability.available);
  });

  test('an action is read from its area, and an unknown area is cloud only', () {
    Deployment.use(DeploymentMode.local, role: DeploymentRole.master);
    final capabilities = CapabilityService();

    expect(capabilities.of("finance.receivables.collect"), Capability.hidden);
    expect(capabilities.of("finance.payments.record"), Capability.available);
    expect(capabilities.of("quantum"), Capability.hidden);
  });

  test('an area the mode lacks is denied even to an owner', () {
    PermissionsService().seed({"b-1": <String, dynamic>{}});
    PermissionsService().own("b-1");

    expect(PermissionsService().can("local_server.devices", business: "b-1"), isFalse);
    expect(PermissionsService().granted("local_server", business: "b-1"), isEmpty);
    expect(PermissionsService().can("messages.view", business: "b-1"), isTrue);

    Deployment.use(DeploymentMode.local, role: DeploymentRole.master);

    expect(PermissionsService().canOpen("messages", business: "b-1"), isFalse);
    expect(PermissionsService().can("local_server.devices", business: "b-1"), isTrue);
  });

  test('outside the cloud no source exists yet', () {
    expect(Sources.session, isNotNull);

    Deployment.use(DeploymentMode.local, role: DeploymentRole.master);

    expect(() => Sources.session, throwsUnsupportedError);
  });
}
