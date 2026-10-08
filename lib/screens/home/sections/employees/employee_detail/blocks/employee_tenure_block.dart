import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_employee_detail_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/employees/employee_facts/employee_search.dart';
import 'package:app/screens/home/sections/employees/employee_format.dart';

/// The three facts read right after who the person is — how long in this job,
/// in the company, and on what contract — as three small tiles, not a titled
/// section: they answer "who is this to us" and the sections below are what
/// is looked up afterwards. A rehire counts every stint in the company, so the
/// first two can differ.
class EmployeeTenureBlock extends StatelessWidget {
  const EmployeeTenureBlock({super.key, required this.detail});

  final BusinessEmployeeDetail detail;

  @override
  Widget build(BuildContext context) {
    // Not tiles of a section: a search has nothing to find in them.
    if (EmployeeSearch.of(context).isNotEmpty) return const SizedBox.shrink();

    final text = S.of(context);
    final since = employeeDayLabel(context, detail.companySince);
    final contract = employeeContractLabel(context, detail.job.contract);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.spaceS),
      child: IntrinsicHeight(child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _TenureFact(
            value: employeeSpanLabel(context, detail.tenure),
            label: text.employee_tenure_job
          )),
          SizedBox(width: AppSize.gap),
          Expanded(child: _TenureFact(
            value: text.employee_days(detail.companyDays),
            label: since.isEmpty ? text.employee_tenure_company : text.employee_tenure_company_since(since)
          )),
          SizedBox(width: AppSize.gap),
          Expanded(child: _TenureFact(
            value: contract.isEmpty ? text.employee_value_none : contract,
            label: text.employee_field_contract,
            muted: contract.isEmpty
          ))
        ]
      ))
    );
  }
}

class _TenureFact extends StatelessWidget {
  const _TenureFact({required this.value, required this.label, this.muted = false});

  final String value;
  final String label;

  /// The value is a missing one, said in grey like every empty value.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Surface(
      color: scheme.surface,
      padding: EdgeInsets.all(AppSize.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextMedium(value, bold: true, lines: 2, ellipsis: true, color: muted ? scheme.text.secondary : null),
          SizedBox(height: AppSize.gap * 0.5),
          TextSmall(label, lines: 2, ellipsis: true, color: scheme.text.secondary)
        ]
      )
    );
  }
}
