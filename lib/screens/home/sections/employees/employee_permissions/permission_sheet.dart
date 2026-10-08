import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart';

// SERVICES
import 'package:app/services/permissions/member_permissions_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/employees/employee_facts/widgets/employee_fact_frame.dart';

import './permission_cell.dart';
import './permission_grid.dart';
import './permission_section.dart';
import './permission_thread.dart';

/// One section: its own row (icon, title, description, how many actions are on, the switch that
/// lets the person in), then its actions threaded under it, since an action holds only with it.
class PermissionSheet extends StatelessWidget {
  const PermissionSheet({super.key, required this.section, required this.actions, required this.service});

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
        padding: EdgeInsets.fromLTRB(PermissionGrid.inset, PermissionGrid.inset, AppSize.spaceS, PermissionGrid.inset),
        child: Align(
          alignment: Alignment.topCenter,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: PermissionGrid.cell,
            height: PermissionGrid.cell,
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
      cell: PermissionCell(
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
      padding: EdgeInsets.all(PermissionGrid.inset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          head,
          for (final action in actions)
            _Row(
              leading: SizedBox(
                width: PermissionGrid.indent,
                child: PermissionThread(last: action == actions.last, open: open && service.flag(key, action))
              ),
              text: TextSmall(
                section.action(context, action),
                lines: 2,
                ellipsis: true,
                // An action stored under a closed section grants nothing (`can` needs both).
                color: open ? scheme.text.primary : scheme.text.secondary
              ),
              cell: PermissionCell(
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
        padding: EdgeInsets.symmetric(vertical: PermissionGrid.inset),
        child: Align(alignment: Alignment.centerLeft, child: text)
      )),
      Padding(
        padding: EdgeInsets.only(left: AppSize.spaceS, right: PermissionGrid.inset),
        child: Center(child: cell)
      )
    ]
  ));
}
