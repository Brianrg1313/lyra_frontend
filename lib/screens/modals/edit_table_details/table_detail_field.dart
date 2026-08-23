import 'package:flutter/widgets.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/stock/tables/table_detail_model.dart';
import 'package:app/services/stock/tables/table_detail_service.dart';

/// Un dato de la cabecera de una tabla que se puede escribir desde sus
/// ajustes: como se llama la tabla y que guarda.
///
/// Vive aparte del formulario porque es lo que necesita el formulario para
/// armarse solo: la ficha describe el dato una vez —de donde se lee, con que
/// forma se escribe, con que clave se guarda— y no tiene que saber nada del
/// modal que lo cambia. Es el mismo reparto que hace `BusinessField` con el
/// perfil de la empresa.
///
/// Son solo estos dos a proposito. El color se elige y no se escribe, las
/// columnas se editan en la propia planilla —que es donde se las ve— y de que
/// tabla lee un bot se decide desde el bot: lo unico que aca se **escribe** es
/// texto.
///
/// El nombre del valor es `title` y no `name` porque asi se llama en pantalla
/// (es el titulo de la tabla, como en el alta), aunque del otro lado la clave
/// sea `NAME`. Esa traduccion la hace [save] y no la ficha.
enum TableDetailField {
  title,
  description;

  /// Lo que hay guardado hoy: con esto se abre el campo lleno.
  String value(TableDetailModel detail) => switch (this) {
    title => detail.name,
    description => detail.description
  };

  /// Como se llama el dato. Es el mismo texto que lo nombra en la ficha, en el
  /// titulo del modal y en sus errores: son el mismo dato leido tres veces.
  String label(BuildContext context) => switch (this) {
    title => S.of(context).table_settings_name,
    description => S.of(context).table_settings_description
  };

  String placeholder(BuildContext context) => switch (this) {
    title => S.of(context).table_title_placeholder,
    description => S.of(context).table_description_placeholder
  };

  /// Una tabla sin nombre no se puede listar; una sin descripcion si, y de
  /// hecho casi todas nacen asi.
  bool get obligatory => this == title;

  int? get min => this == title ? 3 : null;
  int get max => this == title ? 60 : 240;

  /// El mismo juego de caracteres que acepta el alta: es el mismo nombre de
  /// tabla, escrito en otro momento. La descripcion no filtra nada —es texto
  /// libre— y por eso pasa con `IGNORE`.
  String get pattern => this == title
    ? "[A-Za-zÀ-ÖØ-öø-ÿ0-9 '&.,()/\\-]"
    : "IGNORE";

  /// Guarda [text] como este dato. Es una escritura **parcial**: el otro dato
  /// no viaja, asi que corregir la descripcion no puede pisar un renombre que
  /// haya entrado mientras tanto.
  Future<bool> save(
    BuildContext context,
    TableDetailService service,
    String text
  ) => switch (this) {
    title => service.edit(context, name: text),
    description => service.edit(context, description: text)
  };
}
