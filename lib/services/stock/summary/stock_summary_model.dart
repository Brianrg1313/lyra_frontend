import 'package:flutter/foundation.dart';

import 'package:app/services/inventory/product_image.dart';
import 'package:app/services/inventory/table_field_type.dart';

/// A column of the stock summary, as described by
/// `POST /inventory/stock/summary/`.
///
/// The summary row is **half fixed and half the company's**:
///
/// ```
/// image | ...the columns the company left in the summary... | stock | reserved | performance
/// ```
///
/// The photo opens the row because it is how a person recognizes a product, and
/// the three numbers close it because they are the question this list answers.
/// In the middle go the table's own columns —the ones that have their summary
/// mark turned on— in the order the company arranged them.
///
/// The four fixed ones are distinguished by [key]: they are words (`image`,
/// `stock`, `reserved`, `performance`) and the company's are UUIDs, so one can
/// never be confused with the other. The backend also sends [fixed], and it is
/// read from there when it comes.
class StockSummaryColumn {
  const StockSummaryColumn({
    required this.key,
    this.name = "",
    this.type = TableFieldType.text,
    this.width,
    this.options = const [],
    this.unit = "",
    this.fixed = false
  });

  /// Key of the photo column, always the first of the row.
  static const String imageKey = "image";

  /// Key of what is left to sell.
  static const String stockKey = "stock";

  /// Key of what is reserved for someone.
  static const String reservedKey = "reserved";

  /// Key of the indicator of how well it sells. It is not measured yet: the
  /// column exists and its value is null.
  /// What another branch sent here and nobody has counted in yet: in no balance, so it can't
  /// be sold anywhere until it is received.
  static const String transitKey = "transit";

  static const String performanceKey = "performance";

  /// By what the column is identified within the row: the field's UUID if it
  /// belongs to the table, or one of the four fixed words.
  final String key;

  /// Header, as the company named it.
  ///
  /// Empty in a fixed column that has nothing behind it (`reserved`,
  /// `performance`, and `stock` in a table without a stock column): the backend
  /// sends it null on purpose and the name is put by this app, in its language.
  final String name;

  /// With what the value is drawn.
  final TableFieldType type;

  /// How wide the column ended up in the sheet, or null if nobody touched it.
  /// Here it is not used as a measure but as a distribution: it is what gives a
  /// description more room than a code.
  final double? width;

  /// The options of a list-type column, empty in the rest.
  final List<String> options;

  /// The symbol with which the column's numbers are written: the currency code
  /// of an amount, the magnitude of a measure. Empty in the rest, and also in
  /// an amount that never declared its own —there it is written with the
  /// company's currency, which is the one this list resolves once for all its
  /// rows.
  final String unit;

  /// Whether it is one of the four that this list always shows.
  final bool fixed;

  bool get isImage => key == imageKey;
  bool get isStock => key == stockKey;
  bool get isReserved => key == reservedKey;
  bool get isTransit => key == transitKey;
  bool get isPerformance => key == performanceKey;

  /// Whether it is one of the three numbers that close the row. They are drawn
  /// differently than the rest —narrow, right-aligned— because they are for
  /// comparing top to bottom, not for reading.
  bool get isNumber => isStock || isReserved || isTransit || isPerformance;

  /// Whether the summary can be ordered by it (`stock.md` ST-35): any of the company's
  /// columns but the photo, and `stock` only when a stock column of the table is behind
  /// it — which is what its [name] says (ST-32): the backend orders by what the record
  /// stores, and only that column mirrors the balance into it. `reserved` and
  /// `performance` have nothing stored to order by.
  bool get sortable => isStock ? name.isNotEmpty : !isImage && !isNumber;

  factory StockSummaryColumn.fromJson(Map json) {
    final key = (json["key"] ?? json["KEY"] ?? "").toString();
    final name = (json["name"] ?? json["NAME"])?.toString() ?? "";

    return StockSummaryColumn(
      key: key,
      name: name,
      type: TableFieldType.from(json["type"] ?? json["TYPE"]),
      width: _width(json["width"] ?? json["WIDTH"]),
      options: _options(json["options"] ?? json["OPTIONS"]),
      unit: (json["unit"] ?? json["UNIT"] ?? "").toString().trim(),
      // Without the data, the four words are enough to recognize them: any
      // column of a table is a UUID.
      fixed: json["fixed"] ?? json["FIXED"] ?? _fixed.contains(key)
    );
  }

  static const Set<String> _fixed = {
    imageKey, stockKey, reservedKey, transitKey, performanceKey
  };

  /// The stored width as a number. MySQL returns an INT as text quite often,
  /// so it is read both ways.
  static double? _width(dynamic raw) => switch (raw) {
    final num value => value.toDouble(),
    final String text => double.tryParse(text),
    _ => null
  };

  static List<String> _options(dynamic raw) => raw is List
    ? [for (final option in raw) option.toString()]
    : const [];
}

/// What the summary is ordered by: one column, one way (`stock.md` ST-35). Without one
/// the backend's own order holds.
@immutable
class StockSummarySort {
  const StockSummarySort(this.key, {this.descending = false});

  /// The column's [StockSummaryColumn.key].
  final String key;

  final bool descending;

  /// What a click on [column]'s title leaves after [current]: three steps per column,
  /// from its largest value down, then from its smallest up, then no order (the
  /// backend's own, as if it had never been ordered). Another column starts over from
  /// the first step.
  static StockSummarySort? after(StockSummarySort? current, String column) {
    if (current == null || current.key != column) return StockSummarySort(column, descending: true);
    if (current.descending) return StockSummarySort(column);
    return null;
  }

  @override
  bool operator ==(Object other) =>
    other is StockSummarySort && other.key == key && other.descending == descending;

  @override
  int get hashCode => Object.hash(key, descending);
}

/// A row of the summary: a product.
///
/// The values go by column key and not by position —the opposite of the
/// sheet— because the middle columns are whichever the company left and can
/// change from one read to the next (someone turns one on or off from the
/// table's settings). With the keys, a response with the columns moved is still
/// drawn well.
class StockSummaryRow {
  const StockSummaryRow({required this.id, required this.values});

  /// Identifier of the record. It travels beside the data (`keys: ["id",
  /// ...]`) and is not shown.
  final String id;

  final Map<String, dynamic> values;

  /// The value of a column, or null if the row does not bring it.
  dynamic operator [](String key) => values[key];

  /// The same row with the two inventory numbers rewritten.
  ///
  /// It is what runs after a movement: the backend answers the product's whole
  /// balance, so the page does not have to be reread for the row to tell the
  /// truth. It returns a new row and does not touch the one that was there
  /// because the list compares instances to know what to repaint.
  StockSummaryRow withBalance({required int stock, required int reserved}) =>
    StockSummaryRow(id: id, values: {
      ...values,
      StockSummaryColumn.stockKey: stock,
      StockSummaryColumn.reservedKey: reserved
    });

  /// The product's cover, or null if it does not have one.
  ///
  /// The `image` column does not bring what the cell stores but the already
  /// resolved photo (`{ id, scope, url }` for one of ours, `{ id: null, url }`
  /// for the address an import left), so it is read from there and not with
  /// [ProductImage.from], which expects what was stored.
  ProductImage? get cover {
    final raw = values[StockSummaryColumn.imageKey];
    if (raw == null) return null;

    final images = ProductImage.from(
      raw is Map ? (raw["id"] ?? raw["url"] ?? raw["URL"]) : raw
    );

    return images.isEmpty ? null : images.first;
  }

  /// How much of this product there is, or null when the table does not count
  /// stock.
  ///
  /// Null and zero are opposite answers: zero is "there is nothing left" and
  /// null is "nobody is counting it" (the table has no stock column). That is
  /// why one is not collapsed into the other.
  int? get stock => _int(values[StockSummaryColumn.stockKey]);

  /// How much of what there is is set aside for someone, or null if it is not
  /// counted.
  int? get reserved => _int(values[StockSummaryColumn.reservedKey]);

  /// What is on its way here from another branch, or null if the answer doesn't say.
  int? get transit => _int(values[StockSummaryColumn.transitKey]);

  static int? _int(dynamic raw) => switch (raw) {
    final num value => value.toInt(),
    final String text => int.tryParse(text),
    _ => null
  };
}

/// A page of the stock summary: the columns with which it is drawn and the
/// rows of that batch.
///
/// The read is paginated, so this is a batch and not the whole summary; the one
/// that paginates is `StockSummaryService`.
class StockSummaryPage {
  const StockSummaryPage({
    this.table = "",
    this.total = 0,
    this.page = 1,
    this.size = 0,
    this.columns = const [],
    this.rows = const []
  });

  /// The table that was summarized. **It is not asked for**: the backend
  /// answers for the company's primary table (`tables`.`primary`) and says
  /// which one it was. It is what lets this app open it without having chosen
  /// any.
  final String table;

  /// How many products there are in total, not how many came in this page. It
  /// is what the list measures and what tells when to stop asking for more.
  final int total;

  final int page;
  final int size;

  final List<StockSummaryColumn> columns;
  final List<StockSummaryRow> rows;

  /// Whether the response brings no columns either: it is not an empty summary
  /// (that is zero rows) but a read that was not understood.
  bool get isEmpty => columns.isEmpty;

  /// Decodes `{ table, total, page, size, columns, data }`, with the rows
  /// compressed in `{ keys, values }` —`keys` is `["id", ...the column keys]`,
  /// so the key is not repeated in each row—.
  factory StockSummaryPage.fromResponse(dynamic data) {
    if (data is! Map) return const StockSummaryPage();

    final columns = [
      for (final column in data["columns"] ?? data["COLUMNS"] ?? const [])
        if (column is Map) StockSummaryColumn.fromJson(column)
    ];

    return StockSummaryPage(
      table: (data["table"] ?? data["TABLE"] ?? "").toString(),
      total: _int(data["total"] ?? data["TOTAL"]) ?? 0,
      page: _int(data["page"] ?? data["PAGE"]) ?? 1,
      size: _int(data["size"] ?? data["SIZE"]) ?? 0,
      columns: columns,
      rows: _rows(data["data"] ?? data["rows"] ?? data["DATA"])
    );
  }

  static List<StockSummaryRow> _rows(dynamic raw) {
    if (raw is! Map) return const [];

    final keys = raw["keys"] ?? raw["KEYS"];
    final values = raw["values"] ?? raw["VALUES"];

    if (keys is! List || values is! List) return const [];

    // The first key is the record's id: it travels with the data but is not one
    // of them, so it comes out of the values map and goes separately.
    return [
      for (final row in values)
        if (row is List)
          StockSummaryRow(
            id: (row.isEmpty ? "" : row.first)?.toString() ?? "",
            values: {
              for (int i = 1; i < keys.length && i < row.length; i++)
                keys[i].toString(): row[i]
            }
          )
    ];
  }

  static int? _int(dynamic raw) => switch (raw) {
    final num value => value.toInt(),
    final String text => int.tryParse(text),
    _ => null
  };
}
