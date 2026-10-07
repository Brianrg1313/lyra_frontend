import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_employee_detail_model.dart';
import 'package:app/services/business/business_employee_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/business/employees/employee_format.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

import './employee_quick_action.dart';

/// Who: picture, name, username, the headline they wrote, and the tags that
/// say where they stand.
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
    final headline = person?.headline ?? "";
    final state = detail?.state ?? employee.state;
    final presence = employeePresence(
      context,
      state: state,
      work: detail?.workStatus ?? employee.workStatus
    );
    final warning = employeeContractWarning(context, detail?.contractStatus);
    final job = [detail?.job.title ?? employee.jobTitle, detail?.job.department ?? employee.department]
      .where((part) => part.isNotEmpty)
      .join(" · ");
    // Work first: it is the channel the company is meant to use.
    final phone = [detail?.job.workPhone ?? "", person?.phone ?? ""].firstWhere((v) => v.isNotEmpty, orElse: () => "");
    final email = [detail?.job.workEmail ?? "", person?.email ?? "", employee.email]
      .firstWhere((v) => v.isNotEmpty, orElse: () => "");
    final radius = AppSize.cornerInset(AppSize.gap);

    // A wash of the presence color from the top: where the person stands is
    // read before their name, as the status dot does in the list.
    return Container(
      padding: EdgeInsets.all(AppSize.padding * 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(radius),
          topRight: Radius.circular(radius)
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [scheme.background.withValues(alpha: 0.16), scheme.background]
        )
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ProfilePicture(
                kind: ProfileKind.employee,
                // A thumbnail covering twice the side: sharp on a dense screen without
                // downloading the original.
                url: (person?.picture ?? employee.picture)?.sized((AppSize.action * 2.6 * 2).round()),
                size: AppSize.action * 2.6,
                label: name
              ),
              SizedBox(width: AppSize.spaceS),
              Flexible(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextInter(
                    name,
                    bold: true,
                    multiplier: 1.8,
                    ellipsis: true,
                    selectable: true
                  ),
                  if (username.isNotEmpty) ...[
                    TextSmall("@$username", ellipsis: true, color: scheme.text.secondary)
                  ],
                  if (phone.isNotEmpty || email.isNotEmpty) ...[
                    SizedBox(height: AppSize.gap),
                    Row(children: [
                      if (phone.isNotEmpty) EmployeeQuickAction(
                        icon: CI.phone,
                        label: S.of(context).employee_field_phone,
                        value: phone
                      ),
                      if (phone.isNotEmpty && email.isNotEmpty) SizedBox(width: AppSize.gap * 0.75),
                      if (email.isNotEmpty) EmployeeQuickAction(
                        icon: CI.mail,
                        label: S.of(context).employee_field_email,
                        value: email
                      )
                    ])
                  ],
                  SizedBox(height: AppSize.gap),
                  Wrap(
                    spacing: AppSize.gap * 0.5,
                    runSpacing: AppSize.gap * 0.5,
                    children: [
                      SettingsTag(icon: presence.icon, label: presence.label, color: presence.color),
                      if (employee.me) SettingsTag(
                        icon: CI.user,
                        label: S.of(context).employees_you,
                        color: scheme.primary
                      ),
                      if (warning != null) SettingsTag(
                        icon: CI.info,
                        label: warning.label,
                        color: warning.color
                      )
                    ]
                  ),
                  if (job.isNotEmpty) ...[
                    SizedBox(height: AppSize.gap * 0.75),
                    TextSmall(job, ellipsis: true, color: scheme.text.secondary)
                  ]
                ]
              ))
            ]),
          if (headline.isNotEmpty) ...[
            SizedBox(height: AppSize.spaceS),
            TextSmall(headline, lines: 3, ellipsis: true)
          ]
        ]
      )
    );
  }
}
