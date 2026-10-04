import 'dart:async';

import 'package:flutter/foundation.dart';

// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart';

// SERVICES
import 'package:app/toolkit/deployment.dart';
import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/services/permissions/permissions_service.dart';
import './hybrid_service.dart';
import './lan_service.dart';
import './sync_cloud_source.dart';

/// Where the master's sync with the cloud stands (`sync.status`, `business.md` B-35).
class SyncState {
  const SyncState({
    required this.enrolled,
    this.revoked = false,
    this.lastSync,
    this.lastError,
    this.pending = 0
  });

  factory SyncState.fromJson(Map json) => SyncState(
    enrolled: json["enrolled"] == true,
    revoked: json["revoked"] == true,
    lastSync: DateTime.tryParse(json["lastSync"]?.toString() ?? "")?.toLocal(),
    lastError: json["lastError"] as String?,
    pending: (json["pending"] as num?)?.toInt() ?? 0
  );

  final bool enrolled;

  /// Unlinked from the cloud: the engine stopped syncing and won't start again by itself.
  final bool revoked;
  final DateTime? lastSync;
  final String? lastError;

  /// Changes made here the cloud doesn't have yet.
  final int pending;

  bool get syncing => enrolled && !revoked;
}

/// Enrols the master with the backend without asking anyone (`business.md` B-33 to B-36,
/// `docs/task-edge-sync-backend.md` §1): on a device signed in online as the owner, once the
/// company is linked and the internet answers, it takes the engine's key to `POST
/// /edge/v1/devices` and hands the answer back to the engine, which syncs on its own from then on.
///
/// Only what a person must decide reaches the screen ([taken], [SyncState.revoked]): replacing
/// the branch's other server, or linking again a server someone unlinked. A failure of the network
/// or the backend is tried again the next time the internet comes back.
///
/// App-wide (`initial_builder.dart`), following the [HybridService] session and the
/// [CapabilityService] (mode, internet, link).
class SyncService extends ChangeNotifier {
  SyncService({
    required LanService lan,
    required HybridService hybrid,
    SyncCloudSource cloud = const SyncCloudSource(),
    bool Function()? owner
  }) : _lan = lan, _hybrid = hybrid, _cloud = cloud, _owner = owner ?? (() => PermissionsService().owns()) {
    _hybrid.addListener(_follow);
    CapabilityService().addListener(_follow);
    // The boot may have resumed the session before this was made.
    _follow();
  }

  final LanService _lan;
  final HybridService _hybrid;
  final SyncCloudSource _cloud;

  /// Whether the signed-in person owns the company: only the owner enrols, here as online.
  final bool Function() _owner;

  SyncState? _state;

  /// Null until read, and on a device that may not read it (`server`).
  SyncState? get state => _state;

  bool _taken = false;

  /// The branch is synced by another server (`site_has_master`): this one syncs only if the owner
  /// chooses it over that one ([enrol] with `replace`).
  bool get taken => _taken;

  bool _working = false;
  bool get working => _working;

  /// Whether the cloud can be reached for this company now: `hybrid`, online, linked.
  bool _online = false;

  /// The automatic enrolment ran this session: it runs once, and again only after a failure.
  bool _tried = false;

  /// Whether the owner can act on [taken] or a revoked server from here.
  bool get canEnrol => _online && _owner();

  void _follow() {
    if (!_hybrid.joined) {
      if (_state != null || _taken || _tried) {
        _state = null;
        _taken = false;
        _tried = false;
        notifyListeners();
      }
      _online = false;
      return;
    }

    final capabilities = CapabilityService();
    final online = Deployment.mode == DeploymentMode.hybrid && capabilities.internet && capabilities.linked;
    if (online == _online) return;

    _online = online;
    if (online) unawaited(_check());
  }

  Future<void> _check() async {
    await refresh();

    final state = _state;
    if (_tried || state == null || state.enrolled || !canEnrol) return;

    _tried = true;
    await enrol();
  }

  /// Reads `sync.status` again: what the server section shows.
  Future<void> refresh() async {
    try {
      _state = SyncState.fromJson(await _lan.call(Ops.syncStatus) as Map);
      notifyListeners();
    } on Object {
      // Not allowed to read it, or the master away: nothing to show.
    }
  }

  /// Enrols this master: by itself the first time, or the owner's "use this server" ([replace],
  /// after [taken]) and "link again" (a revoked one). False when it didn't; [taken] says why when
  /// a person can do something about it.
  Future<bool> enrol({bool replace = false}) async {
    if (_working) return false;

    _working = true;
    notifyListeners();

    try {
      final key = Map<String, Object?>.from(await _lan.call(Ops.syncPrepare) as Map);
      final answer = await _cloud.enrol(key, replace: replace);

      _state = SyncState.fromJson(await _lan.call(Ops.syncEnroll, args: answer) as Map);
      _taken = false;
      return true;
    } on Object catch (error) {
      if (error is Map && error["action"] == "site_has_master") {
        _taken = true;
      } else {
        // The network or the backend: the next time the internet returns tries again.
        _tried = false;
        debugPrint("sync: enrolment failed: $error");
      }
      return false;
    } finally {
      _working = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _hybrid.removeListener(_follow);
    CapabilityService().removeListener(_follow);
    super.dispose();
  }
}
