import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_employee_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/employees/employee_format.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// One person: picture, name and job, and — when the
/// panel is wide enough — contract and start date in their own columns. The
/// status tag closes the row. The one shown in the detail panel is filled.
class EmployeeRow extends StatelessWidget {
  const EmployeeRow({
    super.key,
    required this.employee,
    required this.onTap,
    this.wide = true,
    this.selected = false
  });

  final BusinessEmployeeModel employee;
  final bool wide;
  final bool selected;
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

    final date = employee.state == EmployeeState.ended
      ? employeeRangeLabel(context, employee.startDate, employee.endedDate)
      : employeeDayLabel(context, employee.startDate);

    return FocusableWidget(
      action: onTap,
      message: employee.fullName,
      child: Container(
        // The columns' heading is inset as much, so they stay aligned.
        padding: EdgeInsets.symmetric(vertical: AppSize.spaceXS, horizontal: AppSize.spaceXS),
        decoration: BoxDecoration(
          color: selected ? scheme.surfaceOver : null,
          borderRadius: BorderRadius.circular(AppSize.cornerInset(AppSize.gap))
        ),
        child: Row(children: [
          ProfilePicture(
            kind: ProfileKind.employee,
            // A thumbnail covering twice the side: sharp on a dense screen without
            // downloading the original for a row.
            url: (employee.picture)?.sized((AppSize.action * 2).round()),
            size: AppSize.action,
            label: employee.fullName
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
      )
    );
  }
}
