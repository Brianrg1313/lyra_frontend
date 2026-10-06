// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart';

// SERVICES
import 'package:app/services/permissions/permission_member_model.dart';

/// Where a company's permissions are read and changed: the cloud's `/permissions` or a master's
/// `permissions.*` ops (`docs/offline/specs/session.md` session.permissions), the same model in
/// both. Members are named by `username`.
abstract interface class PermissionsSource {
  /// The viewer's own permissions in the active company.
  Future<Grant> mine();

  /// Whether only the cloud changes permissions here: a master that syncs with its cloud company
  /// (`session.md` P-12). Never the cloud's own.
  Future<bool> online();

  /// Every template the company may apply, the platform's first.
  Future<List<PermissionTemplateModel>> templates();

  /// One member, or someone with an active job and no access yet.
  Future<PermissionMemberModel> member(String username);

  /// Copies [template] onto the member and/or lays the partial [permissions] over it.
  Future<void> assign(String username, {String? template, Map<String, Map<String, bool>>? permissions});

  /// Takes the member's access away; their permissions stay for when it comes back.
  Future<void> revoke(String username);
}
