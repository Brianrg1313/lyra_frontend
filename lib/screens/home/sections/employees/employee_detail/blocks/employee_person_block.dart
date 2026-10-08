import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter, LengthLimitingTextInputFormatter;
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_employee_detail_model.dart';
import 'package:app/services/business/business_employees_service.dart';
import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/services/catalog/country_catalog_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';
import 'package:app/screens/home/sections/employees/employee_facts/_employee_facts.dart';
import 'package:app/screens/home/sections/employees/employee_facts/employee_date_fact.dart';
import 'package:app/screens/home/sections/employees/employee_facts/employee_fact.dart';
import 'package:app/screens/home/sections/employees/employee_facts/employee_note.dart';
import 'package:app/screens/home/sections/employees/employee_facts/employee_phone_fact.dart';
import 'package:app/screens/home/sections/employees/employee_facts/employee_section.dart';
import 'package:app/screens/home/sections/employees/employee_facts/employee_select_fact.dart';
import 'package:app/screens/home/sections/employees/employee_facts/employee_text_fact.dart';
import 'package:app/screens/home/sections/employees/employee_format.dart';
import 'package:app/screens/modals/server/master_password/_master_password.dart';

import './employee_block_values.dart';
import './employee_editor.dart';

/// The person's own profile, first in the panel: who they are comes before
/// what they do here. Whole only while the job is active; otherwise the
/// section says why it is not there instead of showing empty tiles that would
/// read as unknown.
class EmployeePersonBlock extends StatelessWidget {
  const EmployeePersonBlock({super.key, required this.detail, required this.edit});

  final BusinessEmployeeDetail detail;
  final EmployeeEditor edit;

  @override
  Widget build(BuildContext context) {
    final text = S.of(context);

    // A session the cloud's grant opened on a master: the password there opens it (`session.md` S-13).
    if (detail.sealedLocked) {
      return EmployeeSection(
        title: text.employee_person_title,
        children: [
          EmployeeNote(text: text.employee_person_sealed, lines: 3),
          Button(title: text.finance_methods_unlock, width: null, action: () => _unseal(context))
        ]
      );
    }

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
    final nations = editable ? employeeCountryOptions(context) : const <SelectOption>[];

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
            validate: (value) => employeeCheckName(context, text.employee_field_first_name, value),
            onSave: edit.savePerson("FIRST_NAME")
          ),
          EmployeeTextFact(
            icon: CI.user,
            label: text.employee_field_last_name,
            value: person.lastName,
            empty: none,
            enabled: editable,
            required: true,
            validate: (value) => employeeCheckName(context, text.employee_field_last_name, value),
            onSave: edit.savePerson("LAST_NAME")
          ),
          EmployeePhoneFact(
            icon: CI.phone,
            label: text.employee_field_phone,
            value: person.phone,
            country: person.country.isEmpty ? employeeCompanyCountry(context) : person.country,
            empty: none,
            enabled: editable,
            onSave: edit.savePerson("PHONE")
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
            // Searched where they live; the company's country until that is said. The search is
            // the cloud's: without it the address is typed.
            placesCountry: person.country,
            onPlace: CapabilityService().cloudServices ? edit.place : null,
            onSave: edit.savePerson("ADDRESS")
          ),
          EmployeeTextFact(
            icon: CI.home,
            label: text.employee_field_city,
            value: person.city,
            empty: none,
            enabled: editable,
            onSave: edit.savePerson("CITY")
          ),
          EmployeeTextFact(
            icon: CI.home,
            label: text.employee_field_region,
            value: person.region,
            empty: none,
            enabled: editable,
            onSave: edit.savePerson("REGION")
          ),
          EmployeeTextFact(
            icon: CI.home,
            label: text.employee_field_postal_code,
            value: person.postalCode,
            empty: none,
            enabled: editable,
            formatters: employeeDigits(10),
            onSave: edit.savePerson("POSTAL_CODE")
          ),
          EmployeeSelectFact(
            icon: CI.globe_shopping,
            label: text.employee_field_country,
            value: person.country.isEmpty ? "" : countries.nameOf(person.country),
            selected: person.country,
            empty: none,
            enabled: editable,
            options: nations,
            onSave: edit.savePerson("COUNTRY")
          ),
          EmployeeDateFact(
            icon: CI.gift,
            label: text.employee_field_birthday,
            value: employeeDayLabel(context, person.birthday),
            day: person.birthday,
            empty: none,
            enabled: editable,
            validate: (day) => employeeCheckBirthday(context, day),
            onSave: edit.savePerson("BIRTHDAY")
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
            onSave: edit.savePerson("SEX")
          ),
          EmployeeSelectFact(
            icon: CI.network,
            label: text.employee_field_nationality,
            value: person.nationality.isEmpty ? "" : countries.nameOf(person.nationality),
            selected: person.nationality,
            empty: none,
            enabled: editable,
            options: nations,
            onSave: edit.savePerson("NATIONALITY")
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
            onSave: edit.savePerson("DOCUMENT_TYPE")
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
              : employeeDigits(20),
            onSave: edit.savePerson("DOCUMENT_NUMBER")
          ),
          if (editable || person.about.isNotEmpty) EmployeeTextFact(
            icon: CI.message_ai,
            label: text.employee_field_about,
            value: person.about,
            empty: none,
            wide: true,
            lines: 6,
            enabled: editable,
            onSave: edit.savePerson("ABOUT")
          )
        ])
      ]
    );
  }

  Future<void> _unseal(BuildContext context) async {
    final employees = context.read<BusinessEmployeesService>();
    if (await showUnseal(context)) await employees.loadDetail(detail.id, force: true);
  }
}
