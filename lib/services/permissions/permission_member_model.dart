// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart';

/// Where a member's permissions were copied from (`template: {scope, id, name}`). [name] is null
/// once the template is gone: the label stays, the template doesn't.
class PermissionTemplateRef {
  const PermissionTemplateRef({required this.scope, required this.id, this.name});

  final String scope;
  final String id;
  final String? name;

  static PermissionTemplateRef? from(Object? raw) {
    if (raw is! Map || raw["id"] == null) return null;

    return PermissionTemplateRef(
      scope: raw["scope"]?.toString() ?? "",
      id: raw["id"].toString(),
      name: raw["name"]?.toString()
    );
  }
}

/// One member's permissions as the editor opens them (`GET /permissions/members/detail/:USERNAME`,
/// `permissions.members.detail`): the cloud's per-person document, in the catalog's keys.
///
/// [access] false is someone with an active job and no membership yet: assigning them is what
/// lets them in (`session.md` P-5, P-6).
class PermissionMemberModel {
  const PermissionMemberModel({
    required this.username,
    this.name = "",
    this.lastName = "",
    this.me = false,
    this.owner = false,
    this.access = false,
    required this.grant,
    this.template,
    this.custom = false
  });

  final String username;
  final String name;
  final String lastName;
  final bool me;

  /// Created the company: always `all`, never changed (`permissions_owner`).
  final bool owner;
  final bool access;
  final Grant grant;
  final PermissionTemplateRef? template;

  /// Changed by hand after [template] was copied onto them.
  final bool custom;

  static PermissionMemberModel? from(Object? raw) {
    if (raw is! Map || raw["username"] == null) return null;

    final owner = raw["owner"] == true;

    return PermissionMemberModel(
      username: raw["username"].toString(),
      name: raw["name"]?.toString() ?? "",
      lastName: raw["last_name"]?.toString() ?? "",
      me: raw["me"] == true,
      owner: owner,
      access: raw["access"] == true,
      grant: Grant(all: owner || raw["all"] == true, sections: _sections(raw["sections"])),
      template: PermissionTemplateRef.from(raw["template"]),
      custom: raw["custom"] == true
    );
  }
}

/// A template to start a member from (`GET /permissions/templates`): the platform's (`global`,
/// [id] is its code) or the company's own.
class PermissionTemplateModel {
  const PermissionTemplateModel({
    required this.id,
    required this.scope,
    required this.name,
    this.description,
    required this.grant
  });

  final String id;
  final String scope;
  final String name;
  final String? description;
  final Grant grant;

  bool get global => scope == "global";

  static PermissionTemplateModel? from(Object? raw) {
    if (raw is! Map || raw["id"] == null) return null;

    return PermissionTemplateModel(
      id: raw["id"].toString(),
      scope: raw["scope"]?.toString() ?? "company",
      name: raw["name"]?.toString() ?? "",
      description: raw["description"]?.toString(),
      grant: Grant(all: raw["all"] == true, sections: _sections(raw["sections"]))
    );
  }

  static List<PermissionTemplateModel> listFrom(Object? raw) => [
    if (raw is List)
      for (final row in raw) ?PermissionTemplateModel.from(row)
  ];
}

/// The viewer's own permissions (`GET /permissions` → `mine`, `permissions.get`).
Grant permissionsMine(Object? answer) {
  final mine = answer is Map ? answer["mine"] : null;
  if (mine is! Map) return Grant.none();

  return Grant(all: mine["all"] == true, sections: _sections(mine["sections"]));
}

PermissionSections? _sections(Object? raw) => raw is Map
  ? {
      for (final MapEntry(:key, :value) in raw.entries)
        if (value is Map) "$key": {for (final flag in value.entries) "${flag.key}": flag.value == true}
    }
  : null;
