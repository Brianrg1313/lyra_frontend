import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart';

// SERVICES
import 'package:app/services/permissions/member_permissions_service.dart';
import 'package:app/services/permissions/permission_member_model.dart';
import 'package:app/services/permissions/sources/permissions_source.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';
import 'package:app/screens/home/sections/_section/section_message.dart';

import './employee_card.dart';

/// A section of the permission catalog (`PermissionCatalog.sections`, the backend's
/// `catalog.js`) as the editor draws it. The name is the catalog key, never renamed:
/// `test/permissions_test.dart` keeps this list and the catalog equal.
enum PermissionSection {
  inventory(CI.warehouse),
  reservations(CI.bookmark),
  pos(CI.cashbox),
  sales(CI.sale),
  money(CI.wallet),
  employees(CI.employee),
  permissions(CI.safe_user),
  products(CI.product),
  chats(CI.chat),
  channels(CI.ia),
  appointments(CI.calendar),
  knowledge(CI.documents),
  branches(CI.shop),
  delivery(CI.delivery),
  business(CI.store),
  server(CI.cloud_network);

  const PermissionSection(this.icon);

  final IconData icon;

  /// Its actions, in the catalog's order.
  List<String> get actions => PermissionCatalog.sections[name] ?? const [];

  String title(BuildContext context) => switch (this) {
    inventory => S.of(context).permission_inventory_title,
    reservations => S.of(context).permission_reservations_title,
    pos => S.of(context).permission_pos_title,
    sales => S.of(context).permission_sales_title,
    money => S.of(context).permission_money_title,
    employees => S.of(context).permission_employees_title,
    permissions => S.of(context).permission_permissions_title,
    products => S.of(context).permission_products_title,
    chats => S.of(context).permission_chats_title,
    channels => S.of(context).permission_channels_title,
    appointments => S.of(context).permission_appointments_title,
    knowledge => S.of(context).permission_knowledge_title,
    branches => S.of(context).permission_branches_title,
    delivery => S.of(context).permission_delivery_title,
    business => S.of(context).permission_business_title,
    server => S.of(context).permission_server_title
  };

  String description(BuildContext context) => switch (this) {
    inventory => S.of(context).permission_inventory_description,
    reservations => S.of(context).permission_reservations_description,
    pos => S.of(context).permission_pos_description,
    sales => S.of(context).permission_sales_description,
    money => S.of(context).permission_money_description,
    employees => S.of(context).permission_employees_description,
    permissions => S.of(context).permission_permissions_description,
    products => S.of(context).permission_products_description,
    chats => S.of(context).permission_chats_description,
    channels => S.of(context).permission_channels_description,
    appointments => S.of(context).permission_appointments_description,
    knowledge => S.of(context).permission_knowledge_description,
    branches => S.of(context).permission_branches_description,
    delivery => S.of(context).permission_delivery_description,
    business => S.of(context).permission_business_description,
    server => S.of(context).permission_server_description
  };

  /// What [action] lets the person do; the key itself for one this app has no words for yet.
  String action(BuildContext context, String action) {
    final s = S.of(context);

    return switch ("$name.$action") {
      "inventory.restock" => s.permission_inventory_restock,
      "inventory.remove" => s.permission_inventory_remove,
      "inventory.return" => s.permission_inventory_return,
      "inventory.hold" => s.permission_inventory_hold,
      "inventory.configure" => s.permission_inventory_configure,
      "inventory.pictures" => s.permission_inventory_pictures,
      "reservations.create" => s.permission_reservations_create,
      "reservations.manage" => s.permission_reservations_manage,
      "pos.sell" => s.permission_pos_sell,
      "pos.cancel" => s.permission_pos_cancel,
      "sales.fulfill" => s.permission_sales_fulfill,
      "money.charge" => s.permission_money_charge,
      "money.void" => s.permission_money_void,
      "money.accounts" => s.permission_money_accounts,
      "money.export" => s.permission_money_export,
      "employees.manage" => s.permission_employees_manage,
      "permissions.assign" => s.permission_permissions_assign,
      "permissions.templates" => s.permission_permissions_templates,
      "products.create" => s.permission_products_create,
      "products.edit" => s.permission_products_edit,
      "products.delete" => s.permission_products_delete,
      "products.import" => s.permission_products_import,
      "products.structure" => s.permission_products_structure,
      "chats.reply" => s.permission_chats_reply,
      "chats.manage" => s.permission_chats_manage,
      "chats.assign" => s.permission_chats_assign,
      "chats.bot" => s.permission_chats_bot,
      "channels.create" => s.permission_channels_create,
      "channels.edit" => s.permission_channels_edit,
      "channels.delete" => s.permission_channels_delete,
      "channels.connect" => s.permission_channels_connect,
      "appointments.book" => s.permission_appointments_book,
      "appointments.configure" => s.permission_appointments_configure,
      "knowledge.create" => s.permission_knowledge_create,
      "knowledge.edit" => s.permission_knowledge_edit,
      "knowledge.delete" => s.permission_knowledge_delete,
      "branches.create" => s.permission_branches_create,
      "branches.edit" => s.permission_branches_edit,
      "branches.delete" => s.permission_branches_delete,
      "delivery.create" => s.permission_delivery_create,
      "delivery.edit" => s.permission_delivery_edit,
      "delivery.delete" => s.permission_delivery_delete,
      "business.edit" => s.permission_business_edit,
      "business.emails" => s.permission_business_emails,
      "server.devices" => s.permission_server_devices,
      "server.backups" => s.permission_server_backups,
      "server.stop" => s.permission_server_stop,
      final key => key
    };
  }
}

/// A template's name and description in this app's words: the platform's by code, a company's
/// as its people wrote them.
({String name, String? description}) permissionTemplateText(BuildContext context, PermissionTemplateModel template) {
  final s = S.of(context);
  if (!template.global) return (name: template.name, description: template.description);

  return switch (template.id) {
    "owner" => (name: s.permission_preset_owner, description: s.permission_preset_owner_description),
    "manager" => (name: s.permission_preset_manager, description: s.permission_preset_manager_description),
    "marketing" => (name: s.permission_preset_marketing, description: s.permission_preset_marketing_description),
    "seller" => (name: s.permission_preset_seller, description: s.permission_preset_seller_description),
    "auditor" => (name: s.permission_preset_auditor, description: s.permission_preset_auditor_description),
    "billing" => (name: s.permission_preset_billing, description: s.permission_preset_billing_description),
    "finance" => (name: s.permission_preset_finance, description: s.permission_preset_finance_description),
    _ => (name: template.name, description: template.description)
  };
}

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
              _Sheet(section: entry.key, actions: entry.value, service: _service)
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

/// Sizes of a sheet. Every row puts its switch in the same slot, so the switches read as one
/// column down the panel.
abstract final class _Grid {
  static double get cell => AppSize.text * 2.3;
  static double get inset => AppSize.spaceXS;

  /// Room left of an action for the thread that ties it to its section.
  static double get indent => inset + cell + AppSize.spaceS;
}

/// One section: its own row (icon, title, description, how many actions are on, the switch that
/// lets the person in), then its actions threaded under it, since an action holds only with it.
class _Sheet extends StatelessWidget {
  const _Sheet({required this.section, required this.actions, required this.service});

  final PermissionSection section;

  /// The actions to draw (all of them, or the ones the search matched).
  final List<String> actions;
  final MemberPermissionsService service;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final key = section.name;
    final open = service.flag(key, PermissionCatalog.access);
    final on = section.actions.where((action) => service.flag(key, action)).length;
    final tone = open ? scheme.primary : scheme.text.secondary;
    final title = section.title(context);

    final head = _Row(
      leading: Padding(
        padding: EdgeInsets.fromLTRB(_Grid.inset, _Grid.inset, AppSize.spaceS, _Grid.inset),
        child: Align(
          alignment: Alignment.topCenter,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: _Grid.cell,
            height: _Grid.cell,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(EmployeeFactFrame.radius)
            ),
            child: Center(child: Icon(section.icon, size: EmployeeFactFrame.iconSize, color: tone))
          )
        )
      ),
      text: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextMedium(title, bold: true, ellipsis: true),
          TextSmall(section.description(context), lines: 2, ellipsis: true, color: scheme.text.secondary),
          if (section.actions.isNotEmpty) ...[
            SizedBox(height: AppSize.spaceXS * 0.4),
            TextSmall(S.of(context).permission_group_count(on, section.actions.length), color: tone, multiplier: 0.9)
          ]
        ]
      ),
      cell: _Cell(
        on: open,
        icon: CI.eye,
        message: title,
        toggle: _toggle(key, PermissionCatalog.access, key),
        locked: _locked(key)
      )
    );

    return Surface(
      color: scheme.surface,
      radius: EmployeeFactFrame.sheetRadius,
      padding: EdgeInsets.all(_Grid.inset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          head,
          for (final action in actions)
            _Row(
              leading: SizedBox(
                width: _Grid.indent,
                child: _Thread(last: action == actions.last, open: open && service.flag(key, action))
              ),
              text: TextSmall(
                section.action(context, action),
                lines: 2,
                ellipsis: true,
                // An action stored under a closed section grants nothing (`can` needs both).
                color: open ? scheme.text.primary : scheme.text.secondary
              ),
              cell: _Cell(
                on: service.flag(key, action),
                dim: !open,
                icon: CI.check,
                message: S.of(context).permission_access_cell(section.action(context, action), title),
                toggle: _toggle(key, action, "$key.$action"),
                locked: _locked("$key.$action")
              )
            )
        ]
      )
    );
  }

  /// The press of one switch, none when the viewer may not change [key].
  VoidCallback? _toggle(String section, String flag, String key) =>
    service.canChange(key) ? () => service.toggle(section, flag) : null;

  /// An editable person with a key the viewer does not hold (escalation, `session.md` P-6).
  bool _locked(String key) => !service.readOnly && !service.canChange(key);
}

class _Row extends StatelessWidget {
  const _Row({required this.leading, required this.text, required this.cell});

  final Widget leading;
  final Widget text;
  final Widget cell;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(child: Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      leading,
      Expanded(child: Padding(
        padding: EdgeInsets.symmetric(vertical: _Grid.inset),
        child: Align(alignment: Alignment.centerLeft, child: text)
      )),
      Padding(
        padding: EdgeInsets.only(left: AppSize.spaceS, right: _Grid.inset),
        child: Center(child: cell)
      )
    ]
  ));
}

/// The line down from the section's icon to each action, lit at the branch while the action
/// holds.
class _Thread extends StatelessWidget {
  const _Thread({required this.last, required this.open});

  final bool last;
  final bool open;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final stroke = AppSize.text * 0.12;
    final left = _Grid.inset + _Grid.cell / 2 - stroke / 2;

    return Stack(children: [
      Positioned(
        left: left,
        top: 0,
        bottom: 0,
        child: FractionallySizedBox(
          heightFactor: last ? 0.5 : 1,
          alignment: Alignment.topCenter,
          child: Container(width: stroke, color: scheme.line)
        )
      ),
      Positioned(
        left: left,
        right: AppSize.spaceXS,
        top: 0,
        bottom: 0,
        child: Center(child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: stroke,
          color: open ? scheme.primary : scheme.line
        ))
      )
    ]);
  }
}

/// One switch. On is a solid mark in the button colors, the strongest thing in the list; off is
/// an outline. Without [toggle] it is only drawn.
class _Cell extends StatelessWidget {
  const _Cell({
    required this.on,
    required this.icon,
    required this.message,
    required this.toggle,
    this.locked = false,
    this.dim = false
  });

  final bool on;
  final IconData icon;
  final String message;
  final VoidCallback? toggle;

  /// The viewer may not give or take it: a key instead of the icon while off, and says why.
  final bool locked;

  /// Under a closed section: stored, granting nothing.
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final size = _Grid.cell;
    final fill = dim ? scheme.button.fill.withValues(alpha: 0.4) : scheme.button.fill;

    final mark = SizedBox(
      width: size,
      height: size,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: on ? fill : Colors.transparent,
          border: Border.all(color: on ? fill : scheme.line, width: AppSize.text * 0.1),
          borderRadius: BorderRadius.circular(EmployeeFactFrame.radius)
        ),
        child: Center(child: Icon(
          on ? CI.check : locked ? CI.key : icon,
          size: EmployeeFactFrame.hintSize,
          color: on ? scheme.button.text : scheme.text.secondary.withValues(alpha: 0.6)
        ))
      )
    );

    if (locked) return Tooltip(message: S.of(context).permission_locked, child: mark);
    if (toggle == null) return mark;

    return FeedbackButton(
      action: toggle!,
      message: message,
      radius: EmployeeFactFrame.radius,
      width: size,
      height: size,
      color: Colors.transparent,
      feedbackColor: scheme.line,
      child: mark
    );
  }
}
