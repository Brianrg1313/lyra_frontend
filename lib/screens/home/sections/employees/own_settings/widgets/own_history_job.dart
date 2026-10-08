import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/account/employment_record_model.dart';
import 'package:app/services/business/business_employee_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/employees/employee_format.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

class OwnHistoryJob extends StatelessWidget {
  const OwnHistoryJob({super.key, required this.job});

  final EmploymentRecord job;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);

    final role = [job.jobTitle, job.department, job.branch ?? ""].where((part) => part.trim().isNotEmpty).join(" · ");
    final dates = switch (job.state) {
      EmployeeState.active => s.account_history_since(employeeDayLabel(context, job.startDate)),
      EmployeeState.ended => employeeRangeLabel(context, job.startDate, job.endedDate),
      _ => ""
    };
    final span = job.tenure == null || job.state == EmployeeState.invited ? "" : employeeSpanLabel(context, job.tenure!);
    final when = [if (job.startDate != null) dates, span].where((part) => part.isNotEmpty).join(" · ");

    final tag = switch (job.state) {
      EmployeeState.active => (label: s.account_history_current, color: scheme.chart.good),
      EmployeeState.invited => (label: s.employee_state_invited, color: scheme.primary),
      EmployeeState.ended => (label: s.employee_state_ended, color: scheme.text.secondary),
      EmployeeState.declined => (label: s.employee_state_declined, color: scheme.text.secondary),
      EmployeeState.cancelled => (label: s.employee_state_cancelled, color: scheme.text.secondary),
      null => null
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfilePicture(
          kind: ProfileKind.business,
          url: job.businessLogo?.thumbnail,
          size: AppSize.action * 0.9,
          label: job.businessName
        ),
        SizedBox(width: AppSize.spaceXS),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextMedium(job.businessName, bold: true, ellipsis: true),
            if (role.isNotEmpty) TextSmall(role, ellipsis: true),
            if (job.contract != null || when.isNotEmpty)
              TextSmall(
                [if (job.contract != null) employeeContractLabel(context, job.contract), when]
                  .where((part) => part.isNotEmpty)
                  .join(" · "),
                lines: 2,
                ellipsis: true,
                color: scheme.text.secondary
              )
          ]
        )),
        if (tag != null) ...[
          SizedBox(width: AppSize.gap),
          SettingsTag(label: tag.label, color: tag.color)
        ]
      ]
    );
  }
}
