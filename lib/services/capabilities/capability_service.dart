import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/toolkit/deployment.dart';

/// What an area is in the running deployment.
enum Capability {
  /// Open, as far as the mode goes (the permission still decides).
  available,

  /// Part of the product but not reachable here and now: a cloud-only area without the
  /// internet (in `local`, or `hybrid` with it down), or one whose master side isn't built yet.
  /// Shown locked, with a `SectionMessage`, never hidden: the app is the same one with or
  /// without the network (plan §9.6, D17).
  needsInternet,

  /// A cloud-only area in `hybrid` while the master's company isn't linked to its cloud company
  /// (`business.md` B-30): the internet answers, but the cloud doesn't know which company to
  /// serve. Locked like [needsInternet], with its own message (plan D18).
  needsLink,

  /// What can't exist in this mode at all (a master's accounting export in the cloud): hidden
  /// like an area without its `view`.
  hidden
}

/// Which areas exist in the running deployment (`docs/plan-offline-lan.md` §2, §7.3).
///
/// It answers from the mode alone; `PermissionsService` asks it before any grant,
/// so every door the permissions already close (side bar, tabs, routes, deep
/// links) closes the same way for an area the mode doesn't have. Sections and tabs
/// draw a locked one ([needsInternet]) instead of leaving it out ([shows] is
/// whether it works now, [exists] whether it is drawn).
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
    "account": _all,
    "account.security": _online,
    "account.history": _online,
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
    "inventory.templates": _online,
    "inventory.transfers": _online,
    "inventory.prices": _online,
    "inventory.picture_import": _online,
    "inventory.purchases": _online,
    "inventory.history": _online,
    "inventory.units": _online,
    "inventory.recipes": _online,
    "inventory.modifiers": _online,
    "inventory.kinds": _online,
    "menu": _online,
    "services": _online,
    "channels": _online,
    "knowledge": _online,
    "finance": _all,
    "finance.overview": _all,
    "finance.overview.view_bot_cost": _notLocal,
    "finance.payments": _all,
    "finance.receivables": _notLocal,
    "finance.methods": _all,
    "finance.export": _lan,
    "lyra_business": _online,
    "marketing": _online,
    "report": _online,
    "connections": _online,
    "external_services": _online,
    "pos": _all,
    "pos.kitchen": _online,
    "local_server": _all
  };

  /// The areas whose master side exists: plan phase 4 ships one domain per
  /// release, and until an area's release it is hidden on a master's devices
  /// even where [modes] says it belongs, since its services have no source to
  /// read there. What sits under a listed area is built with it, except a child
  /// area or action declared in [modes] (employees under business, the
  /// accounting export). Goes away when phase 4 ends.
  static const Set<String> _builtOnMaster = {
    "dashboard",
    "account",
    "business",
    "business.statistics",
    "business.employees",
    "business.clients",
    "business.settings",
    "inventory",
    "pos",
    "sales",
    "sales.process",
    "sales.done",
    "finance",
    "finance.overview",
    "finance.payments",
    "finance.methods",
    "finance.export",
    "deliveries",
    "deliveries.settings",
    "deliveries.areas",
    "local_server"
  };

  bool _internet = true;
  bool _linked = true;

  /// Whether this install is a computer that can run the engine: a native desktop build.
  static bool get canHostMaster => Deployment.lanEnabled && !kIsWeb && switch (defaultTargetPlatform) {
    TargetPlatform.windows || TargetPlatform.macOS || TargetPlatform.linux => true,
    _ => false
  };

  /// Whether this install sees one company only (plan principle 3, D6): a
  /// master holds one, so there is nothing to switch to or create.
  bool get singleCompany => Deployment.mode != DeploymentMode.cloud;

  /// Whether the internet is reachable. Only `hybrid` reads it.
  bool get internet => _internet;

  /// Whether the cloud-only services a local area's screen may lean on (the address search of
  /// places) answer here: in `cloud`, and in `hybrid` while the internet is up. Without them the
  /// screen falls back to what it does alone (typing the address).
  bool get cloudServices => switch (Deployment.mode) {
    DeploymentMode.cloud => true,
    DeploymentMode.hybrid => _internet && _linked,
    DeploymentMode.local => false
  };

  set internet(bool value) {
    if (value == _internet) return;

    _internet = value;
    notifyListeners();
  }

  /// The running mode changed (`HybridService`: signed in online on a device with a master,
  /// "work offline"): every answer may have.
  void modeChanged() => notifyListeners();

  /// Whether the company in use is known to the cloud: always in `cloud`; in `hybrid`, whether
  /// the master's company carries its cloud company's id (`BusinessModel.cloudId`). Set by
  /// `BusinessService` whenever the active company changes. Only `hybrid` reads it.
  bool get linked => _linked;

  set linked(bool value) {
    if (value == _linked) return;

    _linked = value;
    notifyListeners();
  }

  /// What [area] (`finance.payments`, or an action id `finance.payments.record`)
  /// is in the running mode. It is read from the most specific area declared on
  /// the path; one declared nowhere is cloud only, as the contract of
  /// `app-areas.json` says.
  Capability of(String area) {
    final mode = Deployment.mode;
    final declared = _declared(area) ?? _online;

    // The server section is wherever a master can be (plan D16): on a device paired with one,
    // and online on any computer, where it creates one. Not in a browser or on a phone.
    if (area.split(".").first == "local_server" && Deployment.paired == null && !canHostMaster) {
      return Capability.hidden;
    }

    if (mode == DeploymentMode.cloud) {
      return declared.contains(mode) ? Capability.available : Capability.hidden;
    }

    // What the master serves: always there, whatever the internet. An area kept on the master for
    // `hybrid` alone (deliveries) is the master's there, and locked in `local` like a cloud one.
    if (declared.contains(mode) && _builtLocally(area)) return Capability.available;

    // The rest is the cloud's: a cloud-only area, or one whose master side isn't built yet,
    // which `hybrid` reads from the cloud meanwhile. Without it, locked.
    if (!declared.contains(DeploymentMode.cloud)) return Capability.hidden;

    if (mode == DeploymentMode.local || !_internet) return Capability.needsInternet;

    return _linked ? Capability.available : Capability.needsLink;
  }

  /// Whether [area] works now: what an action, a button or a grant asks.
  bool shows(String area) => of(area) == Capability.available;

  /// Whether [area] is drawn locked: part of the product, not reachable now.
  bool locked(String area) => switch (of(area)) {
    Capability.needsInternet || Capability.needsLink => true,
    _ => false
  };

  /// Whether [area] is drawn, open or locked: what a side bar option or a tab asks.
  bool exists(String area) => of(area) != Capability.hidden;

  /// Read like [_declared]: the most specific key on the path that is listed
  /// as built, or declared as an area of its own, decides.
  static bool _builtLocally(String area) {
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
