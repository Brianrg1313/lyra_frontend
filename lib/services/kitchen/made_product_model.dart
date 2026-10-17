import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/inventory/table_field_type.dart';
import 'package:app/services/kitchen/kitchen_read.dart';
import 'package:app/services/kitchen/made_consumes_model.dart';
import 'package:app/services/stock/tables/table_structure_model.dart';
import 'package:app/services/stock/tables/table_view_model.dart';

/// Which columns of a `made` table a product's form writes: its name, its price and the rest of
/// what can be typed in a field. A made product is a form, not a row (`cocina-frontend.md` §2:
/// «sus columnas + Consume»), so a column that is a picture, a count the backend keeps or a list
/// of several values is left to the table itself.
@immutable
class MadeFields {
  const MadeFields({this.name, this.price, this.others = const []});

  /// The column that names the product: the first `TITLE`, else the first plain text. `null`
  /// in a table with neither, where saving the first product creates it.
  final TableFieldModel? name;

  /// The first `PRICE`; `null` until saving the first product creates it.
  final TableFieldModel? price;

  /// The other columns typed in a field, in the table's order.
  final List<TableFieldModel> others;

  /// What a form can write in a field: text, numbers and one option of a list.
  static const Set<TableFieldType> typed = {
    TableFieldType.text, TableFieldType.textarea, TableFieldType.title, TableFieldType.description,
    TableFieldType.sku, TableFieldType.barcode, TableFieldType.number, TableFieldType.decimal,
    TableFieldType.price, TableFieldType.currency, TableFieldType.discount, TableFieldType.percentage,
    TableFieldType.measure, TableFieldType.email, TableFieldType.phone, TableFieldType.url,
    TableFieldType.options
  };

  factory MadeFields.of(List<TableFieldModel> fields) {
    TableFieldType type(TableFieldModel field) => TableFieldType.from(field.type);

    final name = fields.where((field) => type(field) == TableFieldType.title).firstOrNull
      ?? fields.where((field) => type(field) == TableFieldType.text).firstOrNull;
    final price = fields.where((field) => type(field) == TableFieldType.price).firstOrNull;

    return MadeFields(
      name: name,
      price: price,
      others: [
        for (final field in fields)
          if (field != name && field != price && field.id.isNotEmpty && typed.contains(type(field))) field
      ]
    );
  }
}

/// One product of a `made` table as its list and its form read it: its values by FIELD_ID and
/// what it consumes, from the same `records/list` page (`consumes`, `cocina-frontend.md` §3).
@immutable
class MadeProduct {
  const MadeProduct({required this.id, this.values = const {}, this.consumes});

  final String id;

  /// What the record holds, by FIELD_ID, as text.
  final Map<String, String> values;

  /// `null` when the page did not say it (a product written elsewhere, a read cut short).
  final MadeConsumes? consumes;

  String valueOf(TableFieldModel? field) => field == null ? "" : values[field.id] ?? "";

  /// The rows of an aligned [page] (its columns are the structure's).
  static List<MadeProduct> listFrom(TableViewModel page) => [
    for (final row in page.rows)
      if (row.id.isNotEmpty) MadeProduct(
        id: row.id,
        values: {
          for (final (index, column) in page.columns.indexed)
            if (column.id.isNotEmpty && row.at(index) != null) column.id: kitchenText(row.at(index))
        },
        consumes: page.consumes[row.id]
      )
  ];
}
