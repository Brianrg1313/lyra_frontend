/// `PUT /permissions/members/` body. `TEMPLATE_ID` copies a template onto the member;
/// `PERMISSIONS` is always partial (`{pos: {access: true, cancel: true}}`), laid over that template
/// or over what they had. Neither: the member is only let in (`session.md` P-5).
Map<String, dynamic> assignMemberRequest({
  required String username,
  String? template,
  Map<String, Map<String, bool>>? permissions
}) => {
  "USERNAME": username,
  "TEMPLATE_ID": ?template,
  if (permissions != null && permissions.isNotEmpty) "PERMISSIONS": permissions
};
