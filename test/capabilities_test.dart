import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/services/permissions/permissions_service.dart';
import 'package:app/toolkit/deployment.dart';
import 'package:app/services/client/sources/session_lan_source.dart';
import 'package:app/services/business/sources/business_lan_source.dart';
import 'package:app/services/business/sources/employees_lan_source.dart';
import 'package:app/services/pos/sources/pos_lan_source.dart';
import 'package:app/services/money/sources/money_lan_source.dart';
import 'package:app/services/sales/sources/sales_lan_source.dart';

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
        for (final action in (area["action_modes"] as Map? ?? const {}).entries) {
          declared["${area["key"]}.${action.key}"] = {...(action.value as List).cast<String>()};
        }
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

  test('in the cloud every area is open but those of a master (its server, the accounting export)', () {
    final capabilities = CapabilityService();

    for (final area in CapabilityService.modes.keys) {
      expect(
        capabilities.of(area),
        area == "local_server" || area == "finance.export" ? Capability.hidden : Capability.available,
        reason: area
      );
    }
    expect(capabilities.singleCompany, isFalse);
  });

  test('in local the cloud-only areas are hidden, not waiting', () {
    Deployment.use(DeploymentMode.local, role: DeploymentRole.master);
    final capabilities = CapabilityService();

    expect(capabilities.of("messages"), Capability.hidden);
    expect(capabilities.of("deliveries"), Capability.hidden);
    expect(capabilities.of("finance.receivables"), Capability.hidden);
    // What Lyra's assistant cost is measured in the cloud.
    expect(capabilities.of("finance.overview.view_bot_cost"), Capability.hidden);
    expect(capabilities.of("business.branches"), Capability.hidden);
    expect(capabilities.of("business.delete"), Capability.hidden);
    expect(capabilities.of("business.settings.manage_emails"), Capability.hidden);
    expect(capabilities.of("business.settings.edit"), Capability.available);
    expect(capabilities.of("local_server"), Capability.available);
    expect(capabilities.singleCompany, isTrue);
  });

  test('on a master, a local area waits for its phase 4 release', () {
    Deployment.use(DeploymentMode.local, role: DeploymentRole.client);
    final capabilities = CapabilityService();

    // Built: the business domain, inventory (importing too), stock, the POS, the sales board and
    // finance's summary, payments, accounts and the accounting export.
    expect(capabilities.of("business"), Capability.available);
    expect(capabilities.of("business.settings"), Capability.available);
    expect(capabilities.of("business.settings.edit_logo"), Capability.available);
    expect(capabilities.of("inventory"), Capability.available);
    expect(capabilities.of("inventory.move_stock"), Capability.available);
    expect(capabilities.of("inventory.import"), Capability.available);
    expect(capabilities.of("pos"), Capability.available);
    expect(capabilities.of("pos.checkout"), Capability.available);
    expect(capabilities.of("sales.done"), Capability.available);
    expect(capabilities.of("sales.fulfil"), Capability.available);
    // Approving a payment is about conversations, which a master has none of.
    expect(capabilities.of("sales.approve"), Capability.hidden);
    expect(capabilities.of("finance"), Capability.available);
    expect(capabilities.of("finance.overview"), Capability.available);
    expect(capabilities.of("finance.payments.void"), Capability.available);
    expect(capabilities.of("finance.methods"), Capability.available);
    expect(capabilities.of("finance.methods.manage_currencies"), Capability.available);
    expect(capabilities.of("finance.export"), Capability.available);
    expect(capabilities.of("business.employees"), Capability.available);
    expect(capabilities.of("business.employees.view_personal"), Capability.available);
    // The address search is the cloud's (places).
    expect(capabilities.cloudServices, isFalse);
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
    expect(capabilities.of("business.settings"), Capability.available);
    expect(capabilities.cloudServices, isFalse);
  });

  test('an action is read from its area, and an unknown area is cloud only', () {
    Deployment.use(DeploymentMode.local, role: DeploymentRole.master);
    final capabilities = CapabilityService();

    expect(capabilities.of("finance.receivables.collect"), Capability.hidden);
    expect(capabilities.of("business.settings.edit"), Capability.available);
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

  test('outside the cloud only the built domains have a source', () {
    expect(Sources.money, isNotNull);

    Deployment.use(DeploymentMode.local, role: DeploymentRole.master);

    expect(Sources.session, isA<SessionLanSource>());
    expect(Sources.business, isA<BusinessLanSource>());
    expect(Sources.pos, isA<PosLanSource>());
    expect(Sources.sales, isA<SalesLanSource>());
    expect(Sources.money, isA<MoneyLanSource>());
    expect(Sources.employees, isA<EmployeesLanSource>());
    expect(() => Sources.delivery, throwsUnsupportedError);
  });
}
