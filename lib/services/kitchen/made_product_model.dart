import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/inventory/product_image.dart';
import 'package:app/services/inventory/table_field_type.dart';
import 'package:app/services/kitchen/kitchen_read.dart';
import 'package:app/services/kitchen/kitchen_report_model.dart';
import 'package:app/services/kitchen/made_consumes_model.dart';
import 'package:app/services/stock/tables/table_structure_model.dart';
import 'package:app/services/stock/tables/table_view_model.dart';

/// Which columns of a `made` table a product's form writes: its name, its price, its photo, its
/// description and the rest of what can be typed in a field. A made product is a form, not a row
/// (`cocina-frontend.md` §2: «sus columnas + Consume»), so a count the backend keeps or a list of
/// several values is left to the table itself.
@immutable
class MadeFields {
  const MadeFields({this.name, this.price, this.image, this.description, this.others = const []});

  /// The column that names the product: the first `TITLE`, else the first plain text. `null`
  /// in a table with neither, where saving the first product creates it.
  final TableFieldModel? name;

  /// The first `PRICE`; `null` until saving the first product creates it.
  final TableFieldModel? price;

  /// The first `IMAGE`: every table opens with one (the backend's `Tables.ensureImage`), and a
  /// photo is uploaded against the record, not written in it.
  final TableFieldModel? image;

  /// The first `DESCRIPTION`, else the first `TEXTAREA`: what the product is, in words (the
  /// first is what Lyra reads by meaning). `null` until a description is written, which
  /// creates it.
  final TableFieldModel? description;

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
    final image = fields.where((field) => type(field) == TableFieldType.image).firstOrNull;
    final description = fields.where((field) => type(field) == TableFieldType.description).firstOrNull
      ?? fields.where((field) => type(field) == TableFieldType.textarea).firstOrNull;

    return MadeFields(
      name: name,
      price: price,
      image: image,
      description: description,
      others: [
        for (final field in fields)
          if (field != name && field != price && field != description && field.id.isNotEmpty && typed.contains(type(field))) field
      ]
    );
  }
}

/// One product of a `made` table as its list and its form read it: its values by FIELD_ID, its
/// photos, what it consumes and what that costs, from the same `records/list` page (`consumes`,
/// `costs`, `cocina-frontend.md` §3, §9).
@immutable
class MadeProduct {
  const MadeProduct({required this.id, this.values = const {}, this.images = const [], this.consumes, this.cost});

  final String id;

  /// What the record holds, by FIELD_ID, as text.
  final Map<String, String> values;

  /// Its image column's gallery, the first one the cover. Read from the raw value: a gallery is
  /// a list, and [values] holds text.
  final List<ProductImage> images;

  /// `null` when the page did not say it (a product written elsewhere, a read cut short).
  final MadeConsumes? consumes;

  /// What making one costs and what its price leaves; `null` when the page did not say it (no
  /// recipe, or a viewer without the kitchen's reports).
  final DishCost? cost;

  /// What its list and its form draw: the first photo there is something of to draw.
  ProductImage? get cover => images.where((image) => !image.isPending).firstOrNull;

  String valueOf(TableFieldModel? field) => field == null ? "" : values[field.id] ?? "";

  /// The rows of an aligned [page] (its columns are the structure's); [image] is the column its
  /// photos are read from.
  static List<MadeProduct> listFrom(TableViewModel page, {TableFieldModel? image}) {
    final slot = image == null ? -1 : page.columns.indexWhere((column) => column.id == image.id);

    return [
      for (final row in page.rows)
        if (row.id.isNotEmpty) MadeProduct(
          id: row.id,
          values: {
            for (final (index, column) in page.columns.indexed)
              if (column.id.isNotEmpty && row.at(index) != null) column.id: kitchenText(row.at(index))
          },
          images: slot < 0 ? const [] : ProductImage.from(row.at(slot)),
          consumes: page.consumes[row.id],
          cost: page.costs[row.id]
        )
    ];
  }
}
