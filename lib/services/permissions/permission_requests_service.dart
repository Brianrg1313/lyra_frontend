import 'dart:async';

import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/permissions/permission_request_model.dart';
import 'package:app/services/client/sources/session_source.dart';
import 'package:app/toolkit/deployment.dart';
import 'package:app/toolkit/settings/initial_builder.dart' show clientService;

enum PermissionRequestsStatus { idle, loading, ready, error }

/// The person's own permission requests in the active company (`/permissions/requests/`),
/// so a locked section says "requested" instead of offering to ask again.
///
/// Owned by the screen that shows a missing permission, not app-wide: the list belongs to the
/// active company, and that screen is remounted on every business switch.
class PermissionRequestsService extends ChangeNotifier {
  PermissionRequestsService({SessionSource? source}) : _injected = source;

  final SessionSource? _injected;

  SessionSource get _source => _injected ?? Sources.session;

  PermissionRequestsStatus _status = PermissionRequestsStatus.idle;
  List<PermissionRequestModel> _requests = const [];

  PermissionRequestsStatus get status => _status;
  List<PermissionRequestModel> get requests => _requests;

  /// Whether [permission] was asked for and is still waiting.
  bool isPending(String permission) =>
    _requests.any((request) => request.permission == permission && request.isPending);

  /// A failed read leaves the list empty: the worst outcome is offering to ask again, and
  /// the backend refuses a duplicate.
  Future<void> load() async {
    if (_status == PermissionRequestsStatus.loading) return;

    _status = PermissionRequestsStatus.loading;
    notifyListeners();

    try {
      _requests = await _source.permissionRequests();
      _status = PermissionRequestsStatus.ready;
    } catch (error) {
      if (kDebugMode) print("permission requests read failed: $error");

      _status = PermissionRequestsStatus.error;
    }

    notifyListeners();
  }

  /// Asks for [permission]. Throws the api error (already normalized to `{message, …}`);
  /// the caller shows it. On success the request is held as pending without a reread.
  ///
  /// A `409` means this screen is behind: the request is already pending, or the permission
  /// was granted since `/init`. Both are reread before rethrowing, so the screen redraws as
  /// "requested" or opens the section.
  Future<void> request(String permission, {String? reason}) async {
    final String id;

    try {
      id = await _source.requestPermission(permission, reason: reason);
    } catch (error) {
      if (error is Map && error["code"] == 409) {
        unawaited(clientService.refreshCatalogs());
        await load();
      }
      rethrow;
    }

    _requests = [
      PermissionRequestModel(
        id: id,
        permission: permission,
        state: PermissionRequestState.pending,
        reason: reason?.trim().isEmpty ?? true ? null : reason!.trim(),
        createdAt: DateTime.now()
      ),
      ..._requests
    ];

    notifyListeners();
  }

  @visibleForTesting
  void seed(List<PermissionRequestModel> requests) {
    _requests = requests;
    _status = PermissionRequestsStatus.ready;
    notifyListeners();
  }
}
