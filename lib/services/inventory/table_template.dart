import 'package:flutter/widgets.dart' show BuildContext;

import 'package:app/toolkit/toolkit.dart';
import 'package:core/form.dart' show SelectOption;

/// Table template: a category with a recognizable name, so as not to start from
/// an empty table with no clue of what to fill in. It is only a catalog of
/// names: whoever builds the columns for each category is the backend, when it
/// receives [value] on creation ([TablesService.create]) when it is not [blank]. The front
/// does not know or load columns on its own.
///
/// [blank] is the one that starts selected and sends no category: choosing a template
/// is never required to create a table.
///
/// The categories were designed not to be confused with each other when choosing them: that is why
/// "beauty" and "beauty accessories" are one single one (`beauty`) instead of two
/// that a rushed user would hardly tell apart.
class TableTemplate {
  const TableTemplate({required this.value, required this.label});

  /// Category code. It travels as-is to the backend (`TEMPLATE` on creation)
  /// when it is not [blank]; on the other side it resolves to the columns that
  /// correspond to it.
  final String value;
  final String label;

  static const blank = "BLANK";

  /// The backend's restaurant menu (category, portion, prep time): the only start a menu
  /// (`made` table) is offered besides [blank]. The others are a catalog's columns (sizes,
  /// brands), and the bakery's and drinks' carry a `stock` column a made product never has:
  /// what it can sell is what its supplies allow.
  static const menu = "MENU";

  static List<TableTemplate> all(BuildContext context) => [
    TableTemplate(value: blank, label: S.of(context).table_template_blank),
    TableTemplate(value: "CLOTHING", label: S.of(context).table_template_clothing),
    TableTemplate(value: "SHOES", label: S.of(context).table_template_shoes),
    TableTemplate(value: "ELECTRONICS", label: S.of(context).table_template_electronics),
    TableTemplate(value: "APPLIANCES", label: S.of(context).table_template_appliances),
    TableTemplate(value: "HOME", label: S.of(context).table_template_home),
    TableTemplate(value: "HEALTH", label: S.of(context).table_template_health),
    TableTemplate(value: "BEAUTY", label: S.of(context).table_template_beauty),
    TableTemplate(value: "FOOD", label: S.of(context).table_template_food),
    TableTemplate(value: "ACCESSORIES", label: S.of(context).table_template_accessories)
  ];

  /// Dropdown options, in the same order as [all].
  static List<SelectOption> options(BuildContext context) => [
    for (final template in all(context))
      SelectOption(value: template.value, placeholder: template.label)
  ];
}
