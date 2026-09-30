import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:core/form.dart';

/// Type of information that a field of a product table stores.
///
/// It serves two purposes and that is why just "text" is not enough:
///
/// 1. It tells the AI what to expect in that column (an amount, an item
///    code, an expiry date), so it can read, complete and
///    cross-check the catalog without anyone explaining it field by field.
/// 2. It defines which UI fills the field when loading stock: a numeric
///    keyboard for [number], a currency picker for [price], a
///    calendar for [date], a dropdown for [options].
///
/// [title] and [description] are the two that the backend **indexes by
/// meaning**: they are the text the AI reads and searches by. They are two and not
/// one because they answer different questions —how the product is **named** and what
/// it **is**— and everything that has to name a row (the POS ticket, the
/// agent's cart, the stock summary) reads the first one instead of
/// guessing which of the text columns was the name.
///
/// [counter] and [stock] are not written by hand: the backend carries them (the second one,
/// against the inventory engine). They are declared the same because they are part of the
/// table and their column has to be reserved.
///
/// The code list is the backend's (the `TYPE` rule of its validator) and
/// has to match exactly: it is the only thing that travels in creation and in
/// reading a table. The order here is the one there, so both lists
/// can be read side by side.
enum TableFieldType {
  text,
  textarea,
  title,
  description,
  sku,
  barcode,
  number,
  decimal,
  price,
  currency,

  /// The only percent anything subtracts: the POS takes the first one off the first [price]
  /// (`Catalog.net` in the backend) and the bot quotes the same figure. A [percentage] never
  /// is, which is why they are two types, and why the backend refuses a discount outside
  /// 0–100: a 1200 there would give the product away.
  discount,
  percentage,
  measure,
  counter,
  boolean,
  date,
  datetime,
  email,
  phone,
  url,
  options,
  categories,
  image,
  stock;

  /// The unknown falls into [text]: if the backend sends a type that this
  /// version does not know yet, the field keeps being seen and edited as text
  /// instead of being lost. It deliberately does not fall into any of the semantic ones, which
  /// drag an indexing that field may not have.
  ///
  /// `SELECT` and `VECTOR` are the two old names and they keep being read: the
  /// database migrates them on its own (`select` was renamed to `options`, and `vector` was
  /// split into [title] and [description]), but an installation that has not
  /// run the migration yet has to draw its columns anyway. A
  /// surviving `VECTOR` falls into [description] and not [title] for the same reason
  /// the migration leaves there everyone but the first one: a table can have
  /// several, and assuming each one is the product name would be worse than
  /// assuming none of them is.
  static TableFieldType from(dynamic raw) => switch (
    raw?.toString().toUpperCase()
  ) {
    "TEXTAREA" => textarea,
    "TITLE" => title,
    "DESCRIPTION" => description,
    "SKU" => sku,
    "BARCODE" => barcode,
    "NUMBER" => number,
    "DECIMAL" => decimal,
    "PRICE" => price,
    "CURRENCY" => currency,
    "DISCOUNT" => discount,
    "PERCENTAGE" => percentage,
    "MEASURE" => measure,
    "COUNTER" => counter,
    "BOOLEAN" => boolean,
    "DATE" => date,
    "DATETIME" => datetime,
    "EMAIL" => email,
    "PHONE" => phone,
    "URL" => url,
    "OPTIONS" || "SELECT" => options,
    "CATEGORIES" => categories,
    "IMAGE" => image,
    "STOCK" => stock,
    "VECTOR" => description,
    _ => text
  };

  /// Code that travels to the backend. It is not translated.
  String get value => name.toUpperCase();

  String label(BuildContext context) => switch (this) {
    text => S.of(context).field_type_text,
    textarea => S.of(context).field_type_textarea,
    title => S.of(context).field_type_title,
    description => S.of(context).field_type_description,
    sku => S.of(context).field_type_sku,
    barcode => S.of(context).field_type_barcode,
    number => S.of(context).field_type_number,
    decimal => S.of(context).field_type_decimal,
    price => S.of(context).field_type_price,
    currency => S.of(context).field_type_currency,
    discount => S.of(context).field_type_discount,
    percentage => S.of(context).field_type_percentage,
    measure => S.of(context).field_type_measure,
    counter => S.of(context).field_type_counter,
    boolean => S.of(context).field_type_boolean,
    date => S.of(context).field_type_date,
    datetime => S.of(context).field_type_datetime,
    email => S.of(context).field_type_email,
    phone => S.of(context).field_type_phone,
    url => S.of(context).field_type_url,
    options => S.of(context).field_type_options,
    categories => S.of(context).field_type_categories,
    image => S.of(context).field_type_image,
    stock => S.of(context).field_type_stock
  };

  /// What information is expected to be found in the field. It is shown under the
  /// label when choosing the type, so the administrator knows which one fits.
  String hint(BuildContext context) => switch (this) {
    text => S.of(context).field_type_text_hint,
    textarea => S.of(context).field_type_textarea_hint,
    title => S.of(context).field_type_title_hint,
    description => S.of(context).field_type_description_hint,
    sku => S.of(context).field_type_sku_hint,
    barcode => S.of(context).field_type_barcode_hint,
    number => S.of(context).field_type_number_hint,
    decimal => S.of(context).field_type_decimal_hint,
    price => S.of(context).field_type_price_hint,
    currency => S.of(context).field_type_currency_hint,
    discount => S.of(context).field_type_discount_hint,
    percentage => S.of(context).field_type_percentage_hint,
    measure => S.of(context).field_type_measure_hint,
    counter => S.of(context).field_type_counter_hint,
    boolean => S.of(context).field_type_boolean_hint,
    date => S.of(context).field_type_date_hint,
    datetime => S.of(context).field_type_datetime_hint,
    email => S.of(context).field_type_email_hint,
    phone => S.of(context).field_type_phone_hint,
    url => S.of(context).field_type_url_hint,
    options => S.of(context).field_type_options_hint,
    categories => S.of(context).field_type_categories_hint,
    image => S.of(context).field_type_image_hint,
    stock => S.of(context).field_type_stock_hint
  };

  IconData get icon => switch (this) {
    text => Icons.short_text,
    textarea => Icons.notes_outlined,
    title => Icons.title,
    description => CI.ia,
    sku => Icons.qr_code_2,
    barcode => Icons.barcode_reader,
    number => Icons.numbers,
    decimal => Icons.straighten,
    price => CI.wallet,
    currency => CI.cashbox,
    discount => CI.discount,
    percentage => Icons.percent,
    measure => CI.kg_square,
    counter => Icons.plus_one,
    boolean => Icons.toggle_on_outlined,
    date => CI.calendar,
    datetime => Icons.schedule,
    email => CI.mail,
    phone => CI.phone,
    url => CI.link,
    options => Icons.arrow_drop_down_circle_outlined,
    categories => CI.list,
    image => CI.image,
    stock => Icons.inventory_2_outlined
  };

  /// Whether the field is filled by hand.
  ///
  /// [counter] and [stock] are carried by the backend (the second one, against the
  /// inventory engine): their cells look like just another datum, but disabled and without
  /// an editor.
  bool get editable => switch (this) {
    counter || stock => false,
    _ => true
  };

  /// Whether the field text is **indexed by the backend by meaning**: it is what
  /// the AI reads and searches by, and not just another datum of the row.
  ///
  /// The type knows it because there are three who ask the same thing and all three
  /// answer the same —with the brand color—: the cell, the editor and the
  /// stock summary. They are [title] and [description], the two that replaced the
  /// old `vector`.
  bool get semantic => this == title || this == description;

  /// Whether the field picks its values from a **closed list** that belongs to
  /// the column (see `TableFieldModel.options`).
  ///
  /// There are two and the difference is how many each record stores: from an [options]
  /// only one (a condition, a size), from a [categories] several (a product
  /// is "shoes" and "sports" at the same time). That is why they are two types and not one with
  /// a switch: what changes is not how it is picked but what is stored in
  /// the cell, a text versus a list.
  bool get listed => this == options || this == categories;

  /// Whether a cell of this field stores **several** values.
  bool get multiple => this == categories;

  /// Whether the field's numbers do not bring their own symbol, so the symbol belongs to
  /// the column and travels with it (see `TableFieldModel.unit`): the currency of
  /// [price] and [currency], the magnitude of [measure].
  ///
  /// [discount] and [percentage] are deliberately left out: there the unit **is** the type.
  bool get united => this == price || this == currency || this == measure;

  /// Whether the field value is money. Both are read the same —an amount with the
  /// symbol of its currency— and the only thing that separates them is that [price] is what
  /// the company **charges**, and that is why it is the only one the agent can tell
  /// a client.
  bool get money => this == price || this == currency;

  /// Whether the field is **touched** instead of written.
  ///
  /// Neither a list nor an image has a text editor: their cell deploys something
  /// and it is chosen there —the field options in one, what to do with the photo in the
  /// other—. That is why it needs to be distinguished from [editable] —which says whether the datum
  /// is filled by hand, and both are filled by hand— and that is why the type knows it and not
  /// the cell: it is the same question that decides whether the cursor opens the editor or the
  /// dropdown, and both the touch and the keyboard ask it.
  ///
  /// It is also what decides how the cell breathes: both draw their own
  /// frame inside, so they get the air of a frame and not of a text
  /// (see `SheetStyle.framePadding`).
  bool get picker => listed || this == image;

  /// Whether the field stores a date.
  ///
  /// Both are written the same —numbers are typed— and both are read the same, so
  /// the only thing that distinguishes them is whether they also carry a time, and that is already said by the
  /// stored datum (see `ProductDate.hasTime`). The type knows it because there are two
  /// who ask the same thing: the cell, to write the date in letters, and
  /// the editor, to change its space for a slash while typing.
  bool get isDate => this == date || this == datetime;

  /// With which pointer the cell of this field is seen.
  ///
  /// It is [picker] answered for the mouse: where it is written goes the text
  /// pointer, and where it is touched and something opens goes the one of a button. The pointer
  /// is the only thing that says, **before** touching, whether that cell is written or
  /// chosen: both cell types look similar and until now both
  /// carried the same spreadsheet pointer, which distinguishes nothing.
  ///
  /// The type knows it and not the cell for the same reason as [alignment]: it is a
  /// property of the column, the same in all its rows. Whoever paints it decides
  /// separately what to do with a cell that is **not** written (a field carried by the
  /// backend, a row that has not arrived yet): none of the two goes there.
  MouseCursor get cursor =>
    picker ? SystemMouseCursors.click : SystemMouseCursors.text;

  /// How the value is aligned in its cell: numbers to the right and the rest to
  /// the left, like in a spreadsheet.
  TextAlign get alignment => switch (this) {
    number ||
    decimal ||
    price ||
    currency ||
    discount ||
    percentage ||
    measure ||
    counter ||
    stock => TextAlign.right,
    _ => TextAlign.left
  };

  /// Keyboard with which the field is written. The numeric types open the
  /// numbers one; the rest, the text one.
  TextInputType get keyboard => switch (this) {
    number || counter || stock => TextInputType.number,
    decimal ||
    price ||
    currency ||
    discount ||
    percentage ||
    measure => const TextInputType.numberWithOptions(decimal: true),
    email => TextInputType.emailAddress,
    phone => TextInputType.phone,
    url => TextInputType.url,
    textarea || description => TextInputType.multiline,
    _ => TextInputType.text
  };

  /// The types in the order they are offered: the two semantic ones first and the
  /// rest as they are declared.
  ///
  /// [title] and [description] head the list because they are the ones that give
  /// meaning to the catalog: they are the text the backend indexes by meaning, that
  /// is, what the AI reads, searches and cross-checks. A loose text column almost
  /// always wants to be one of the two, so they are offered before the rest instead
  /// of getting lost in the middle of a list of twenty-four.
  static List<TableFieldType> get ordered => [
    title,
    description,
    for (final type in values)
      if (type != title && type != description) type
  ];

  /// Type dropdown options, in the order of [ordered].
  ///
  /// It is called [menu] and not `options` because `options` is already one of the types: the
  /// datum won the name before the list used to pick it.
  static List<SelectOption> menu(BuildContext context) => [
    for (final type in ordered) SelectOption(
      value: type.value,
      placeholder: type.label(context),
      subtitle: type.hint(context),
      icon: type.icon
    )
  ];
}
