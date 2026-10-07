import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_branches_service.dart';
import 'package:app/services/business/business_employee_detail_model.dart';
import 'package:app/services/business/business_employee_model.dart';
import 'package:app/services/business/business_employees_service.dart';
import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/services/catalog/currency_catalog_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/business/employees/employee_facts/_employee_facts.dart';
import 'package:app/screens/home/sections/business/employees/employee_facts/employee_date_fact.dart';
import 'package:app/screens/home/sections/business/employees/employee_facts/employee_fact.dart';
import 'package:app/screens/home/sections/business/employees/employee_facts/employee_section.dart';
import 'package:app/screens/home/sections/business/employees/employee_facts/employee_select_fact.dart';
import 'package:app/screens/home/sections/business/employees/employee_facts/employee_text_fact.dart';
import 'package:app/screens/home/sections/business/employees/employee_format.dart';

import './employee_block_values.dart';
import './employee_editor.dart';

class EmployeeJobBlock extends StatelessWidget {
  const EmployeeJobBlock({super.key, required this.detail, required this.edit});

  final BusinessEmployeeDetail detail;
  final EmployeeEditor edit;

  @override
  Widget build(BuildContext context) {
    final text = S.of(context);
    final job = detail.job;
    final manager = job.manager;
    final salary = job.salary;
    final none = text.employee_value_none;
    final editable = edit.job;

    final people = context.watch<BusinessEmployeesService>();
    final everyone = [...people.current, ...people.former];
    final currency = CurrencyCatalogService().resolve(job.salaryCurrency);

    final pay = salary == null
      ? ""
      : employeeJoined([
          currency.label("$salary") ?? "$salary",
          employeePeriodLabel(context, job.payPeriod)
        ], " / ");

    return EmployeeSection(
      title: text.employee_job_title,
      children: [EmployeeFacts(facts: [
        EmployeeSelectFact(
          icon: CI.employee_badge,
          label: text.employee_field_job_title,
          value: job.title,
          selected: job.title,
          empty: none,
          enabled: editable,
          // The backend never takes it erased.
          clearable: false,
          creatable: true,
          options: employeeOptionsInUse(everyone.map((employee) => employee.jobTitle)),
          onSave: edit.save("JOB_TITLE")
        ),
        EmployeeSelectFact(
          icon: CI.tems,
          label: text.employee_field_department,
          value: job.department,
          selected: job.department,
          empty: none,
          enabled: editable,
          creatable: true,
          options: employeeOptionsInUse(everyone.map((employee) => employee.department)),
          onSave: edit.save("DEPARTMENT")
        ),
        EmployeeSelectFact(
          icon: CI.shop,
          label: text.employee_field_branch,
          value: job.branchName,
          selected: job.branchId,
          empty: none,
          // One site and no branches list where branches don't exist (a master).
          enabled: editable && CapabilityService().shows("business.branches"),
          loadOptions: () async {
            final branches = context.read<BusinessBranchesService>();

            // Once per page: the branches tab may have read them already.
            await branches.load();

            return [for (final branch in branches.branches) SelectOption(value: branch.id, placeholder: branch.name)];
          },
          onSave: edit.save("BRANCH_ID")
        ),
        EmployeeSelectFact(
          icon: CI.user_circle,
          label: text.employee_field_manager,
          value: manager == null ? "" : employeeJoined([manager.fullName, manager.jobTitle], " · "),
          selected: manager?.id ?? "",
          empty: none,
          enabled: editable,
          // The backend takes another invited or active job of the company:
          // the current list, without this one.
          options: [
            for (final employee in people.current)
              if (employee.id != null && employee.id != detail.id) SelectOption(
                value: employee.id!,
                placeholder: employee.fullName,
                subtitle: employee.jobTitle.isEmpty ? null : employee.jobTitle
              )
          ],
          onSave: edit.save("MANAGER_ID")
        ),
        EmployeeSelectFact(
          icon: CI.documents,
          label: text.employee_field_contract,
          value: employeeContractLabel(context, job.contract),
          selected: job.contract?.value ?? "",
          empty: none,
          enabled: editable,
          options: [
            for (final contract in EmployeeContract.values)
              SelectOption(value: contract.value, placeholder: employeeContractLabel(context, contract))
          ],
          onSave: edit.save("CONTRACT")
        ),
        EmployeeSelectFact(
          icon: CI.calendar,
          label: text.employee_field_workday,
          value: employeeWorkdayLabel(context, job.workday),
          selected: job.workday?.value ?? "",
          empty: none,
          enabled: editable,
          options: [
            for (final workday in EmployeeWorkday.values)
              SelectOption(value: workday.value, placeholder: employeeWorkdayLabel(context, workday))
          ],
          onSave: edit.save("WORKDAY")
        ),
        EmployeeDateFact(
          icon: CI.calendar,
          label: text.employee_field_start,
          value: employeeDayLabel(context, job.startDate),
          day: job.startDate,
          empty: none,
          enabled: editable,
          validate: (day) => job.endDate != null && day.isAfter(job.endDate!) ? text.employee_edit_start_after_end : null,
          onSave: edit.save("START_DATE")
        ),
        if (editable || job.endDate != null) EmployeeDateFact(
          icon: CI.calendar,
          label: text.employee_field_contract_end,
          value: employeeDayLabel(context, job.endDate),
          day: job.endDate,
          empty: none,
          enabled: editable,
          validate: (day) => job.startDate != null && day.isBefore(job.startDate!) ? text.employee_edit_end_before_start : null,
          onSave: edit.save("END_DATE")
        ),
        if (!editable) EmployeeFact(
          icon: CI.wallet,
          label: text.employee_field_salary,
          value: pay,
          empty: text.employee_value_not_filed
        )
        else ...[
          EmployeeTextFact(
            icon: CI.wallet,
            label: text.employee_field_salary,
            value: salary == null ? "" : currency.label("$salary") ?? "$salary",
            initial: salary == null ? "" : "$salary",
            empty: text.employee_value_not_filed,
            formatters: [FilteringTextInputFormatter.allow(RegExp("[0-9.,]"))],
            validate: (value) => employeeCheckAmount(context, value),
            onSave: edit.save("SALARY", employeeAmount)
          ),
          EmployeeSelectFact(
            icon: CI.wallet,
            label: text.employee_field_pay_period,
            value: employeePeriodLabel(context, job.payPeriod),
            selected: job.payPeriod?.value ?? "",
            empty: none,
            options: [
              for (final period in EmployeePayPeriod.values)
                SelectOption(value: period.value, placeholder: employeePeriodLabel(context, period))
            ],
            onSave: edit.save("PAY_PERIOD")
          ),
          EmployeeSelectFact(
            icon: CI.wallet,
            label: text.employee_field_currency,
            value: job.salaryCurrency,
            selected: job.salaryCurrency,
            empty: none,
            options: [
              for (final option in CurrencyCatalogService().fiat)
                SelectOption(value: option.code, placeholder: option.name, chosen: option.code, subtitle: option.code)
            ],
            onSave: edit.save("SALARY_CURRENCY")
          )
        ],
        if (editable || job.code.isNotEmpty) EmployeeTextFact(
          icon: CI.key,
          label: text.employee_field_code,
          value: job.code,
          empty: none,
          copy: true,
          enabled: editable,
          onSave: edit.save("EMPLOYEE_CODE")
        )
      ])]
    );
  }
}
