import 'package:flutter/widgets.dart' show BuildContext;

import 'package:app/toolkit/toolkit.dart';
import 'package:core/form.dart' show SelectOption;

/// Plantilla de tabla: un rubro con un nombre reconocible, para no arrancar de
/// una tabla vacia sin ninguna pista de que cargar. Es solo un catalogo de
/// nombres: quien arma las columnas de cada rubro es el backend, al recibir
/// [value] en el alta ([TablesService.create]) cuando no es [blank]. El front
/// no conoce ni carga columnas por su cuenta.
///
/// [blank] es la que arranca elegida y no manda rubro: elegir una plantilla
/// nunca es obligatorio para crear una tabla.
///
/// Los rubros se pensaron para no confundirse entre si al elegirlos: por eso
/// "belleza" y "accesorios de belleza" son uno solo (`beauty`) en vez de dos
/// que un usuario apurado difícilmente distinga.
class TableTemplate {
  const TableTemplate({required this.value, required this.label});

  /// Codigo del rubro. Viaja tal cual al backend (`TEMPLATE` en el alta)
  /// cuando no es [blank]; del otro lado se resuelve a las columnas que le
  /// correspondan.
  final String value;
  final String label;

  static const blank = "BLANK";

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

  /// Opciones del desplegable, en el mismo orden que [all].
  static List<SelectOption> options(BuildContext context) => [
    for (final template in all(context))
      SelectOption(value: template.value, placeholder: template.label)
  ];
}
