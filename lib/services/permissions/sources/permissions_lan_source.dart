// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart';

// SERVICES
import 'package:app/services/permissions/permission_member_model.dart';
import 'package:app/services/permissions/sources/permissions_source.dart';
import 'package:app/services/lan/lan_service.dart';
import 'package:app/toolkit/deployment.dart';

/// [PermissionsSource] over the master (`docs/offline/specs/session.md` session.permissions).
///
/// The ops answer the cloud's shapes in the spec's names (`lastName`); this lays them out as the
/// cloud's so the models read one shape.
class PermissionsLanSource implements PermissionsSource {
  const PermissionsLanSource(this._lan);

  final LanService _lan;

  @override
  Future<Grant> mine() async => permissionsMine(await _lan.call(Ops.permissionsGet));

  @override
  Future<bool> online() async {
    final answer = await _lan.call(Ops.permissionsGet);

    return answer is Map && answer["online"] == true;
  }

  @override
  Future<List<PermissionTemplateModel>> templates() async =>
    PermissionTemplateModel.listFrom(await _lan.call(Ops.permissionsTemplatesList));

  @override
  Future<PermissionMemberModel> member(String username) async {
    final answer = await _lan.call(Ops.permissionsMembersDetail, args: {"username": username});

    return PermissionMemberModel.from(answer is Map ? {...answer, "last_name": answer["lastName"]} : null) ??
      (throw const UnreadableAnswer("permissions.members.detail"));
  }

  @override
  Future<void> assign(String username, {String? template, Map<String, Map<String, bool>>? permissions}) =>
    _lan.call(Ops.permissionsMembersAssign, args: {
      "username": username,
      "template": ?template,
      if (permissions != null && permissions.isNotEmpty) "permissions": permissions
    });

  @override
  Future<void> revoke(String username) => _lan.call(Ops.permissionsMembersRevoke, args: {"username": username});
}
