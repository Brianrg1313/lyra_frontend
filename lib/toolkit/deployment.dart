import 'package:flutter/foundation.dart';

// SERVICES
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

/// Where the company's data lives (`docs/plan-offline-lan.md` §7).
///
/// - [cloud]: today's app, the backend over the internet.
/// - [local]: one desktop install is the master and serves the LAN, no cloud.
/// - [hybrid]: the master serves the LAN and syncs with the cloud.
///
/// Only [cloud] is reachable until the engine exists (plan phases 2–3): the
/// other two are named so the seams can already switch on them.
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

  /// Until the boot flow reads it from preferences (plan §7.4) only tests set it.
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

  /// There is no LAN source before plan phase 4, and nothing reaches another
  /// mode before phase 3: a call getting here outside the cloud is a bug, not
  /// a state to recover from.
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
