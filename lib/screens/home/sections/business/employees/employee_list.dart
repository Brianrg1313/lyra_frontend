import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_employee_model.dart';
import 'package:app/services/business/business_employees_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';
import 'package:app/screens/modals/business/invite_employee/_invite_employee.dart';

import './employee_avatar.dart';
import './employee_format.dart';

/// The left panel: everyone who works here, with where each one stands, and
/// below them who used to.
///
/// The viewer's own card is always the first row (the service keeps it
/// there), marked as theirs. Touching a row opens it on the right.
class EmployeeList extends StatelessWidget {
  const EmployeeList({super.key});

  /// Below this width the contract and start-date columns are dropped: the
  /// name and the status are what a row cannot lose.
  static const double _wide = 560;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<BusinessEmployeesService>();
    final invited = service.current
      .where((employee) => employee.state == EmployeeState.invited)
      .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Heading(
          active: service.total,
          invited: invited,
          onInvite: () => showInviteEmployee(context, employees: service)
        ),
        SizedBox(height: AppSize.spaceS),
        Expanded(child: LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth >= _wide;

          /// One group of rows with a line between each pair — never above
          /// the first or below the last, so a group title sits flush.
          List<Widget> group(List<BusinessEmployeeModel> employees) => [
            for (var i = 0; i < employees.length; i++) ...[
              if (i > 0) Separator.horizontal(
                margin: EdgeInsets.symmetric(vertical: AppSize.gap * 0.5)
              ),
              EmployeeTile(
                employee: employees[i],
                wide: wide,
                selected: employees[i].key == service.selectedKey,
                onTap: () => service.select(employees[i].key)
              )
            ]
          ];

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              if (wide) const _Columns(),
              ...group(service.current),
              if (service.former.isNotEmpty) ...[
                _GroupTitle(
                  title: S.of(context).employees_former_title,
                  count: service.former.length
                ),
                ...group(service.former)
              ]
            ]
          );
        }))
      ]
    );
  }
}

/// What the panel is, how many it holds, and the button that invites one more.
class _Heading extends StatelessWidget {
  const _Heading({
    required this.active,
    required this.invited,
    required this.onInvite
  });

  final int active;
  final int invited;
  final void Function() onInvite;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final text = S.of(context);

    return Row(children: [
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextMedium(text.employees_title, bold: true, ellipsis: true),
          SizedBox(height: AppSize.gap * 0.5),
          TextSmall(
            [
              text.employees_active_count(active),
              if (invited > 0) text.employees_invited_count(invited)
            ].join(" · "),
            ellipsis: true,
            color: scheme.text.secondary
          )
        ]
      )),
      SizedBox(width: AppSize.spaceS),
      Button(
        width: null,
        title: text.employees_invite,
        leftIcon: Icon(CI.plus, color: scheme.button.text),
        action: onInvite
      )
    ]);
  }
}

/// Names the columns of the wide rows, once, above them.
class _Columns extends StatelessWidget {
  const _Columns();

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final text = S.of(context);

    Widget label(String value) => TextSmall(
      value,
      multiplier: 0.9,
      ellipsis: true,
      color: scheme.text.secondary
    );

    return Padding(
      padding: EdgeInsets.only(
        left: AppSize.spaceXS,
        right: AppSize.spaceXS,
        bottom: AppSize.gap
      ),
      child: Row(children: [
        SizedBox(width: AppSize.action + AppSize.spaceXS),
        Expanded(flex: 4, child: label(text.employees_column_person)),
        Expanded(flex: 2, child: label(text.employees_column_contract)),
        Expanded(flex: 2, child: label(text.employees_column_since)),
        SizedBox(width: EmployeeTile.statusWidth, child: label(text.employees_column_status))
      ])
    );
  }
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      top: AppSize.spaceS,
      bottom: AppSize.gap,
      left: AppSize.spaceXS
    ),
    child: TextSmall(
      "$title · $count",
      ellipsis: true,
      color: ThemeColor.of(context).text.secondary
    )
  );
}

/// One person: picture with their status dot, name and job, and — when the
/// panel is wide enough — contract and start date in their own columns. The
/// status tag closes the row.
class EmployeeTile extends StatelessWidget {
  const EmployeeTile({
    super.key,
    required this.employee,
    required this.selected,
    required this.onTap,
    this.wide = true
  });

  final BusinessEmployeeModel employee;
  final bool selected;
  final bool wide;
  final void Function() onTap;

  /// Room for the longest status tag ("Paternity leave") without cutting it.
  static double get statusWidth => AppSize.action * 3.2;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final text = S.of(context);
    final presence = employeePresence(
      context,
      state: employee.state,
      work: employee.workStatus
    );

    final job = [employee.jobTitle, employee.department]
      .where((part) => part.isNotEmpty)
      .join(" · ");

    final background = selected ? scheme.surfaceOver : scheme.surface;
    final date = employee.state == EmployeeState.ended
      ? employeeRangeLabel(context, employee.startDate, employee.endedDate)
      : employeeDayLabel(context, employee.startDate);

    return FocusableWidget(
      action: onTap,
      message: employee.fullName,
      child: Row(children: [
        EmployeeAvatar(
          name: employee.fullName,
          picture: employee.picture,
          size: AppSize.action,
          status: presence.color,
          ring: background
        ),
        SizedBox(width: AppSize.spaceXS),
        Expanded(flex: 4, child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Flexible(child: TextMedium(employee.fullName, bold: true, ellipsis: true)),
              if (employee.me) ...[
                SizedBox(width: AppSize.gap),
                TextSmall(text.employees_you, color: scheme.primary)
              ]
            ]),
            SizedBox(height: AppSize.gap * 0.5),
            TextSmall(
              job.isEmpty ? "@${employee.username}" : job,
              ellipsis: true,
              color: scheme.text.secondary
            )
          ]
        )),
        if (wide) ...[
          Expanded(flex: 2, child: TextSmall(
            employeeContractLabel(context, employee.contract),
            ellipsis: true,
            color: scheme.text.secondary
          )),
          Expanded(flex: 2, child: TextSmall(
            date,
            ellipsis: true,
            color: scheme.text.secondary
          ))
        ],
        SizedBox(
          width: statusWidth,
          child: Align(
            alignment: Alignment.centerLeft,
            child: SettingsTag(
              icon: presence.icon,
              label: presence.label,
              color: presence.color
            )
          )
        )
      ])
    );
  }
}
