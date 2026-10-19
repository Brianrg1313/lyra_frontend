/// Bodies of the three write operations for a column (field) of an already
/// created table: creation (`POST /v1/inventory/products/builder/fields/`), editing
/// (`PUT /v1/inventory/products/builder/fields/`) and deletion (`DELETE /v1/inventory/products/builder/fields/`).
///
/// They live apart from the screen because they are the contract with the backend: what is
/// built here is what is documented on the other side, and thus it can be tested without
/// mounting the modal.
///
/// The owning company does not go in the body: it travels in the `business_id` header of
/// all requests (see `useBusiness` in `toolkit/api.dart`). The [tableId]
/// does travel in creation, because the field belongs to a concrete table; in
/// editing the field id is enough, which already knows which table it belongs to.
///
/// Creation shape:
///
/// ```json
/// {
///   "TABLE_ID": "a1b2c3",
///   "NAME": "Price",
///   "DESCRIPTION": "Sale price including tax",
///   "POSITION": 3,
///   "TYPE": "PRICE"
/// }
/// ```
///
/// Editing shape:
///
/// ```json
/// {
///   "ID": "d4e5f6",
///   "NAME": "Precio",
///   "TYPE": "PRICE",
///   "VISIBILITY": "declared",
///   "WIDTH": 180
/// }
/// ```
///
/// The options of an `OPTIONS` or `CATEGORIES` field travel in `OPTIONS`, as
/// the whole list and not as the one being added: they belong to the field, so
/// they are stored just like its name or its width —writing the resulting value— and
/// not with a separate creation. The unit of a `PRICE`, a `CURRENCY` or a `MEASURE`
/// travels the same way, in `UNIT`: it is the symbol with which the numbers of
/// that column are written, and it also belongs to the column and not to each value.
///
/// ```json
/// { "ID": "d4e5f6", "NAME": "Color", "OPTIONS": ["Rojo", "Verde"] }
/// { "ID": "a7b8c9", "NAME": "Costo", "UNIT": "USD" }
/// ```
///
/// Deletion shape:
///
/// ```json
/// { "ID": "d4e5f6" }
/// ```
library;

/// Builds the creation body of a field.
///
/// Trims the texts and omits the description when it ends up empty, instead of
/// sending it blank: thus the backend distinguishes "no description" from
/// "description deleted", just like the rest of the optional api fields.
///
/// The [position] orders the columns: whoever creates the field resolves it as the
/// current number of columns, so the new one ends up last.
///
/// The [options] and the [unit] are omitted when not passed, like the description:
/// a column is born without a list and without a symbol, and both are set later from
/// the table sheet or from the cell itself.
Map<String, dynamic> createFieldRequest({
  required String tableId,
  required String name,
  required String description,
  required String type,
  required int position,
  List<String>? options,
  String? unit
}) {
  final trimmed = description.trim();
  final symbol = unit?.trim() ?? "";

  return {
    "TABLE_ID": tableId,
    "NAME": name.trim(),
    if (trimmed.isNotEmpty) "DESCRIPTION": trimmed,
    "POSITION": position,
    "TYPE": type,
    if (options != null) "OPTIONS": [
      for (final option in options)
        if (option.trim().isNotEmpty) option.trim()
    ],
    if (symbol.isNotEmpty) "UNIT": symbol
  };
}

/// Builds the editing body of a field.
///
/// The name is required even when it is not being changed: the backend always asks
/// for it, so whoever edits only the type sends the one the field already had. The
/// rest are truly optional and what is not sent is not touched, so that
/// changing the type does not delete the description, does not move the column nor
/// change its width.
///
/// The [width] is the width of the column on screen and goes whole: it is a measure
/// in logical pixels, and the fraction left by a drag means nothing on the
/// other side.
///
/// The [visibility] is how much the AI model sees of the column
/// (`visible` / `declared` / `hidden`). It travels like the type —only when it is
/// changed— because it is the same: a property of the column that corrects itself,
/// without touching anything written in it.
///
/// The [summary] is whether the column is shown in the inventory summary, the
/// short view a person reads. It travels as the `1`/`0` that the backend
/// documents and not as a boolean —on the other side it accepts both, but what is
/// stored is the number—, and only when it is changed: not sending it leaves the
/// column where it was, inside or outside the summary.
///
/// The [options] are the full list of an `OPTIONS` or `CATEGORIES` field just
/// as it has to remain. An empty list **does** travel, and it is what deletes the
/// field's options. Not sending them leaves them as they were, like the rest of the
/// optional fields.
///
/// The [unit] is the symbol with which the numbers of a `PRICE`, a
/// `CURRENCY` or a `MEASURE` are written. It behaves like the options: an empty text
/// **does** travel and is what removes the unit from the column, and not sending it leaves it
/// as it was. They are the only two keys where "empty" is a value and
/// not the absence of one, which is why they are not trimmed to `null` like the
/// description.
Map<String, dynamic> editFieldRequest({
  required String id,
  required String name,
  String? description,
  String? type,
  int? position,
  int? width,
  String? visibility,
  bool? summary,
  List<String>? options,
  String? unit,
  bool convert = false
}) {
  final trimmed = description?.trim() ?? "";

  return {
    "ID": id,
    "NAME": name.trim(),
    if (trimmed.isNotEmpty) "DESCRIPTION": trimmed,
    "POSITION": ?position,
    if (type != null && type.isNotEmpty) "TYPE": type,
    "WIDTH": ?width,
    if (visibility != null && visibility.isNotEmpty) "VISIBILITY": visibility,
    if (summary != null) "SUMMARY": summary ? 1 : 0,
    if (options != null) "OPTIONS": [
      for (final option in options)
        if (option.trim().isNotEmpty) option.trim()
    ],
    if (unit != null) "UNIT": unit.trim(),
    if (unit != null && convert) "CONVERT": true
  };
}

/// Builds the deletion body of a field.
///
/// It is only the id: the field already knows which table and company it belongs to, and the
/// backend gives it a logical deletion (`status = 0`) together with whatever was loaded
/// in that column. It has its function just like the other two, so the three
/// write operations of the field are read —and tested— in the same place.
Map<String, dynamic> deleteFieldRequest({required String id}) => {"ID": id};
