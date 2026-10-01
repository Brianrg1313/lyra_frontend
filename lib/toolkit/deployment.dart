import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/lan/lan_device.dart';
import 'package:app/services/lan/lan_identity_store.dart';
import 'package:app/toolkit/lan.dart' show lanSupported;
import 'package:app/services/client/sources/session_source.dart';
import 'package:app/services/client/sources/session_cloud_source.dart';
import 'package:app/services/client/sources/session_lan_source.dart';
import 'package:app/services/business/sources/business_source.dart';
import 'package:app/services/business/sources/business_cloud_source.dart';
import 'package:app/services/business/sources/business_lan_source.dart';
import 'package:app/services/business/sources/employees_source.dart';
import 'package:app/services/business/sources/employees_cloud_source.dart';
import 'package:app/services/business/sources/employees_lan_source.dart';
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
import 'package:app/toolkit/api.dart' show api;
import 'package:app/services/database/database_service.dart';

/// Where the company's data lives (`docs/plan-offline-lan.md` §7, decision D9).
///
/// - [cloud]: today's app, the backend over the internet. A business without a computer.
/// - [local]: one desktop of each site is the master and serves the LAN, no cloud.
/// - [hybrid]: the master serves the LAN and syncs with the cloud (a subscription, phase 6).
///
/// It is never chosen up front: a device is in LAN mode while it is paired with a master or is
/// one ([Deployment.restore]), unless its session is the cloud's: the sign in page offers the
/// cloud whenever the backend answers, paired or not, and the session decides where the data
/// comes from. Whether a master syncs is the company's subscription, not the device's.
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
  static DeploymentRole? _paired;

  static DeploymentMode get mode => _mode;

  /// Null in [DeploymentMode.cloud].
  static DeploymentRole? get role => _role;

  /// What this device's pairing makes it, whichever session it runs: a paired device signed in
  /// to the cloud keeps its pairing for the next time it signs in to the master ([offline]).
  static DeploymentRole? get paired => _paired;

  /// Whether this install offers LAN mode: every native one, and the page a
  /// master serves (plan §3). The same build is the cloud app everywhere else:
  /// a browser on the cloud's site never sees it, whatever it has stored.
  static bool get lanEnabled => lanSupported;

  /// Reads this device's mode from what it holds (`preCall`, before the first route): the
  /// pairing [store] keeps (`LanDevice`, written by the setup and by pairing) makes it a
  /// master or a client, anything else is the cloud app. A paired device that holds a cloud
  /// session ([cloudSession]) stays the cloud app until it signs out. Nothing up front decides
  /// it, and leaving the LAN ([detach]) or pairing ([attach]) changes it at any time.
  static Future<void> restore([
    LanIdentityStore store = const SecureLanIdentityStore(),
    Future<bool> Function() cloudSession = _cloudToken
  ]) async {
    LanDevice? device;

    if (lanEnabled) {
      try {
        device = await store.device();
      } on Object {
        // The OS key store can't be read: the cloud app still opens.
        device = null;
      }
    }

    var cloud = device == null;
    if (!cloud) {
      try {
        cloud = await cloudSession();
      } on Object {
        cloud = false;
      }
    }

    use(cloud ? DeploymentMode.cloud : DeploymentMode.local, role: device?.role, paired: device?.role);
  }

  /// A browser's cloud session is a cookie this page can't see, and a master's page is never
  /// the cloud's origin: only a stored token says so.
  static Future<bool> _cloudToken() async =>
    !kIsWeb && await DatabaseService().hasInSecure(api.current.tokenName);

  /// This device was just set up as the master or paired with one (its `LanDevice` stored).
  static void attach(DeploymentRole role) => use(DeploymentMode.local, role: role);

  /// This device just forgot its pairing.
  static void detach() => use(DeploymentMode.cloud);

  /// The sign in page goes to the cloud: its sources serve this session, the pairing kept.
  static void online() {
    _mode = DeploymentMode.cloud;
    _role = null;
  }

  /// The sign in page goes to the master this device is paired with.
  static void offline() {
    if (_paired != null) use(DeploymentMode.local, role: _paired);
  }

  /// [paired] defaults to [role]: a test of a session on a master is a test of a paired device.
  @visibleForTesting
  static void use(DeploymentMode mode, {DeploymentRole? role, DeploymentRole? paired}) {
    _mode = mode;
    _role = mode == DeploymentMode.cloud ? null : role;
    _paired = paired ?? _role;
  }
}

/// The one place that picks each domain's source for the running mode.
///
/// A service reads its source from here unless a test hands it one. Cloud
/// sources hold no state, so the same instance serves every service.
abstract final class Sources {
  static SessionSource get session => _pick(const SessionCloudSource(), () => SessionLanSource(lanService));
  static BusinessSource get business => _pick(const BusinessCloudSource(), () => BusinessLanSource(lanService));
  static EmployeesSource get employees => _pick(const EmployeesCloudSource(), () => EmployeesLanSource(lanService));
  static DeliverySource get delivery => _pick(const DeliveryCloudSource());
  static InventorySource get inventory => _pick(const InventoryCloudSource(), () => InventoryLanSource(lanService));
  static StockSource get stock => _pick(const StockCloudSource(), () => StockLanSource(lanService));
  static PosSource get pos => _pick(const PosCloudSource(), () => PosLanSource(lanService));
  static SalesSource get sales => _pick(const SalesCloudSource(), () => SalesLanSource(lanService));
  static MoneySource get money => _pick(const MoneyCloudSource(), () => MoneyLanSource(lanService));

  /// LAN sources arrive one domain per release (plan phase 4), over the one
  /// connection [lanService] holds. A domain without one yet is the cloud's in
  /// `hybrid` (plan §9.6) and locked in `local` (`CapabilityService`), so a call
  /// getting here in `local` without a [lan] source is a bug, not a state to
  /// recover from.
  static T _pick<T>(T cloud, [T Function()? lan]) => switch (Deployment.mode) {
    DeploymentMode.cloud => cloud,
    DeploymentMode.hybrid => lan?.call() ?? cloud,
    DeploymentMode.local => lan?.call() ?? (throw UnsupportedError("No LAN source for $T yet"))
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
