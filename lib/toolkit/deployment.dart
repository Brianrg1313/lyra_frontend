import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/preferences/preferences_service.dart';
import 'package:app/toolkit/lan.dart' show lanSupported;
import 'package:app/services/client/sources/session_source.dart';
import 'package:app/services/client/sources/session_cloud_source.dart';
import 'package:app/services/client/sources/session_lan_source.dart';
import 'package:app/services/business/sources/business_source.dart';
import 'package:app/services/business/sources/business_cloud_source.dart';
import 'package:app/services/business/sources/business_lan_source.dart';
import 'package:app/services/business/sources/employees_source.dart';
import 'package:app/services/business/sources/employees_cloud_source.dart';
import 'package:app/services/business/sources/delivery_source.dart';
import 'package:app/services/business/sources/delivery_cloud_source.dart';
import 'package:app/services/stock/sources/inventory_source.dart';
import 'package:app/services/stock/sources/inventory_cloud_source.dart';
import 'package:app/services/stock/sources/inventory_lan_source.dart';
import 'package:app/services/stock/sources/stock_source.dart';
import 'package:app/services/stock/sources/stock_cloud_source.dart';
import 'package:app/services/stock/sources/stock_lan_source.dart';
import 'package:app/services/pos/sources/pos_source.dart';
import 'package:app/services/pos/sources/pos_cloud_source.dart';
import 'package:app/services/pos/sources/pos_lan_source.dart';
import 'package:app/services/sales/sources/sales_source.dart';
import 'package:app/services/sales/sources/sales_cloud_source.dart';
import 'package:app/services/sales/sources/sales_lan_source.dart';
import 'package:app/services/money/sources/money_source.dart';
import 'package:app/services/money/sources/money_cloud_source.dart';
import 'package:app/services/money/sources/money_lan_source.dart';
import 'package:app/toolkit/settings/initial_builder.dart' show lanService;

/// Where the company's data lives (`docs/plan-offline-lan.md` §7).
///
/// - [cloud]: today's app, the backend over the internet.
/// - [local]: one desktop install is the master and serves the LAN, no cloud.
/// - [hybrid]: the master serves the LAN and syncs with the cloud.
///
/// [local] is part of every build ([Deployment.lanEnabled]). [hybrid] needs
/// phase 6.
enum DeploymentMode { cloud, local, hybrid }

/// What this install is in a LAN deployment. Meaningless in [DeploymentMode.cloud].
enum DeploymentRole { master, client }

/// The mode this install runs in.
///
/// It reaches the sources ([Sources]) and the capability table
/// (`CapabilityService`), never a screen: screens don't know the mode (plan
/// principle 8).
abstract final class Deployment {
  static DeploymentMode _mode = DeploymentMode.cloud;
  static DeploymentRole? _role;

  static DeploymentMode get mode => _mode;

  /// Null in [DeploymentMode.cloud].
  static DeploymentRole? get role => _role;

  /// Whether this install offers LAN mode: every native one, and the page a
  /// master serves (plan §3). The same build is the cloud app everywhere else:
  /// a browser on the cloud's site never sees it, whatever the preferences say.
  static bool get lanEnabled => lanSupported;

  /// Whether this install has chosen a mode yet (a fresh install asks, plan §7.4).
  static bool get chosen => PreferencesService().deployment != null;

  /// Reads the mode chosen on this device (`preCall`, before the first route).
  static void restore() {
    final stored = PreferencesService().deployment?.split("/");
    final mode = DeploymentMode.values.asNameMap()[stored?.first];
    final role = stored != null && stored.length > 1 ? DeploymentRole.values.asNameMap()[stored[1]] : null;

    if (mode == null || mode == DeploymentMode.cloud || !lanEnabled || role == null) {
      _mode = DeploymentMode.cloud;
      _role = null;
    } else {
      _mode = mode;
      _role = role;
    }
  }

  /// Makes [mode] this device's mode from now on (the setup screens).
  static void choose(DeploymentMode mode, {DeploymentRole? role}) {
    use(mode, role: role);
    PreferencesService().deployment = mode == DeploymentMode.cloud ? mode.name : "${mode.name}/${role!.name}";
  }

  /// Forgets the choice: the next start asks again. A browser leaving LAN mode
  /// does this, as the page it runs from is the master's and has no cloud.
  static void forget() {
    use(DeploymentMode.cloud);
    PreferencesService().deployment = null;
  }

  @visibleForTesting
  static void use(DeploymentMode mode, {DeploymentRole? role}) {
    _mode = mode;
    _role = mode == DeploymentMode.cloud ? null : role;
  }
}

/// The one place that picks each domain's source for the running mode.
///
/// A service reads its source from here unless a test hands it one. Cloud
/// sources hold no state, so the same instance serves every service.
abstract final class Sources {
  static SessionSource get session => _pick(const SessionCloudSource(), () => SessionLanSource(lanService));
  static BusinessSource get business => _pick(const BusinessCloudSource(), () => BusinessLanSource(lanService));
  static EmployeesSource get employees => _pick(const EmployeesCloudSource());
  static DeliverySource get delivery => _pick(const DeliveryCloudSource());
  static InventorySource get inventory => _pick(const InventoryCloudSource(), () => InventoryLanSource(lanService));
  static StockSource get stock => _pick(const StockCloudSource(), () => StockLanSource(lanService));
  static PosSource get pos => _pick(const PosCloudSource(), () => PosLanSource(lanService));
  static SalesSource get sales => _pick(const SalesCloudSource(), () => SalesLanSource(lanService));
  static MoneySource get money => _pick(const MoneyCloudSource(), () => MoneyLanSource(lanService));

  /// LAN sources arrive one domain per release (plan phase 4), over the one
  /// connection [lanService] holds. A domain without one yet is hidden on a
  /// master's devices (`CapabilityService`), so a call getting here without a
  /// [lan] source is a bug, not a state to recover from.
  static T _pick<T>(T cloud, [T Function()? lan]) => switch (Deployment.mode) {
    DeploymentMode.cloud => cloud,
    DeploymentMode.local || DeploymentMode.hybrid =>
      lan?.call() ?? (throw UnsupportedError("No LAN source for $T yet"))
  };
}

/// An answer that arrived but is not the shape its model reads.
///
/// Thrown by a source so its service takes the same path as for a failed
/// request, which is what an unreadable answer always was. It carries no
/// `message`, so `FloatFlag.showFromError` shows nothing for it, as before.
class UnreadableAnswer implements Exception {
  const UnreadableAnswer(this.what);

  /// Which read it was, for the debug log.
  final String what;

  @override
  String toString() => "UnreadableAnswer($what)";
}
