import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_employee_detail_model.dart';
import 'package:app/services/business/business_employee_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/employees/employee_format.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

import './employee_quick_action.dart';

/// Who the detail panel is about, in its bar: picture, name, the tags that say
/// where they stand, username and job, and the ways to reach them.
///
/// It stays while the pages under it swap, like the open chat's header: going
/// into a part of the card never loses whose card it is.
class EmployeeDetailHeader extends StatelessWidget {
  const EmployeeDetailHeader({super.key, required this.employee, this.detail});

  final BusinessEmployeeModel employee;
  final BusinessEmployeeDetail? detail;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final person = detail?.person;
    // An invited email with no account yet has no names and a placeholder
    // username: the row's email names it, and the username is not shown.
    final unclaimed = employee.email.isNotEmpty;
    final name = unclaimed ? employee.fullName : person?.fullName ?? employee.fullName;
    final username = unclaimed ? "" : person?.username ?? employee.username;
    final state = detail?.state ?? employee.state;
    final presence = employeePresence(
      context,
      state: state,
      work: detail?.workStatus ?? employee.workStatus
    );
    final warning = employeeContractWarning(context, detail?.contractStatus);
    final job = [detail?.job.title ?? employee.jobTitle, detail?.job.department ?? employee.department]
      .where((part) => part.isNotEmpty);
    // Work first: it is the channel the company is meant to use.
    final phone = [detail?.job.workPhone ?? "", person?.phone ?? ""].firstWhere((v) => v.isNotEmpty, orElse: () => "");
    final email = [detail?.job.workEmail ?? "", person?.email ?? "", employee.email]
      .firstWhere((v) => v.isNotEmpty, orElse: () => "");

    return Row(children: [
      ProfilePicture(
        kind: ProfileKind.employee,
        // A thumbnail covering twice the side: sharp on a dense screen without
        // downloading the original.
        url: (person?.picture ?? employee.picture)?.sized((AppSize.action * 2).round()),
        size: AppSize.action,
        label: name
      ),
      SizedBox(width: AppSize.spaceXS),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Flexible(child: TextMedium(name, bold: true, ellipsis: true, selectable: true)),
            SizedBox(width: AppSize.gap * 1.5),
            SettingsTag(icon: presence.icon, label: presence.label, color: presence.color),
            if (employee.me) ...[
              SizedBox(width: AppSize.gap),
              SettingsTag(icon: CI.user, label: S.of(context).employees_you, color: scheme.primary)
            ],
            if (warning != null) ...[
              SizedBox(width: AppSize.gap),
              SettingsTag(icon: CI.info, label: warning.label, color: warning.color)
            ]
          ]),
          SizedBox(height: AppSize.gap * 0.5),
          TextSmall(
            [if (username.isNotEmpty) "@$username", ...job].join(" · "),
            ellipsis: true,
            color: scheme.text.secondary
          )
        ]
      )),
      if (phone.isNotEmpty) ...[
        SizedBox(width: AppSize.spaceXS),
        EmployeeQuickAction(icon: CI.phone, label: S.of(context).employee_field_phone, value: phone)
      ],
      if (email.isNotEmpty) ...[
        SizedBox(width: AppSize.gap),
        EmployeeQuickAction(icon: CI.mail, label: S.of(context).employee_field_email, value: email)
      ]
    ]);
  }
}
