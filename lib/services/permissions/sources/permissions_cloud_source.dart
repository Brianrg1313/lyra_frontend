// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart';

// SERVICES
import 'package:app/services/permissions/permission_member_model.dart';
import 'package:app/services/permissions/permission_member_request.dart';
import 'package:app/services/permissions/sources/permissions_source.dart';
import 'package:app/toolkit/api.dart';
import 'package:app/toolkit/deployment.dart';

/// [PermissionsSource] over the backend's REST api (`/lyra/v1/permissions`).
class PermissionsCloudSource implements PermissionsSource {
  const PermissionsCloudSource();

  @override
  Future<Grant> mine() async => permissionsMine(await api.get(path: "/permissions/", version: "v1"));

  @override
  Future<bool> online() async => false;

  @override
  Future<List<PermissionTemplateModel>> templates() async =>
    PermissionTemplateModel.listFrom(await api.get(path: "/permissions/templates/", version: "v1"));

  @override
  Future<PermissionMemberModel> member(String username) async {
    // No trailing slash: the username is a route segment (`params: ["USERNAME"]`).
    final data = await api.get(path: "/permissions/members/detail/${Uri.encodeComponent(username)}", version: "v1");

    return PermissionMemberModel.from(data) ?? (throw const UnreadableAnswer("permissions/members/detail"));
  }

  @override
  Future<void> assign(
    String username, {
    String? template,
    Map<String, Map<String, bool>>? permissions,
    ({List<String>? ids})? branches,
    String? branch,
    bool reset = false
  }) => api.put(
    path: "/permissions/members/",
    version: "v1",
    data: assignMemberRequest(
      username: username,
      template: template,
      permissions: permissions,
      branches: branches,
      branch: branch,
      reset: reset
    )
  );

  @override
  Future<void> revoke(String username) =>
    api.delete(path: "/permissions/members/", version: "v1", data: {"USERNAME": username});
}
