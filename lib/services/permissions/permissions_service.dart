import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/capabilities/capability_service.dart';
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
/// A master (`docs/offline/specs/session.md`, P-1) sends a company's grants as the list it keeps
/// instead (`["*"]`, `["sales.*", "pos.view"]`), with wildcards: `*` is everything, `<area>.*`
/// every action of that area and its children. Both shapes answer the same questions.
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

  /// Company id → its grants as a master lists them.
  Map<String, Set<String>> _lists = const {};

  /// Companies created in this session: their creator owns them, and an owner holds
  /// everything, so there is no need to reread `/init` to know it.
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
    if (!_loaded) return true;

    final company = business ?? businessService.activeId;
    if (company == null) return false;
    if (_owned.contains(company)) return true;

    final list = _lists[company];
    if (list != null) return _allows(list, id);

    Object? node = _companies[company];
    for (final key in path) {
      if (node is! Map) return false;
      node = node[key];
    }

    return node == true;
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

    final list = _lists[company];
    if (list != null) {
      if (_allows(list, "$area.*")) return null;

      return {
        for (final grant in list)
          if (grant.startsWith("$area.") && !grant.substring(area.length + 1).contains(".")) grant.substring(area.length + 1)
      };
    }

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

  /// P-1 over a listed set, the rule the master enforces (`Permissions.allows` in `lyra_node`).
  static bool _allows(Set<String> grants, String id) {
    if (grants.contains("*") || grants.contains(id)) return true;

    for (final grant in grants) {
      if (!grant.endsWith(".*")) continue;

      final area = grant.substring(0, grant.length - 2);
      if (id == area || id.startsWith("$area.")) return true;
    }

    return false;
  }

  /// Stores `/init`'s `permissions` (a tree per company, or a master's list). A company whose
  /// entry is neither gets nothing.
  void seed(dynamic data) {
    if (data is! Map) return;

    _companies = {
      for (final entry in data.entries)
        if (entry.value is Map) entry.key.toString(): entry.value as Map
    };
    _lists = {
      for (final entry in data.entries)
        if (entry.value is List) entry.key.toString(): {
          for (final grant in entry.value as List) grant.toString()
        }
    };
    _owned = const {};
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
    _lists = const {};
    _owned = const {};
    _loaded = false;

    notifyListeners();
  }
}
