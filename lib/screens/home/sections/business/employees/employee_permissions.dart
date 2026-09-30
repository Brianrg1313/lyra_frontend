import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/permissions/permissions_service.dart';

// WIDGETS
import 'package:core/form.dart';

import './employee_card.dart';

/// The four switches every permission row offers. They are the simple face of
/// the catalog's actions (`docs/app-areas.json`): `create` stands for the
/// area's ways of adding (invite, record, sell…), `edit` for changing what is
/// there, `delete` for removing or voiding.
enum PermissionAccess {
  view(CI.eye),
  create(CI.plus),
  edit(CI.edit),
  delete(CI.trash);

  const PermissionAccess(this.icon);

  final IconData icon;

  /// The switch a catalog action (`docs/app-areas.json`) is drawn under.
  /// Reading variants are `view`; what is not adding or removing is `edit`.
  static PermissionAccess of(String action) => switch (action) {
    "view" || "view_personal" || "view_all" || "view_bot_cost" || "view_usage" => view,
    "create" || "invite" || "record" || "sell" || "create_table" || "import" ||
      "custom_amount" || "set_tax" || "checkout" => create,
    "delete" || "void" || "delete_table" || "cancel_ticket" => delete,
    _ => edit
  };

  String label(BuildContext context) => switch (this) {
    view => S.of(context).permission_access_view,
    create => S.of(context).permission_access_create,
    edit => S.of(context).permission_access_edit,
    delete => S.of(context).permission_access_delete
  };
}

const _viewOnly = {PermissionAccess.view};
const _all = {PermissionAccess.view, PermissionAccess.create, PermissionAccess.edit, PermissionAccess.delete};

/// Every company area of `docs/app-areas.json` that can be granted, in the
/// side bar's order. [area] is the catalog's key, never renamed; [actions] are
/// the switches that area has a meaning for — the rest are drawn but off.
/// Placeholder areas (services, marketing, report, external services) are
/// left out until they hold something to guard.
enum EmployeePermission {
  business("business", CI.store, {PermissionAccess.view, PermissionAccess.delete}),
  businessStatistics("business.statistics", CI.chart, _viewOnly),
  businessEmployees("business.employees", CI.employee, {PermissionAccess.view, PermissionAccess.create, PermissionAccess.edit}),
  businessBranches("business.branches", CI.shop, {PermissionAccess.view, PermissionAccess.create, PermissionAccess.edit}),
  businessClients("business.clients", CI.user, _viewOnly),
  businessSettings("business.settings", CI.setting, {PermissionAccess.view, PermissionAccess.edit}),
  messages("messages", CI.chat, {PermissionAccess.view, PermissionAccess.edit}),
  deliveries("deliveries", CI.delivery, {PermissionAccess.view, PermissionAccess.create}),
  deliveriesSettings("deliveries.settings", CI.setting, {PermissionAccess.view, PermissionAccess.edit}),
  deliveriesAreas("deliveries.areas", CI.globe_shopping, _all),
  sales("sales", CI.sale, {PermissionAccess.view, PermissionAccess.edit}),
  salesProcess("sales.process", CI.task_list, _viewOnly),
  salesDone("sales.done", CI.shopping_check, _viewOnly),
  inventory("inventory", CI.inventory, _all),
  channels("channels", CI.ia, _all),
  finance("finance", CI.wallet, _viewOnly),
  financeOverview("finance.overview", CI.chart, _viewOnly),
  financePayments("finance.payments", CI.invoice_list, {PermissionAccess.view, PermissionAccess.create, PermissionAccess.delete}),
  financeReceivables("finance.receivables", CI.receipt, {PermissionAccess.view, PermissionAccess.edit}),
  financeMethods("finance.methods", CI.discount_card, _all),
  connections("connections", CI.cloud_connected, _all),
  pos("pos", CI.cashbox, {PermissionAccess.view, PermissionAccess.create, PermissionAccess.delete});

  const EmployeePermission(this.area, this.icon, this.actions);

  final String area;
  final IconData icon;
  final Set<PermissionAccess> actions;

  /// The area it sits under (`business` for `business.employees`): a child's
  /// `view` requires its parent's, as the catalog's contract says.
  EmployeePermission? get parent {
    final dot = area.lastIndexOf(".");
    if (dot < 0) return null;

    final key = area.substring(0, dot);
    return values.where((p) => p.area == key).firstOrNull;
  }

  /// The root area, which names the group the row is listed in.
  EmployeePermission get root => parent?.root ?? this;

  /// What the viewer holds in the active company, in the matrix's words: the
  /// `/init` grants ([PermissionsService]), each action under its switch.
  static Map<EmployeePermission, Set<PermissionAccess>> own() {
    final permissions = PermissionsService();
    final grants = <EmployeePermission, Set<PermissionAccess>>{};

    for (final permission in values) {
      final actions = permissions.granted(permission.area);

      if (actions == null) {
        grants[permission] = {...permission.actions};
      } else if (actions.contains("view")) {
        grants[permission] = {
          for (final action in actions) PermissionAccess.of(action)
        }.intersection(permission.actions);
      }
    }

    return grants;
  }

  String title(BuildContext context) => switch (this) {
    business => S.of(context).permission_business_title,
    businessStatistics => S.of(context).permission_business_statistics_title,
    businessEmployees => S.of(context).permission_business_employees_title,
    businessBranches => S.of(context).permission_business_branches_title,
    businessClients => S.of(context).permission_business_clients_title,
    businessSettings => S.of(context).permission_business_settings_title,
    messages => S.of(context).permission_messages_title,
    deliveries => S.of(context).permission_deliveries_title,
    deliveriesSettings => S.of(context).permission_deliveries_settings_title,
    deliveriesAreas => S.of(context).permission_deliveries_areas_title,
    sales => S.of(context).permission_sales_title,
    salesProcess => S.of(context).permission_sales_process_title,
    salesDone => S.of(context).permission_sales_done_title,
    inventory => S.of(context).permission_inventory_title,
    channels => S.of(context).permission_channels_title,
    finance => S.of(context).permission_finance_title,
    financeOverview => S.of(context).permission_finance_overview_title,
    financePayments => S.of(context).permission_finance_payments_title,
    financeReceivables => S.of(context).permission_finance_receivables_title,
    financeMethods => S.of(context).permission_finance_methods_title,
    connections => S.of(context).permission_connections_title,
    pos => S.of(context).permission_pos_title
  };

  String description(BuildContext context) => switch (this) {
    business => S.of(context).permission_business_description,
    businessStatistics => S.of(context).permission_business_statistics_description,
    businessEmployees => S.of(context).permission_business_employees_description,
    businessBranches => S.of(context).permission_business_branches_description,
    businessClients => S.of(context).permission_business_clients_description,
    businessSettings => S.of(context).permission_business_settings_description,
    messages => S.of(context).permission_messages_description,
    deliveries => S.of(context).permission_deliveries_description,
    deliveriesSettings => S.of(context).permission_deliveries_settings_description,
    deliveriesAreas => S.of(context).permission_deliveries_areas_description,
    sales => S.of(context).permission_sales_description,
    salesProcess => S.of(context).permission_sales_process_description,
    salesDone => S.of(context).permission_sales_done_description,
    inventory => S.of(context).permission_inventory_description,
    channels => S.of(context).permission_channels_description,
    finance => S.of(context).permission_finance_description,
    financeOverview => S.of(context).permission_finance_overview_description,
    financePayments => S.of(context).permission_finance_payments_description,
    financeReceivables => S.of(context).permission_finance_receivables_description,
    financeMethods => S.of(context).permission_finance_methods_description,
    connections => S.of(context).permission_connections_description,
    pos => S.of(context).permission_pos_description
  };
}

/// One person's permissions: a search, then every [EmployeePermission]
/// grouped by its root area, each with its [PermissionAccess] switches.
///
/// The switches keep the catalog's rules so what is drawn is always a valid
/// grant: any action turns on the area's `view` (and its parents'), and
/// turning a `view` off clears the area's actions and everything under it.
///
/// **Local only for now**: there is no endpoint that reads or writes another
/// person's grants yet, so it starts empty and closing the panel drops it.
/// [initial] and [onChanged] are the seams for when it exists.
///
/// With [readOnly] nothing toggles: the viewer's own grants
/// ([EmployeePermission.own]), which nobody changes for themselves.
class EmployeePermissions extends StatefulWidget {
  const EmployeePermissions({super.key, this.initial = const {}, this.onChanged, this.readOnly = false});

  final Map<EmployeePermission, Set<PermissionAccess>> initial;
  final void Function(Map<EmployeePermission, Set<PermissionAccess>> grants)? onChanged;
  final bool readOnly;

  @override
  State<EmployeePermissions> createState() => _EmployeePermissionsState();
}

class _EmployeePermissionsState extends State<EmployeePermissions> {
  /// Filtered on each key: it only hides rows already drawn.
  final _search = InputController(key: "search");

  late final Map<EmployeePermission, Set<PermissionAccess>> _grants = {
    for (final entry in widget.initial.entries) entry.key: {...entry.value}
  };

  @override
  void initState() {
    super.initState();
    _search.textController.addListener(_searched);
  }

  @override
  void dispose() {
    _search.textController.removeListener(_searched);
    _search.form.dispose();
    super.dispose();
  }

  void _searched() {
    if (mounted) setState(() {});
  }

  bool _has(EmployeePermission permission, PermissionAccess access) =>
    _grants[permission]?.contains(access) ?? false;

  void _toggle(EmployeePermission permission, PermissionAccess access) {
    setState(() {
      if (_has(permission, access)) {
        _grants[permission]!.remove(access);
        if (access == PermissionAccess.view) _revoke(permission);
      } else {
        // Walks up: an action needs its area open, and an area its parent.
        EmployeePermission? node = permission;
        while (node != null) {
          (_grants[node] ??= {}).add(PermissionAccess.view);
          node = node.parent;
        }
        _grants[permission]!.add(access);
      }
    });

    widget.onChanged?.call(_grants);
  }

  /// Without its `view` nothing else in [permission] or below it holds.
  void _revoke(EmployeePermission permission) {
    _grants.remove(permission);
    for (final child in EmployeePermission.values) {
      if (child.parent == permission) _revoke(child);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final search = EmployeeSearch(query: _search.text, child: const SizedBox.shrink());

    // A group shows when its title matches (all its rows), otherwise only
    // the rows that match by their own title or description.
    final groups = <EmployeePermission, List<EmployeePermission>>{};
    for (final permission in EmployeePermission.values) {
      final root = permission.root;
      final shown = search.matches(root.title(context)) ||
        search.matches(permission.title(context)) ||
        search.matches(permission.description(context));

      if (shown) (groups[root] ??= []).add(permission);
    }

    // The search and the column heads stay put and only the list scrolls:
    // the side modal does not scroll its body, it lends its bar to the first
    // [ScrollableWidget].
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.readOnly) Padding(
          padding: EdgeInsets.only(bottom: AppSize.spaceS),
          child: TextSmall(S.of(context).permission_own_read_only, color: scheme.text.secondary)
        ),
        Input(
          controller: _search,
          placeholder: S.of(context).permission_search_hint,
          leftIcon: Icon(CI.search, size: EmployeeFactFrame.hintSize, color: scheme.text.secondary),
          buttonSpace: false,
          fillColor: scheme.surface,
          radius: EmployeeFactFrame.sheetRadius
        ),
        if (groups.isNotEmpty) const _Heads(),
        Expanded(child: ScrollableWidget(
          padding: EdgeInsets.only(bottom: AppSize.padding),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (groups.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: AppSize.spaceL),
                child: Center(child: TextSmall(S.of(context).permission_search_empty, color: scheme.text.secondary))
              ),
            for (final group in groups.entries) ...[
              if (group.key != groups.keys.first) SizedBox(height: AppSize.spaceS),
              _Group(
                root: group.key,
                permissions: group.value,
                granted: _has,
                toggle: widget.readOnly ? null : _toggle
              )
            ]
          ]
        ))
      ]
    );
  }
}

/// Sizes of the access matrix. Every row puts its cells in the same slots so
/// the four actions read as columns, named once by [_Heads].
abstract final class _Grid {
  static double get cell => AppSize.text * 2.3;
  static double get slot => AppSize.text * 3.6;
  static double get inset => AppSize.spaceXS;

  /// Room left of a sub-area for the thread that ties it to its area.
  static double get indent => inset + cell + AppSize.spaceS;
}

/// The action names, once, over the columns. With them the cells need no
/// label, so 22 rows do not repeat "View Create Edit Delete" 22 times.
class _Heads extends StatelessWidget {
  const _Heads();

  @override
  Widget build(BuildContext context) {
    final color = ThemeColor.of(context).text.secondary;

    return Padding(
      padding: EdgeInsets.only(top: AppSize.spaceS, bottom: AppSize.spaceXS, right: _Grid.inset * 2),
      child: Row(children: [
        const Spacer(),
        for (final access in PermissionAccess.values)
          SizedBox(
            width: _Grid.slot,
            child: TextSmall(access.label(context), textAlign: TextAlign.center, ellipsis: true, color: color)
          )
      ])
    );
  }
}

/// One sheet per root area: the area's own row, then its sub-areas threaded
/// under it, since a sub-area's `view` hangs on the area's.
class _Group extends StatelessWidget {
  const _Group({required this.root, required this.permissions, required this.granted, required this.toggle});

  final EmployeePermission root;
  final List<EmployeePermission> permissions;
  final bool Function(EmployeePermission, PermissionAccess) granted;

  /// `null` draws the cells without a press.
  final void Function(EmployeePermission, PermissionAccess)? toggle;

  @override
  Widget build(BuildContext context) {
    final family = EmployeePermission.values.where((p) => p.root == root).toList();
    final open = family.where((p) => granted(p, PermissionAccess.view)).length;

    return Surface(
      color: ThemeColor.of(context).surface,
      radius: EmployeeFactFrame.sheetRadius,
      padding: EdgeInsets.all(_Grid.inset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final permission in permissions)
            _Row(
              permission: permission,
              granted: granted,
              toggle: toggle,
              // The last sub-area ends the thread instead of running past it.
              last: permission == permissions.last,
              count: permission == root && family.length > 1
                ? S.of(context).permission_group_count(open, family.length)
                : null
            )
        ]
      )
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.permission, required this.granted, required this.toggle, required this.last, this.count});

  final EmployeePermission permission;
  final bool Function(EmployeePermission, PermissionAccess) granted;

  /// `null` draws the cells without a press.
  final void Function(EmployeePermission, PermissionAccess)? toggle;
  final bool last;

  /// How many of the group's areas are open; only on the area's own row.
  final String? count;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final open = granted(permission, PermissionAccess.view);
    final sub = permission.parent != null;
    final tone = open ? scheme.primary : scheme.text.secondary;

    // On a phone the text keeps the whole width and the cells go under it,
    // still flush right so they stay in the columns [_Heads] names.
    final phone = Responsive.of(context).isPhone;

    final text = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextMedium(permission.title(context), bold: !sub, ellipsis: true),
        TextSmall(permission.description(context), lines: 2, ellipsis: true, color: scheme.text.secondary),
        if (count != null) ...[
          SizedBox(height: AppSize.spaceXS * 0.4),
          TextSmall(count!, color: tone, multiplier: 0.9)
        ]
      ]
    );

    final cells = Padding(
      padding: EdgeInsets.only(right: _Grid.inset),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (final access in PermissionAccess.values)
          SizedBox(
            width: _Grid.slot,
            height: _Grid.cell + _Grid.inset * (phone ? 1 : 2),
            child: Center(child: _Cell(
              access: access,
              area: permission.title(context),
              available: permission.actions.contains(access),
              on: granted(permission, access),
              toggle: toggle == null ? null : () => toggle!(permission, access)
            ))
          )
      ])
    );

    return IntrinsicHeight(child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sub)
          SizedBox(width: _Grid.indent, child: _Thread(last: last, open: open))
        else
          Padding(
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
                child: Center(child: Icon(permission.icon, size: EmployeeFactFrame.iconSize, color: tone))
              )
            )
          ),
        Expanded(child: phone
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(padding: EdgeInsets.only(top: _Grid.inset), child: text),
                Align(alignment: Alignment.centerRight, child: cells)
              ]
            )
          : Padding(
              padding: EdgeInsets.symmetric(vertical: _Grid.inset),
              child: Align(alignment: Alignment.centerLeft, child: text)
            )
        ),
        if (!phone) Center(child: cells)
      ]
    ));
  }
}

/// The line down from the area's icon to each sub-area, lit at the branch
/// while the sub-area is open.
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

/// One action of a row. Granted is a solid mark in the button colors, the
/// strongest thing in the list; not granted is an outline; an action the
/// area does not have is a dot, so the columns stay aligned with no dead
/// button in them.
class _Cell extends StatelessWidget {
  const _Cell({required this.access, required this.area, required this.available, required this.on, required this.toggle});

  final PermissionAccess access;
  final String area;
  final bool available;
  final bool on;

  /// `null` for a read-only matrix: the same mark, no press.
  final VoidCallback? toggle;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final size = _Grid.cell;

    if (!available) {
      return Tooltip(
        message: S.of(context).permission_access_unavailable,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(child: Container(
            width: AppSize.text * 0.3,
            height: AppSize.text * 0.3,
            decoration: BoxDecoration(color: scheme.line, shape: BoxShape.circle)
          ))
        )
      );
    }

    final mark = SizedBox(
      width: size,
      height: size,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: on ? scheme.button.fill : Colors.transparent,
          border: Border.all(color: on ? scheme.button.fill : scheme.line, width: AppSize.text * 0.1),
          borderRadius: BorderRadius.circular(EmployeeFactFrame.radius)
        ),
        child: Center(child: Icon(
          on ? CI.check : access.icon,
          size: EmployeeFactFrame.hintSize,
          color: on ? scheme.button.text : scheme.text.secondary.withValues(alpha: 0.6)
        ))
      )
    );

    if (toggle == null) return mark;

    return FeedbackButton(
      action: toggle!,
      message: S.of(context).permission_access_cell(access.label(context), area),
      radius: EmployeeFactFrame.radius,
      width: size,
      height: size,
      color: Colors.transparent,
      feedbackColor: scheme.line,
      child: mark
    );
  }
}
