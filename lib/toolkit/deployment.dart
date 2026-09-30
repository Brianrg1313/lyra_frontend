import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/preferences/preferences_service.dart';
import 'package:app/toolkit/lan.dart' show lanSupported;
import 'package:app/services/client/sources/session_source.dart';
import 'package:app/services/client/sources/session_cloud_source.dart';
import 'package:app/services/business/sources/business_source.dart';
import 'package:app/services/business/sources/business_cloud_source.dart';
import 'package:app/services/business/sources/employees_source.dart';
import 'package:app/services/business/sources/employees_cloud_source.dart';
import 'package:app/services/business/sources/delivery_source.dart';
import 'package:app/services/business/sources/delivery_cloud_source.dart';
import 'package:app/services/stock/sources/inventory_source.dart';
import 'package:app/services/stock/sources/inventory_cloud_source.dart';
import 'package:app/services/stock/sources/stock_source.dart';
import 'package:app/services/stock/sources/stock_cloud_source.dart';
import 'package:app/services/pos/sources/pos_source.dart';
import 'package:app/services/pos/sources/pos_cloud_source.dart';
import 'package:app/services/sales/sources/sales_source.dart';
import 'package:app/services/sales/sources/sales_cloud_source.dart';
import 'package:app/services/money/sources/money_source.dart';
import 'package:app/services/money/sources/money_cloud_source.dart';

/// Where the company's data lives (`docs/plan-offline-lan.md` §7).
///
/// - [cloud]: today's app, the backend over the internet.
/// - [local]: one desktop install is the master and serves the LAN, no cloud.
/// - [hybrid]: the master serves the LAN and syncs with the cloud.
///
/// [local] is reachable from phase 3 behind `--dart-define=LYRA_LAN=true`
/// ([Deployment.lanEnabled]): it is released after plan phase 5. [hybrid] needs
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

  /// Whether this build offers LAN mode: a native build compiled with
  /// `--dart-define=LYRA_LAN=true`. Without it the app is today's cloud app,
  /// whatever the preferences say.
  static bool get lanEnabled => const bool.fromEnvironment("LYRA_LAN") && lanSupported;

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
  static SessionSource get session => _pick(const SessionCloudSource());
  static BusinessSource get business => _pick(const BusinessCloudSource());
  static EmployeesSource get employees => _pick(const EmployeesCloudSource());
  static DeliverySource get delivery => _pick(const DeliveryCloudSource());
  static InventorySource get inventory => _pick(const InventoryCloudSource());
  static StockSource get stock => _pick(const StockCloudSource());
  static PosSource get pos => _pick(const PosCloudSource());
  static SalesSource get sales => _pick(const SalesCloudSource());
  static MoneySource get money => _pick(const MoneyCloudSource());

  /// There is no LAN source before plan phase 4: in LAN mode the app stays on
  /// its LAN pages (`/lan`), so a call getting here outside the cloud is a bug,
  /// not a state to recover from.
  static T _pick<T>(T cloud) => switch (Deployment.mode) {
    DeploymentMode.cloud => cloud,
    DeploymentMode.local || DeploymentMode.hybrid =>
      throw UnsupportedError("No LAN source for $T yet")
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
