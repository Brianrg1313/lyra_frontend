import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter, LengthLimitingTextInputFormatter, TextInputFormatter;
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';
import 'package:app/services/catalog/country_catalog_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/business/settings/country_flag.dart';

/// The company's country: the phone code offered for a phone that has none.
String employeeCompanyCountry(BuildContext context) => context.read<BusinessService>().profile?.country ?? "";

/// Digits only, at most [length] of them.
List<TextInputFormatter> employeeDigits(int length) => [
  FilteringTextInputFormatter.digitsOnly,
  LengthLimitingTextInputFormatter(length)
];

String employeeJoined(List<String> parts, String separator) =>
  parts.where((part) => part.isNotEmpty).join(separator);

String employeeAmount(String text) => text.replaceAll(",", ".");

String? employeeCheckAmount(BuildContext context, String text) {
  final amount = double.tryParse(employeeAmount(text));

  return amount != null && amount >= 0 ? null : S.of(context).employee_edit_invalid_amount;
}

/// Letters of any alphabet and what joins them in a name ("O'Neil",
/// "Ana-María", "Jr."); it starts with a letter.
final _nameShape = RegExp(r"^[\p{L}\p{M}][\p{L}\p{M} .'’\-]*$", unicode: true);

String? employeeCheckName(BuildContext context, String label, String text) =>
  _nameShape.hasMatch(text) ? null : S.of(context).employee_edit_invalid_name(label);

/// One `@` between a name and a domain with a dot: the backend and the mail
/// server judge the rest.
final _emailShape = RegExp(r"^[^\s@]+@[^\s@]+\.[^\s@.]{2,}$");

String? employeeCheckEmail(BuildContext context, String text) =>
  _emailShape.hasMatch(text) ? null : S.of(context).employee_edit_invalid_email;

/// The youngest a person takes a job at in the countries the platform
/// operates in (14 in most of Latin America).
const _youngest = 14;

String? employeeCheckBirthday(BuildContext context, DateTime day) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  if (!day.isBefore(today)) return S.of(context).employee_edit_birthday_future;

  final grown = DateTime(day.year + _youngest, day.month, day.day);

  return grown.isAfter(today) ? S.of(context).employee_edit_birthday_young(_youngest) : null;
}

/// The names in use across the company for one job field, for the list a
/// title or a department is picked from.
List<SelectOption> employeeOptionsInUse(Iterable<String> values) {
  final names = {for (final value in values) if (value.trim().isNotEmpty) value.trim()}.toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  return [for (final name in names) SelectOption(value: name, placeholder: name)];
}

List<SelectOption> employeeCountryOptions(BuildContext context) => [
  // Watched: the catalog may answer after the panel is drawn.
  for (final country in context.watch<CountryCatalogService>().countries)
    SelectOption(
      value: country.code,
      placeholder: country.name,
      leading: CountryFlag(country: country)
    )
];
