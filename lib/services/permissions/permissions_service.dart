import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/toolkit/deployment.dart';
import 'package:app/toolkit/settings/initial_builder.dart' show businessService;

/// What the person may open and do in each company, from `/init`'s `permissions`.
///
/// Ids are the app's areas (`docs/app-areas.json`): `<area>.<action>`, dotted from the root
/// area down (`finance.payments.record`). The backend sends, per company id, the areas
/// nested and **only what is granted**
/// (`{ business: { view: true, employees: { view: true, invite: true } } }`), having already
/// applied the contract's rules (an action only with its area's `view`, a `view` only with its
/// parent's). So a lookup is a walk: absent anywhere on the path is denied.
///
/// A master answers the same tree (`docs/offline/specs/session.md` S-34, P-3): it keeps the
/// cloud's permissions and derives the areas with the backend's own map, so nothing here knows
/// which one answered. It also says which companies the person owns (`owned`), which the cloud
/// doesn't.
///
/// It exists so the app hides a door instead of meeting a 403 behind it. It is not the
/// guard: every endpoint checks the same ids.
///
/// An area the deployment mode doesn't have ([CapabilityService]) is denied before any
/// grant is read, even to an owner: it is not part of the product there.
///
/// A singleton registered with `ChangeNotifierProvider.value`, like the catalogs:
/// [ClientService.resolve] fills it before the tree exists, and screens `watch` it to
/// redraw when a reread brings different grants.
///
/// ```dart
/// if (PermissionsService().canOpen("finance.payments")) …
/// if (context.watch<PermissionsService>().can("sales.approve")) …
/// ```
class PermissionsService extends ChangeNotifier {
  //SINGLETON
  static final PermissionsService _singleton = PermissionsService._internal();

  factory PermissionsService() => _singleton;

  PermissionsService._internal();

  /// Areas of scope `account`: they do not depend on a company, so the backend does not
  /// send them and they are never filtered.
  static const Set<String> _accountAreas = {"dashboard"};

  /// Company id → its granted tree.
  Map<String, Map> _companies = const {};

  /// Companies created in this session, or a master's `owned`: their owner holds everything,
  /// so there is no need to reread `/init` to know it.
  Set<String> _owned = const {};

  bool _loaded = false;

  /// Whether `/init` brought permissions. Until it does (a backend that does not send them
  /// yet) nothing is hidden: the endpoints still refuse what is not granted.
  bool get isLoaded => _loaded;

  /// Whether [id] (`<area>.<action>`) is granted in [business], the active company by
  /// default. No company at all is denied, except for account areas.
  bool can(String id, {String? business}) {
    if (!CapabilityService().shows(id)) return false;

    final path = id.split(".");
    if (_accountAreas.contains(path.first)) return true;
    // Online, the server section is this computer's, not a company's: the cloud grants nothing
    // for it. A master's grants decide once there is one (`local_server.*`).
    if (path.first == "local_server" && Deployment.mode == DeploymentMode.cloud) return true;
    if (!_loaded) return true;

    final company = business ?? businessService.activeId;
    if (company == null) return false;
    if (_owned.contains(company)) return true;

    Object? node = _companies[company];
    for (final key in path) {
      if (node is! Map) return false;
      node = node[key];
    }

    return node == true;
  }

  /// Whether this person owns [business] (the active one by default): created it in this
  /// session, or a master says so. A cloud tree doesn't say it: false there.
  bool owns({String? business}) {
    final company = business ?? businessService.activeId;
    if (company == null) return false;

    return _owned.contains(company);
  }

  /// Whether [area] (`finance.payments`) can be opened: its `view`.
  bool canOpen(String area, {String? business}) => can("$area.view", business: business);

  /// The actions granted in [area] (`view`, `reply`...), or `null` when every one is: an
  /// owner, or no permissions loaded yet (the same cases [can] answers `true` to all).
  Set<String>? granted(String area, {String? business}) {
    if (!CapabilityService().shows(area)) return const {};
    if (!_loaded) return null;

    final company = business ?? businessService.activeId;
    if (company == null) return const {};
    if (_owned.contains(company)) return null;

    Object? node = _companies[company];
    for (final key in area.split(".")) {
      if (node is! Map) return const {};
      node = node[key];
    }

    if (node is! Map) return const {};

    return {
      for (final entry in node.entries)
        if (entry.value == true) entry.key.toString()
    };
  }

  /// Stores `/init`'s `permissions` (a tree per company) and a master's [owned] company ids. A
  /// company whose entry isn't a tree gets nothing.
  void seed(dynamic data, {dynamic owned}) {
    if (data is! Map) return;

    _companies = {
      for (final entry in data.entries)
        if (entry.value is Map) entry.key.toString(): entry.value as Map
    };
    _owned = {
      if (owned is List)
        for (final company in owned) company.toString()
    };
    _loaded = true;

    notifyListeners();
  }

  /// Grants everything in [business], just created by this person.
  void own(String business) {
    _owned = {..._owned, business};

    notifyListeners();
  }

  /// Forgets every grant. For session logout: the next session brings its own.
  void clear() {
    _companies = const {};
    _owned = const {};
    _loaded = false;

    notifyListeners();
  }
}
