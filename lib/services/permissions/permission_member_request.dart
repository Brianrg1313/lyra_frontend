/// `PUT /permissions/members/` body. `TEMPLATE_ID` copies a template onto the member;
/// `PERMISSIONS` is always partial (`{pos: {access: true, cancel: true}}`), laid over that template
/// or over what they had. Neither: the member is only let in (`session.md` P-5).
///
/// Branches (`sedes-frontend.md` §4): [branches] is where they work, sent only when given
/// (`(ids: null)` or an empty list is every branch; a branch taken off drops its own structure).
/// [branch] makes the template and permissions that branch's own structure, laid over it or over
/// the base until it has one; [reset] with [branch] puts that branch back on the base.
Map<String, dynamic> assignMemberRequest({
  required String username,
  String? template,
  Map<String, Map<String, bool>>? permissions,
  ({List<String>? ids})? branches,
  String? branch,
  bool reset = false
}) => {
  "USERNAME": username,
  "TEMPLATE_ID": ?template,
  if (permissions != null && permissions.isNotEmpty) "PERMISSIONS": permissions,
  if (branches != null) "BRANCHES": branches.ids,
  "BRANCH": ?branch,
  if (branch != null && reset) "RESET": true
};
