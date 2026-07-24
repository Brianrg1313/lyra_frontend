import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:core/form.dart';

/// Tipo de informacion que guarda un campo de una tabla de productos.
///
/// Cumple dos funciones y por eso no alcanza con "texto" a secas:
///
/// 1. Le dice a la IA que esperar en esa columna (un importe, un codigo de
///    articulo, una fecha de caducidad), para que pueda leer, completar y
///    contrastar el catalogo sin que nadie se lo explique campo por campo.
/// 2. Define con que UI se rellena el campo al cargar stock: un teclado
///    numerico para [number], un selector de moneda para [price], un
///    calendario para [date], un interruptor para [boolean].
///
/// [vector] es la salida para lo que no encaja en ningun tipo concreto: texto
/// libre que el backend indexa por significado para que la IA lo busque.
///
/// [counter] y [stock] no se escriben a mano: los lleva el backend (el segundo,
/// contra el motor de inventario). Se declaran igual porque forman parte de la
/// tabla y hay que reservarles la columna.
///
/// La lista de codigos es la del backend y tiene que coincidir exactamente:
/// es lo unico que viaja en el alta y en la lectura de una tabla.
enum TableFieldType {
  text,
  textarea,
  number,
  decimal,
  price,
  sku,
  counter,
  boolean,
  date,
  datetime,
  email,
  phone,
  url,
  select,
  image,
  vector,
  stock;

  /// El desconocido cae en [text]: si el backend manda un tipo que esta
  /// version todavia no conoce, el campo se sigue viendo y editando como texto
  /// en vez de perderse. No cae en [vector] a proposito, que arrastra una
  /// indexacion semantica que ese campo puede no tener.
  static TableFieldType from(dynamic raw) => switch (
    raw?.toString().toUpperCase()
  ) {
    "TEXTAREA" => textarea,
    "NUMBER" => number,
    "DECIMAL" => decimal,
    "PRICE" => price,
    "SKU" => sku,
    "COUNTER" => counter,
    "BOOLEAN" => boolean,
    "DATE" => date,
    "DATETIME" => datetime,
    "EMAIL" => email,
    "PHONE" => phone,
    "URL" => url,
    "SELECT" => select,
    "IMAGE" => image,
    "VECTOR" => vector,
    "STOCK" => stock,
    _ => text
  };

  /// Codigo que viaja al backend. No se traduce.
  String get value => switch (this) {
    text => "TEXT",
    textarea => "TEXTAREA",
    number => "NUMBER",
    decimal => "DECIMAL",
    price => "PRICE",
    sku => "SKU",
    counter => "COUNTER",
    boolean => "BOOLEAN",
    date => "DATE",
    datetime => "DATETIME",
    email => "EMAIL",
    phone => "PHONE",
    url => "URL",
    select => "SELECT",
    image => "IMAGE",
    vector => "VECTOR",
    stock => "STOCK"
  };

  String label(BuildContext context) => switch (this) {
    text => S.of(context).field_type_text,
    textarea => S.of(context).field_type_textarea,
    number => S.of(context).field_type_number,
    decimal => S.of(context).field_type_decimal,
    price => S.of(context).field_type_price,
    sku => S.of(context).field_type_sku,
    counter => S.of(context).field_type_counter,
    boolean => S.of(context).field_type_boolean,
    date => S.of(context).field_type_date,
    datetime => S.of(context).field_type_datetime,
    email => S.of(context).field_type_email,
    phone => S.of(context).field_type_phone,
    url => S.of(context).field_type_url,
    select => S.of(context).field_type_select,
    image => S.of(context).field_type_image,
    vector => S.of(context).field_type_vector,
    stock => S.of(context).field_type_stock
  };

  /// Que informacion se espera encontrar en el campo. Se muestra bajo la
  /// etiqueta al elegir el tipo, para que el administrador sepa cual encaja.
  String hint(BuildContext context) => switch (this) {
    text => S.of(context).field_type_text_hint,
    textarea => S.of(context).field_type_textarea_hint,
    number => S.of(context).field_type_number_hint,
    decimal => S.of(context).field_type_decimal_hint,
    price => S.of(context).field_type_price_hint,
    sku => S.of(context).field_type_sku_hint,
    counter => S.of(context).field_type_counter_hint,
    boolean => S.of(context).field_type_boolean_hint,
    date => S.of(context).field_type_date_hint,
    datetime => S.of(context).field_type_datetime_hint,
    email => S.of(context).field_type_email_hint,
    phone => S.of(context).field_type_phone_hint,
    url => S.of(context).field_type_url_hint,
    select => S.of(context).field_type_select_hint,
    image => S.of(context).field_type_image_hint,
    vector => S.of(context).field_type_vector_hint,
    stock => S.of(context).field_type_stock_hint
  };

  IconData get icon => switch (this) {
    text => Icons.short_text,
    textarea => Icons.notes_outlined,
    number => Icons.numbers,
    decimal => Icons.straighten,
    price => CI.wallet,
    sku => Icons.qr_code_2,
    counter => Icons.plus_one,
    boolean => Icons.toggle_on_outlined,
    date => CI.calendar,
    datetime => Icons.schedule,
    email => CI.mail,
    phone => Icons.phone_outlined,
    url => CI.link,
    select => Icons.arrow_drop_down_circle_outlined,
    image => CI.add_image,
    vector => Icons.auto_awesome,
    stock => Icons.inventory_2_outlined
  };

  /// Opciones del desplegable de tipos, en el orden en que estan declarados.
  static List<SelectOption> options(BuildContext context) => [
    for (final type in values) SelectOption(
      value: type.value,
      placeholder: type.label(context),
      subtitle: type.hint(context),
      icon: type.icon
    )
  ];
}
