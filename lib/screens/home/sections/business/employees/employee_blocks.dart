import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter, LengthLimitingTextInputFormatter, TextInputFormatter;
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_branches_service.dart';
import 'package:app/services/business/business_employee_detail_model.dart';
import 'package:app/services/business/business_employee_model.dart';
import 'package:app/services/business/business_employees_service.dart';
import 'package:app/services/business/business_places_model.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/services/catalog/country_catalog_service.dart';
import 'package:app/services/catalog/currency_catalog_service.dart';
import 'package:app/services/permissions/permissions_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/business/settings/country_flag.dart';

import './employee_card.dart';
import './employee_edit.dart';
import './employee_edit_date.dart';
import './employee_edit_phone.dart';
import './employee_format.dart';

/// The blocks of the detail panel, in the order they are looked for: who the
/// person is, how long and on what contract, whether they are here today, how
/// to reach them, the job, what absences are coming, and the record of how it
/// started and ended.
///
/// Blocks that have nothing to say are left out rather than drawn empty —
/// except the job and the person, which say what is missing in words, and
/// the ones that can be filled from here, which are the only place to do it.
List<Widget> employeeBlocks(BuildContext context, BusinessEmployeeDetail detail) {
  final edit = EmployeeEditor(context, detail);

  return [
    _Person(detail: detail, edit: edit),
    if (detail.state != EmployeeState.invited) _Tenure(detail: detail),
    if (detail.leave != null) _LeaveNow(leave: detail.leave!),
    if (detail.ending != null) _Ending(ending: detail.ending!),
    if (edit.job || detail.job.workEmail.isNotEmpty || detail.job.workPhone.isNotEmpty)
      _WorkContact(job: detail.job, edit: edit),
    _Job(detail: detail, edit: edit),
    if (detail.fullProfile && (edit.person || _hasEmergency(detail.person)))
      _Emergency(person: detail.person, edit: edit),
    if (detail.upcomingLeaves.isNotEmpty) _Upcoming(leaves: detail.upcomingLeaves),
    if (detail.invitedAt != null) _Record(detail: detail),
    if (edit.job || detail.job.notes.isNotEmpty) _Notes(notes: detail.job.notes, edit: edit)
  ];
}

/// What of one detail can be changed from the panel, and how a change travels
/// (`PUT /business/employees/`, see [BusinessEmployeesService.edit]).
class EmployeeEditor {
  EmployeeEditor(this.context, this.detail);

  final BuildContext context;
  final BusinessEmployeeDetail detail;

  /// The job: with `employees.manage`, while it is invited or active — the
  /// backend refuses a closed one.
  bool get job =>
    // The app's tree has no edit action of its own: inviting is the area that
    // maps to the backend's `employees.manage`, the grant the edit needs.
    PermissionsService().can("business.employees.invite") &&
    (detail.state == EmployeeState.invited || detail.state == EmployeeState.active);

  /// The personal data: while the job is active. It is the person's own
  /// profile, so a change reaches their account and every other employer.
  bool get person => job && detail.fullProfile && detail.profileEditable;

  /// Saves one backend key with what a tile sent, reshaped by [shape] (a
  /// salary typed with a comma travels with a dot).
  Future<bool> Function(String value) save(String key, [String Function(String value)? shape]) =>
    (value) => context.read<BusinessEmployeesService>().edit(
      context,
      detail.id,
      {key: shape == null || value.isEmpty ? value : shape(value)}
    );

  /// Saves a place picked from the address search: the street line and the
  /// parts it came with, in one change. A part the place did not answer is
  /// left as it was rather than erased.
  Future<bool> place(PlaceModel place) => context.read<BusinessEmployeesService>().edit(
    context,
    detail.id,
    {
      "ADDRESS": place.address,
      if (place.city.isNotEmpty) "CITY": place.city,
      if (place.region.isNotEmpty) "REGION": place.region,
      if (place.postalCode.isNotEmpty) "POSTAL_CODE": place.postalCode,
      if (place.country.isNotEmpty) "COUNTRY": place.country
    }
  );
}

/// The company's country: the phone code offered for a phone that has none.
String _companyCountry(BuildContext context) => context.read<BusinessService>().profile?.country ?? "";

/// Digits only, at most [length] of them.
List<TextInputFormatter> _digits(int length) => [
  FilteringTextInputFormatter.digitsOnly,
  LengthLimitingTextInputFormatter(length)
];

bool _hasEmergency(EmployeePerson person) =>
  person.emergencyName.isNotEmpty || person.emergencyPhone.isNotEmpty;

String _joined(List<String> parts, String separator) =>
  parts.where((part) => part.isNotEmpty).join(separator);

String _amount(String text) => text.replaceAll(",", ".");

String? _checkAmount(BuildContext context, String text) {
  final amount = double.tryParse(_amount(text));

  return amount != null && amount >= 0 ? null : S.of(context).employee_edit_invalid_amount;
}

/// The names in use across the company for one job field, for the list a
/// title or a department is picked from.
List<SelectOption> _inUse(Iterable<String> values) {
  final names = {for (final value in values) if (value.trim().isNotEmpty) value.trim()}.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  return [for (final name in names) SelectOption(value: name, placeholder: name)];
}

List<SelectOption> _countries(BuildContext context) => [
  // Watched: the catalog may answer after the panel is drawn.
  for (final country in context.watch<CountryCatalogService>().countries)
    SelectOption(
      value: country.code,
      placeholder: country.name,
      leading: CountryFlag(country: country)
    )
];

/// The three facts read right after who the person is — how long in this job,
/// in the company, and on what contract — as three small tiles, not a titled
/// section: they answer "who is this to us" and the sections below are what
/// is looked up afterwards. A rehire counts every stint in the company, so the
/// first two can differ.
class _Tenure extends StatelessWidget {
  const _Tenure({required this.detail});

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
          Expanded(child: _Fact(
            value: employeeSpanLabel(context, detail.tenure),
            label: text.employee_tenure_job
          )),
          SizedBox(width: AppSize.gap),
          Expanded(child: _Fact(
            value: text.employee_days(detail.companyDays),
            label: since.isEmpty ? text.employee_tenure_company : text.employee_tenure_company_since(since)
          )),
          SizedBox(width: AppSize.gap),
          Expanded(child: _Fact(
            value: contract.isEmpty ? text.employee_value_none : contract,
            label: text.employee_field_contract,
            muted: contract.isEmpty
          ))
        ]
      ))
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.value, required this.label, this.muted = false});

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

/// The absence running today, first: it is what changes what can be asked of
/// them.
class _LeaveNow extends StatelessWidget {
  const _LeaveNow({required this.leave});

  final EmployeeLeave leave;

  @override
  Widget build(BuildContext context) {
    final text = S.of(context);

    return EmployeeSection(
      title: text.employee_leave_now_title,
      children: [
        EmployeeEvent(
          date: leave.startDate,
          color: ThemeColor.of(context).chart.warning,
          title: employeeLeaveLabel(context, leave.type),
          subtitle: _joined([
            employeeRangeLabel(context, leave.startDate, leave.endDate),
            text.employee_leave_days(leave.days)
          ], " · ")
        ),
        if (leave.note.isNotEmpty) EmployeeNote(title: text.employee_field_note, text: leave.note, lines: 4)
      ]
    );
  }
}

class _WorkContact extends StatelessWidget {
  const _WorkContact({required this.job, required this.edit});

  final EmployeeJob job;
  final EmployeeEditor edit;

  @override
  Widget build(BuildContext context) {
    final text = S.of(context);
    final none = text.employee_value_none;

    return EmployeeSection(
      title: text.employee_work_contact_title,
      children: [EmployeeFacts(facts: [
        if (edit.job || job.workPhone.isNotEmpty) EmployeePhoneFact(
          icon: CI.phone,
          label: text.employee_field_phone,
          value: job.workPhone,
          country: _companyCountry(context),
          empty: none,
          enabled: edit.job,
          onSave: edit.save("WORK_PHONE")
        ),
        if (edit.job || job.workEmail.isNotEmpty) EmployeeTextFact(
          icon: CI.mail,
          label: text.employee_field_email,
          value: job.workEmail,
          empty: none,
          copy: true,
          enabled: edit.job,
          onSave: edit.save("WORK_EMAIL")
        )
      ])]
    );
  }
}

class _Job extends StatelessWidget {
  const _Job({required this.detail, required this.edit});

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
      : _joined([
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
          options: _inUse(everyone.map((employee) => employee.jobTitle)),
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
          options: _inUse(everyone.map((employee) => employee.department)),
          onSave: edit.save("DEPARTMENT")
        ),
        EmployeeSelectFact(
          icon: CI.shop,
          label: text.employee_field_branch,
          value: job.branchName,
          selected: job.branchId,
          empty: none,
          enabled: editable,
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
          value: manager == null ? "" : _joined([manager.fullName, manager.jobTitle], " · "),
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
          onSave: edit.save("START_DATE")
        ),
        if (editable || job.endDate != null) EmployeeDateFact(
          icon: CI.calendar,
          label: text.employee_field_contract_end,
          value: employeeDayLabel(context, job.endDate),
          day: job.endDate,
          empty: none,
          enabled: editable,
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
            validate: (value) => _checkAmount(context, value),
            onSave: edit.save("SALARY", _amount)
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

/// The person's own profile, first in the panel: who they are comes before
/// what they do here. Whole only while the job is active; otherwise the
/// section says why it is not there instead of showing empty tiles that would
/// read as unknown.
class _Person extends StatelessWidget {
  const _Person({required this.detail, required this.edit});

  final BusinessEmployeeDetail detail;
  final EmployeeEditor edit;

  @override
  Widget build(BuildContext context) {
    final text = S.of(context);

    if (!detail.fullProfile) {
      return EmployeeSection(
        title: text.employee_person_title,
        children: [EmployeeNote(text: text.employee_person_hidden, lines: 3)]
      );
    }

    final person = detail.person;
    final countries = CountryCatalogService();
    final none = text.employee_value_none;
    final editable = edit.person;
    final nations = editable ? _countries(context) : const <SelectOption>[];

    return EmployeeSection(
      title: text.employee_person_title,
      subtitle: detail.profileEditable ? text.employee_person_editable : text.employee_person_owned,
      children: [
        EmployeeFacts(facts: [
          EmployeeTextFact(
            icon: CI.user,
            label: text.employee_field_first_name,
            value: person.name,
            empty: none,
            enabled: editable,
            required: true,
            onSave: edit.save("FIRST_NAME")
          ),
          EmployeeTextFact(
            icon: CI.user,
            label: text.employee_field_last_name,
            value: person.lastName,
            empty: none,
            enabled: editable,
            required: true,
            onSave: edit.save("LAST_NAME")
          ),
          EmployeePhoneFact(
            icon: CI.phone,
            label: text.employee_field_phone,
            value: person.phone,
            country: person.country.isEmpty ? _companyCountry(context) : person.country,
            empty: none,
            enabled: editable,
            onSave: edit.save("PHONE")
          ),
          // The account's sign-in email: not a profile field, so never
          // written from here.
          EmployeeFact(icon: CI.mail, label: text.employee_field_email, value: person.email, empty: none, copy: true),
          EmployeeTextFact(
            icon: CI.home,
            label: text.employee_field_address,
            value: person.address,
            empty: none,
            wide: true,
            lines: 2,
            enabled: editable,
            hint: text.employee_edit_address_hint,
            // Searched where they live; the company's country until that is said.
            placesCountry: person.country,
            onPlace: edit.place,
            onSave: edit.save("ADDRESS")
          ),
          EmployeeTextFact(
            icon: CI.home,
            label: text.employee_field_city,
            value: person.city,
            empty: none,
            enabled: editable,
            onSave: edit.save("CITY")
          ),
          EmployeeTextFact(
            icon: CI.home,
            label: text.employee_field_region,
            value: person.region,
            empty: none,
            enabled: editable,
            onSave: edit.save("REGION")
          ),
          EmployeeTextFact(
            icon: CI.home,
            label: text.employee_field_postal_code,
            value: person.postalCode,
            empty: none,
            enabled: editable,
            formatters: _digits(10),
            onSave: edit.save("POSTAL_CODE")
          ),
          EmployeeSelectFact(
            icon: CI.globe_shopping,
            label: text.employee_field_country,
            value: person.country.isEmpty ? "" : countries.nameOf(person.country),
            selected: person.country,
            empty: none,
            enabled: editable,
            options: nations,
            onSave: edit.save("COUNTRY")
          ),
          EmployeeDateFact(
            icon: CI.gift,
            label: text.employee_field_birthday,
            value: employeeDayLabel(context, person.birthday),
            day: person.birthday,
            empty: none,
            enabled: editable,
            onSave: edit.save("BIRTHDAY")
          ),
          EmployeeSelectFact(
            icon: CI.user,
            label: text.employee_field_sex,
            value: employeeSexLabel(context, person.sex),
            selected: person.sex?.value ?? "",
            empty: none,
            enabled: editable,
            options: [
              for (final sex in EmployeeSex.values)
                SelectOption(value: sex.value, placeholder: employeeSexLabel(context, sex))
            ],
            onSave: edit.save("SEX")
          ),
          EmployeeSelectFact(
            icon: CI.network,
            label: text.employee_field_nationality,
            value: person.nationality.isEmpty ? "" : countries.nameOf(person.nationality),
            selected: person.nationality,
            empty: none,
            enabled: editable,
            options: nations,
            onSave: edit.save("NATIONALITY")
          ),
          EmployeeSelectFact(
            icon: CI.safe_user,
            label: text.employee_field_document_type,
            value: employeeDocumentLabel(context, person.documentType),
            selected: person.documentType?.value ?? "",
            empty: none,
            enabled: editable,
            options: [
              for (final document in EmployeeDocument.values)
                SelectOption(value: document.value, placeholder: employeeDocumentLabel(context, document))
            ],
            onSave: edit.save("DOCUMENT_TYPE")
          ),
          EmployeeTextFact(
            icon: CI.safe_user,
            label: text.employee_field_document_number,
            value: person.documentNumber,
            empty: none,
            copy: true,
            enabled: editable,
            // A passport number carries letters in many countries; every other
            // document is a number.
            formatters: person.documentType == EmployeeDocument.passport
              ? [FilteringTextInputFormatter.allow(RegExp("[A-Za-z0-9]")), LengthLimitingTextInputFormatter(20)]
              : _digits(20),
            onSave: edit.save("DOCUMENT_NUMBER")
          ),
          if (editable || person.about.isNotEmpty) EmployeeTextFact(
            icon: CI.message_ai,
            label: text.employee_field_about,
            value: person.about,
            empty: none,
            wide: true,
            lines: 6,
            enabled: editable,
            onSave: edit.save("ABOUT")
          )
        ])
      ]
    );
  }
}

class _Emergency extends StatelessWidget {
  const _Emergency({required this.person, required this.edit});

  final EmployeePerson person;
  final EmployeeEditor edit;

  @override
  Widget build(BuildContext context) {
    final text = S.of(context);
    final none = text.employee_value_none;
    final editable = edit.person;

    return EmployeeSection(
      title: text.employee_emergency_title,
      children: [EmployeeFacts(facts: [
        EmployeeTextFact(
          icon: CI.support,
          // Read-only, the relation names the tile ("Brother") the way the
          // name alone would not; edited, each has its own.
          label: editable || person.emergencyRelation.isEmpty
            ? text.employee_field_emergency_name
            : person.emergencyRelation,
          value: person.emergencyName,
          empty: none,
          enabled: editable,
          onSave: edit.save("EMERGENCY_NAME")
        ),
        if (editable) EmployeeTextFact(
          icon: CI.support,
          label: text.employee_field_emergency_relation,
          value: person.emergencyRelation,
          empty: none,
          onSave: edit.save("EMERGENCY_RELATION")
        ),
        if (editable || person.emergencyPhone.isNotEmpty) EmployeePhoneFact(
          icon: CI.phone,
          label: text.employee_field_phone,
          value: person.emergencyPhone,
          country: person.country.isEmpty ? _companyCountry(context) : person.country,
          empty: none,
          enabled: editable,
          onSave: edit.save("EMERGENCY_PHONE")
        )
      ])]
    );
  }
}

class _Upcoming extends StatelessWidget {
  const _Upcoming({required this.leaves});

  final List<EmployeeLeave> leaves;

  @override
  Widget build(BuildContext context) => EmployeeSection(
    title: S.of(context).employee_upcoming_title,
    children: [
      for (final leave in leaves) EmployeeEvent(
        date: leave.startDate,
        title: employeeLeaveLabel(context, leave.type),
        subtitle: _joined([
          employeeRangeLabel(context, leave.startDate, leave.endDate),
          S.of(context).employee_leave_days(leave.days),
          leave.note
        ], " · ")
      )
    ]
  );
}

/// How the job ended. It goes near the top on a former employee: it is the
/// first thing asked about them.
class _Ending extends StatelessWidget {
  const _Ending({required this.ending});

  final EmployeeEnding ending;

  @override
  Widget build(BuildContext context) {
    final text = S.of(context);
    final reason = employeeEndReasonLabel(context, ending.reason);

    return EmployeeSection(
      title: text.employee_ending_title,
      children: [
        EmployeeEvent(
          date: ending.date,
          title: text.employee_field_ended,
          subtitle: _joined([
            employeeDayLabel(context, ending.date),
            reason.isEmpty ? text.employee_value_none : reason
          ], " · ")
        ),
        if (ending.note.isNotEmpty) EmployeeNote(title: text.employee_field_note, text: ending.note, lines: 4)
      ]
    );
  }
}

/// When the job was filed and when the person answered.
class _Record extends StatelessWidget {
  const _Record({required this.detail});

  final BusinessEmployeeDetail detail;

  @override
  Widget build(BuildContext context) {
    final text = S.of(context);

    return EmployeeSection(
      title: text.employee_record_title,
      children: [EmployeeFacts(facts: [
        EmployeeFact(
          icon: CI.mail,
          label: text.employee_field_invited,
          value: employeeMomentLabel(context, detail.invitedAt)
        ),
        EmployeeFact(
          icon: CI.check,
          label: text.employee_field_responded,
          value: employeeMomentLabel(context, detail.respondedAt),
          empty: text.employee_value_waiting
        )
      ])]
    );
  }
}

class _Notes extends StatelessWidget {
  const _Notes({required this.notes, required this.edit});

  final String notes;
  final EmployeeEditor edit;

  @override
  Widget build(BuildContext context) => EmployeeSection(
    title: S.of(context).employee_notes_title,
    subtitle: S.of(context).employee_notes_subtitle,
    children: [
      if (edit.job) EmployeeFacts(facts: [EmployeeTextFact(
        icon: CI.pen,
        label: S.of(context).employee_notes_title,
        value: notes,
        empty: S.of(context).employee_value_none,
        wide: true,
        lines: 12,
        onSave: edit.save("NOTES")
      )])
      else EmployeeNote(text: notes)
    ]
  );
}
