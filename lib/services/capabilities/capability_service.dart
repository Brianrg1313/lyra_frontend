import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/toolkit/deployment.dart';

/// What an area is in the running deployment.
enum Capability {
  /// Open, as far as the mode goes (the permission still decides).
  available,

  /// Part of the product here but unreachable right now: a cloud-only area in
  /// `hybrid` with the internet down. Shown with a `SectionMessage`, not hidden.
  needsInternet,

  /// Not part of the product in this mode: hidden like an area without its `view`.
  hidden
}

/// Which areas exist in the running deployment (`docs/plan-offline-lan.md` §2, §7.3).
///
/// It answers from the mode alone; `PermissionsService` asks it before any grant,
/// so every door the permissions already close (side bar, tabs, routes, deep
/// links) closes the same way for an area the mode doesn't have.
///
/// A singleton notifier like the permissions: in `hybrid`, losing the internet
/// changes the answer while the app runs.
class CapabilityService extends ChangeNotifier {
  //SINGLETON
  static final CapabilityService _singleton = CapabilityService._internal();

  factory CapabilityService() => _singleton;

  CapabilityService._internal();

  static const _all = {DeploymentMode.cloud, DeploymentMode.local, DeploymentMode.hybrid};
  static const _online = {DeploymentMode.cloud};
  static const _lan = {DeploymentMode.local, DeploymentMode.hybrid};
  static const _notLocal = {DeploymentMode.cloud, DeploymentMode.hybrid};

  /// The `modes` of every area of `docs/app-areas.json`, and the `action_modes` of
  /// its actions as `<area>.<action>`, which a test keeps equal.
  ///
  /// An area in `cloud` only is a cloud-only feature: hidden in `local`, and
  /// in `hybrid` open while the internet is.
  static const Map<String, Set<DeploymentMode>> modes = {
    "dashboard": _all,
    "business": _all,
    "business.delete": _online,
    "business.statistics": _all,
    "business.employees": _all,
    "business.branches": _notLocal,
    "business.clients": _all,
    "business.settings": _all,
    "business.settings.manage_emails": _online,
    "messages": _online,
    "deliveries": _notLocal,
    "deliveries.settings": _notLocal,
    "deliveries.areas": _notLocal,
    "sales": _all,
    "sales.approve": _notLocal,
    "sales.process": _all,
    "sales.done": _all,
    "inventory": _all,
    "services": _online,
    "channels": _online,
    "finance": _all,
    "finance.overview": _all,
    "finance.payments": _all,
    "finance.receivables": _notLocal,
    "finance.methods": _all,
    "marketing": _online,
    "report": _online,
    "connections": _online,
    "external_services": _online,
    "pos": _all,
    "local_server": _lan
  };

  /// The areas whose master side exists: plan phase 4 ships one domain per
  /// release, and until an area's release it is hidden on a master's devices
  /// even where [modes] says it belongs, since its services have no source to
  /// read there. What sits under a listed area is built with it, except a child
  /// area declared in [modes] (employees under business) and what is in
  /// [_pendingOnMaster]. Goes away when phase 4 ends.
  static const Set<String> _builtOnMaster = {
    "dashboard",
    "business",
    "business.statistics",
    "business.clients",
    "business.settings",
    "inventory",
    "pos",
    "sales",
    "sales.process",
    "sales.done",
    "local_server"
  };

  /// Parts of a built area whose master side is still missing, hidden until
  /// their release. None today: kept for the next domain that lands in parts.
  static const Set<String> _pendingOnMaster = {};

  bool _internet = true;

  /// Whether this install sees one company only (plan principle 3, D6): a
  /// master holds one, so there is nothing to switch to or create.
  bool get singleCompany => Deployment.mode != DeploymentMode.cloud;

  /// Whether the internet is reachable. Only `hybrid` reads it.
  bool get internet => _internet;

  set internet(bool value) {
    if (value == _internet) return;

    _internet = value;
    notifyListeners();
  }

  /// What [area] (`finance.payments`, or an action id `finance.payments.record`)
  /// is in the running mode. It is read from the most specific area declared on
  /// the path; one declared nowhere is cloud only, as the contract of
  /// `app-areas.json` says.
  Capability of(String area) {
    final mode = Deployment.mode;
    final declared = _declared(area) ?? _online;

    if (mode != DeploymentMode.cloud && declared.contains(DeploymentMode.local) && !_builtLocally(area)) {
      return Capability.hidden;
    }

    if (declared.contains(mode)) return Capability.available;

    if (mode == DeploymentMode.hybrid && declared.contains(DeploymentMode.cloud)) {
      return _internet ? Capability.available : Capability.needsInternet;
    }

    return Capability.hidden;
  }

  /// Whether [area] is part of the product in the running mode.
  bool shows(String area) => of(area) != Capability.hidden;

  /// Read like [_declared]: the most specific key on the path that is listed
  /// as built, or declared as an area of its own, decides.
  static bool _builtLocally(String area) {
    if (_pendingOnMaster.any((pending) => area == pending || area.startsWith("$pending."))) return false;

    var key = area;

    while (true) {
      if (_builtOnMaster.contains(key)) return true;
      if (modes.containsKey(key)) return false;

      final dot = key.lastIndexOf(".");
      if (dot == -1) return false;

      key = key.substring(0, dot);
    }
  }

  static Set<DeploymentMode>? _declared(String area) {
    var key = area;

    while (true) {
      final found = modes[key];
      if (found != null) return found;

      final dot = key.lastIndexOf(".");
      if (dot == -1) return null;

      key = key.substring(0, dot);
    }
  }
}
