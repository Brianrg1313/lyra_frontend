import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/permissions/member_permissions_service.dart';
import 'package:app/services/permissions/permission_member_model.dart';
import 'package:app/services/permissions/sources/permissions_source.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';
import 'package:app/screens/home/sections/_section/section_message.dart';
import 'package:app/screens/home/sections/business/employees/employee_facts/employee_search.dart';
import 'package:app/screens/home/sections/business/employees/employee_facts/widgets/employee_fact_frame.dart';

import './permission_section.dart';
import './permission_sheet.dart';
import './permission_template_text.dart';

/// One person's permissions in the active company, in the catalog's keys: the cloud's
/// `/permissions/members` or a master's `permissions.members.*`, the same model in both
/// (`docs/offline/specs/session.md` session.permissions).
///
/// A template to start from, a search, then one sheet per [PermissionSection]: its own switch
/// (entering it) and one per action under it. Changes are a draft until saved; a person with a
/// job and no access yet is let in by saving.
///
/// Without [username] it is the viewer's own permissions, which nobody changes for themselves.
/// A key the viewer does not hold is drawn locked: nobody gives or takes what they don't have.
class EmployeePermissions extends StatefulWidget {
  const EmployeePermissions({super.key, this.username, this.person = "", this.source});

  final String? username;

  /// The person's name, for the messages that name them.
  final String person;

  /// Test seam; [Sources.permissions] otherwise.
  final PermissionsSource? source;

  @override
  State<EmployeePermissions> createState() => _EmployeePermissionsState();
}

class _EmployeePermissionsState extends State<EmployeePermissions> {
  /// Filtered on each key: it only hides sheets already drawn.
  final _search = InputController(key: "search");
  final _template = InputController.select(key: "template");
  final _saving = ValueNotifier(false);

  late final _service = MemberPermissionsService(username: widget.username, source: widget.source);

  @override
  void initState() {
    super.initState();
    _search.textController.addListener(_changed);
    _service.addListener(_changed);
    // After this frame: the load notifies at once, and a State being created can't be rebuilt.
    Future.microtask(_service.load);
  }

  @override
  void dispose() {
    _search.textController.removeListener(_changed);
    _search.form.dispose();
    _template.form.dispose();
    _saving.dispose();
    _service.dispose();
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    _saving.value = _service.saving;
    setState(() {});
  }

  Future<void> _save() async {
    final first = _service.member?.access == false;

    try {
      await _service.save();
      _template.textController.clear();
      _template.selectedValue = null;
      if (mounted && !first) FloatFlag.of(context).message(S.of(context).permission_saved);
    } catch (e) {
      FloatFlag.showFromError(e);
    }
  }

  void _discard() {
    _template.textController.clear();
    _template.selectedValue = null;
    _service.discard();
  }

  Future<void> _revoke() async {
    final s = S.of(context);
    final name = widget.person;

    final confirmed = await showAlertModal(
      context: context,
      title: s.permission_revoke_title(name),
      message: s.permission_revoke_message,
      confirmText: s.permission_revoke_confirm,
      cancelText: s.cancel
    );
    if (!confirmed) return;

    try {
      await _service.revoke();
      if (mounted) FloatFlag.of(context).message(S.of(context).permission_revoked(name));
    } catch (e) {
      FloatFlag.showFromError(e);
    }
  }

  @override
  Widget build(BuildContext context) => switch (_service.status) {
    MemberPermissionsStatus.ready => _ready(context),
    MemberPermissionsStatus.error => SectionMessage(
      icon: CI.safe_user,
      title: S.of(context).permission_load_error,
      action: _service.load,
      actionLabel: S.of(context).permission_retry
    ),
    _ => const Center(child: Loading())
  };

  Widget _ready(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final search = EmployeeSearch(query: _search.text, child: const SizedBox.shrink());
    final member = _service.member;
    final note = _note(context);

    // A sheet shows whole when its section matches; otherwise only the actions that match.
    final shown = <PermissionSection, List<String>>{};
    for (final section in PermissionSection.values) {
      final whole = search.matches(section.title(context)) || search.matches(section.description(context));
      final actions = [
        for (final action in section.actions)
          if (whole || search.matches(section.action(context, action))) action
      ];

      if (whole || actions.isNotEmpty) shown[section] = actions;
    }

    final templates = [
      for (final template in _service.templates)
        if (_service.canApply(template)) template
    ];

    // The search and the template stay put and only the sheets scroll: the side modal does not
    // scroll its body, it lends its bar to the first [ScrollableWidget].
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (note != null) Padding(
          padding: EdgeInsets.only(bottom: AppSize.spaceS),
          child: TextSmall(note, lines: 3, ellipsis: true, color: scheme.text.secondary)
        ),
        if (templates.isNotEmpty) ...[
          SelectInput(
            controller: _template,
            title: S.of(context).permission_template_title,
            placeholder: S.of(context).permission_template_placeholder,
            emptyText: S.of(context).permission_template_empty,
            options: [
              for (final template in templates)
                SelectOption(
                  value: template.id,
                  placeholder: permissionTemplateText(context, template).name,
                  subtitle: permissionTemplateText(context, template).description
                )
            ],
            onSelected: (option) => _service.apply(templates.firstWhere((t) => t.id == option.value))
          ),
          SizedBox(height: AppSize.spaceXS)
        ],
        Input(
          controller: _search,
          placeholder: S.of(context).permission_search_hint,
          leftIcon: Icon(CI.search, size: EmployeeFactFrame.hintSize, color: scheme.text.secondary),
          buttonSpace: false,
          fillColor: scheme.surface,
          radius: EmployeeFactFrame.sheetRadius
        ),
        SizedBox(height: AppSize.spaceS),
        Expanded(child: ScrollableWidget(
          padding: EdgeInsets.only(bottom: AppSize.padding),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (shown.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: AppSize.spaceL),
                child: Center(child: TextSmall(S.of(context).permission_search_empty, color: scheme.text.secondary))
              ),
            for (final entry in shown.entries) ...[
              if (entry.key != shown.keys.first) SizedBox(height: AppSize.spaceS),
              PermissionSheet(section: entry.key, actions: entry.value, service: _service)
            ]
          ]
        )),
        if (member != null && !_service.readOnly) _footer(context, member)
      ]
    );
  }

  /// What the person's permissions are, in one line, when there is something to say about them.
  String? _note(BuildContext context) {
    final s = S.of(context);
    final member = _service.member;
    final picked = _service.template;

    if (member == null) return s.permission_own_read_only;
    if (member.owner) return s.permission_owner_note;
    if (member.online) return s.permission_online_note;
    if (member.grant.all && !_service.mine.all) return s.permission_all_locked;
    if (!member.access) return s.permission_no_access_note;
    if (picked != null) return s.permission_template_picked(permissionTemplateText(context, picked).name);
    if (_service.all) return s.permission_all_note;

    final name = member.template?.name;
    if (name == null) return null;

    return member.custom ? s.permission_template_custom(name) : s.permission_template_from(name);
  }

  /// Discard and save while there is a draft (give access for someone not let in yet); remove
  /// access otherwise.
  Widget _footer(BuildContext context, PermissionMemberModel member) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);
    final saving = _service.saving;

    final secondary = !member.access
      ? null
      : _service.dirty
        ? (label: s.cancel, action: _discard, color: scheme.text.primary)
        : (label: s.permission_revoke, action: _revoke, color: scheme.accent);

    return Padding(
      padding: EdgeInsets.only(top: AppSize.spaceS),
      child: Row(children: [
        if (secondary != null)
          Expanded(child: FeedbackButton(
            action: saving ? null : secondary.action,
            height: AppSize.button,
            message: secondary.label,
            radius: AppSize.cornerInset(AppSize.gap),
            color: scheme.surfaceOver,
            child: Center(child: TextSmall(secondary.label, color: saving ? scheme.text.secondary : secondary.color))
          )),
        if (secondary != null && _service.dirty) SizedBox(width: AppSize.spaceXS),
        if (_service.dirty)
          Expanded(child: Button(
            title: member.access ? s.save : s.permission_give_access,
            loading: _saving,
            action: _save
          ))
      ])
    );
  }
}
