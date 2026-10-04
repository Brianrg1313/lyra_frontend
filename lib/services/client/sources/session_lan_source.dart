// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart';

// SERVICES
import 'package:app/services/business/sources/business_lan_source.dart';
import 'package:app/services/client/sources/session_source.dart';
import 'package:app/services/lan/lan_service.dart';
import 'package:app/services/permissions/permission_request_model.dart';
import 'package:app/services/sign_in/login_method.dart';
import 'package:app/toolkit/deployment.dart';

/// [SessionSource] over the master (`docs/offline/specs/session.md`).
///
/// Signing in happens on the sign in page (`AuthMaster`, through `LanService`), before any service reads a source: by
/// the time [ClientService] resolves, the connection is open and bound. So the cloud's sign-in
/// steps and invitations have no LAN side here (S-7); the one task is `business.none`, a master
/// set up without its company (S-31).
class SessionLanSource implements SessionSource {
  const SessionLanSource(this._lan);

  final LanService _lan;

  @override
  Future<bool> hasSession() async => _lan.status == LanStatus.ready;

  @override
  Future<Map<String, dynamic>> bootstrap() async {
    final answer = await _lan.call(Ops.sessionBootstrap);
    if (answer is! Map) throw const UnreadableAnswer("session.bootstrap");

    return initFrom(answer);
  }

  /// `session.bootstrap` in the shape `/init` has, which is what each seed reads
  /// (`ClientService.resolve`): the person at the top level in its keys, the catalogues at the
  /// top level. A logo id becomes the `FileModel` json the cloud sends.
  static Map<String, dynamic> initFrom(Map answer) {
    final client = answer["client"] is Map ? answer["client"] as Map : const {};
    final catalogs = answer["catalogs"] is Map ? answer["catalogs"] as Map : const {};

    return {
      "name": client["name"] ?? "",
      "last_name": client["lastName"] ?? "",
      "username": client["username"] ?? "",
      "email": client["email"] ?? "",
      "sex": client["sex"],
      "picture": null,
      "birthday": client["birthday"],
      "businesses": [
        for (final business in answer["businesses"] as List? ?? const [])
          if (business is Map) {...business, "logo": BusinessLanSource.fileJson(business["logo"])}
      ],
      "permissions": answer["permissions"],
      "owned": answer["owned"],
      "tasks": [
        for (final task in answer["tasks"] as List? ?? const [])
          if (task is Map) {...task}
      ],
      "countries": catalogs["countries"],
      "currencies": catalogs["currencies"],
    };
  }

  @override
  Future<void> signOut() => _lan.signOut();

  /// Nobody has a pending invitation offline: activating one accepts it (S-8, S-31).
  @override
  Future<void> acceptInvitation(String id) => throw UnsupportedError("No invitations on a master");

  @override
  Future<({bool account, LoginMethod? method})> identify(String email) =>
    throw UnsupportedError("Signing in to a master goes through LanService");

  @override
  Future<Object?> signInWithPassword(String email, String password) =>
    throw UnsupportedError("Signing in to a master goes through LanService");

  @override
  Future<Object?> signInWithCode(String email, String code) =>
    throw UnsupportedError("No codes on a master");

  /// `permissions.requests.list` answers `created` where the cloud says `created_at`.
  @override
  Future<List<PermissionRequestModel>> permissionRequests() async {
    final answer = await _lan.call(Ops.permissionsRequestsList);

    return PermissionRequestModel.listFromTable([
      if (answer is List)
        for (final row in answer)
          if (row is Map) {...row, "created_at": row["created"]}
    ]);
  }

  @override
  Future<String> requestPermission(String permission, {String? reason}) async {
    final answer = await _lan.call(Ops.permissionsRequestsCreate, args: {"permission": permission, "reason": ?reason});

    return answer is Map ? answer["id"]?.toString() ?? "" : "";
  }
}
