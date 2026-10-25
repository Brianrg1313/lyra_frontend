import 'dart:async';

import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/business/business_branch_model.dart';
import 'package:app/services/business/sources/business_source.dart';
import 'package:app/services/connection/connection_service.dart';
import 'package:app/services/preferences/preferences_service.dart';
import 'package:app/toolkit/backend/api.dart';
import 'package:app/toolkit/backend/deployment.dart';

enum BranchStatus { idle, loading, ready, error }

/// The branch the person works in, inside the active company: what the `branch_id` header and
/// the socket's `auth.branch_id` carry (`sedes-frontend.md` §2, §3).
///
/// The company is still the tenant; a branch is a second filter inside it. The till, the stock,
/// the sales and the money are one branch's, and the backend refuses those routes without one
/// (`400`, `action: "select_branch"`), so the header travels on **every** request: simpler than
/// remembering which routes need it.
///
/// The list is `GET /business/branches/`, which answers only the branches this person may work
/// in, the main one first. The choice is kept per company on this device
/// ([RememberedSelection.branch]) and put on the header at once when the company becomes active,
/// before the list arrives, so a reopened app sends it from its first request. A kept branch the
/// list no longer has (closed, or taken from the person) gives way to the list's first.
///
/// Cloud only. A master holds one site (plan D6): there is nothing to pick and its engine
/// answers for its site without a header. In `hybrid` the master's site is the one the screens
/// work in, and the cloud falls back to the main branch (or the person's first) on its own.
///
/// A switch rebinds the socket (its rooms are joined in the handshake), and the home shell keys
/// its content by [activeId], so every section reads again for the new branch.
///
/// A singleton (`.value` provider), like [PermissionsService], which reads [activeId] to pick a
/// branch's own permission tree.
class BranchService extends ChangeNotifier {
  //SINGLETON
  static final BranchService _singleton = BranchService._internal();

  factory BranchService() => _singleton;

  BranchService._internal() {
    onBranchRefused = refused;
    ConnectionService().addListener(_onConnection);
  }

  BusinessSource? _injected;

  BusinessSource get _source => _injected ?? Sources.business;

  /// Replaces where the branches are read from, for tests.
  @visibleForTesting
  set source(BusinessSource? source) => _injected = source;

  /// Whether this install picks a branch at all (see the class doc).
  @visibleForTesting
  bool Function() applies = () => Deployment.mode == DeploymentMode.cloud;

  /// The company the list and the choice belong to.
  String? _business;

  BranchStatus _status = BranchStatus.idle;
  List<BusinessBranchModel> _branches = const [];
  String? _active;

  /// Whether the person should be asked which branch they work in: several to pick from and
  /// none picked on this device yet, or the backend refused the one sent.
  bool _ask = false;

  BranchStatus get status => _status;

  /// The branches the person may work in, the main one first.
  List<BusinessBranchModel> get branches => _branches;

  /// The branch the header carries, or null when none travels.
  String? get activeId => _active;

  /// The active branch's row, once the list has it.
  BusinessBranchModel? get active => byId(_active);

  /// Whether there is a choice to offer: more than one branch.
  bool get choosable => _branches.length > 1;

  /// Whether the home should ask for a branch now ([asked] once it did).
  bool get shouldAsk => _ask && choosable;

  /// Whether the screens can read: a branch is on the header, or there is none to wait for
  /// (a master, no company, the list failed or came empty). The home waits on it so a first
  /// visit doesn't meet `branch_required` before the list arrives.
  bool get settled =>
    !applies() || _business == null || _active != null ||
    _status == BranchStatus.ready || _status == BranchStatus.error;

  BusinessBranchModel? byId(String? id) {
    for (final branch in _branches) {
      if (branch.id == id) return branch;
    }
    return null;
  }

  /// The branch's name, or empty when the list doesn't have it.
  String nameOf(String? id) => byId(id)?.name ?? "";

  /// Takes the company that just became active. `BusinessService` calls it on every change,
  /// after `useBusiness` (which scopes [PreferencesService] to it).
  void bind(String? business) {
    if (business == _business) return;

    _business = business;
    _branches = const [];
    _status = BranchStatus.idle;
    _ask = false;

    if (business == null || !applies()) {
      _set(null);
      notifyListeners();
      return;
    }

    _set(PreferencesService().recall(RememberedSelection.branch));
    notifyListeners();

    unawaited(load());
  }

  /// Reads the list and settles the branch: the kept one while the list has it, else the
  /// list's first. A failed read keeps whatever travels already.
  Future<void> load({bool force = false}) async {
    final business = _business;

    if (business == null || !applies()) return;
    if (_status == BranchStatus.loading) return;
    if (!force && _status == BranchStatus.ready) return;

    _status = BranchStatus.loading;
    notifyListeners();

    List<BusinessBranchModel>? branches;

    try {
      branches = await _source.branches();
    } catch (error) {
      if (kDebugMode) print("loadBranches failed: $error");
    }

    // Another company became active while this was read.
    if (business != _business) return;

    if (branches == null) {
      _status = BranchStatus.error;
      notifyListeners();
      return;
    }

    _branches = branches;
    _status = BranchStatus.ready;

    final kept = PreferencesService().recall(RememberedSelection.branch);

    if (byId(_active) == null) {
      final fallback = branches.isEmpty ? null : branches.first.id;

      if (fallback != _active) {
        _set(fallback);
        unawaited(ConnectionService().rebind());
      }
    }

    // One branch is chosen without asking; several are asked once per company on this device.
    if (kept == null || byId(kept) == null) _ask = _ask || branches.length > 1;

    notifyListeners();
  }

  /// Works in [id] from now on: the header, the socket and the choice kept on this device.
  void select(String id) {
    if (byId(id) == null) return;

    _ask = false;
    PreferencesService().remember(RememberedSelection.branch, id);

    if (id == _active) {
      notifyListeners();
      return;
    }

    _set(id);
    unawaited(ConnectionService().rebind());
    notifyListeners();
  }

  /// The home asked; it isn't asked again unless the backend refuses the branch.
  void asked() {
    if (!_ask) return;

    _ask = false;
    notifyListeners();
  }

  /// The backend refused the branch sent, or that none was (`action: "select_branch"`): the
  /// list is read again, which drops a branch the person lost, and the person is asked.
  void refused() {
    if (!applies() || _business == null) return;

    _ask = true;
    unawaited(load(force: true));
  }

  /// A socket refused for its branch (`auth.branch_id`) is the same refusal.
  void _onConnection() {
    if (ConnectionService().error?["action"] == "select_branch") refused();
  }

  void _set(String? id) {
    _active = id;
    useBranch(id);
  }

  /// Seeds the list, for tests.
  @visibleForTesting
  void seed(String business, List<BusinessBranchModel> branches, {String? active}) {
    _business = business;
    _branches = branches;
    _status = BranchStatus.ready;
    _ask = false;
    _set(active ?? (branches.isEmpty ? null : branches.first.id));
    notifyListeners();
  }

  /// Forgets everything (sign out; tests).
  void clear() {
    _business = null;
    _branches = const [];
    _status = BranchStatus.idle;
    _ask = false;
    _set(null);
    notifyListeners();
  }
}
