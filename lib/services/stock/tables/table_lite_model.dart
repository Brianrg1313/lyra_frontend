/// A product table as returned by `GET /inventory/products/builder/list/`,
/// but only with what's needed to draw the listing: the identifier, the
/// title, the description, and how big it is (how many columns and how many
/// records).
///
/// It's the "lite" version on purpose: the full structure (each field's
/// detail, its type and its order) isn't needed to list a business's tables,
/// so it isn't loaded until one is opened. Only what shows in the row goes
/// in here.
class TableLiteModel {
  final String id;
  final String title;

  /// Empty when the table was created without a description (it's optional
  /// at creation).
  final String description;

  /// How many columns the table has. Shown as a quick reference of how big
  /// it is without having to open it.
  final int fields;

  /// How many records are loaded in the table.
  ///
  /// It's `null` —not zero— when the backend couldn't count them: the rows
  /// live in a different store than the columns, so the count can fail on
  /// its own. A table whose records couldn't be counted isn't an empty
  /// table, and the list would rather say nothing than say it's empty.
  final int? records;

  /// Whether it's the business's **primary** table (`tables`.`primary`).
  ///
  /// There's only one and the backend marks it: the first one created,
  /// unless it was changed. It matters outside this list because it's the
  /// one the stock summary reads without anyone choosing it (see
  /// `StockSummaryService`), so switching a column of this table on or off
  /// is what shows up below.
  final bool primary;

  /// Flutter ARGB literal (`0xFF2196F3`) the table is tinted with, or empty.
  final String color;

  const TableLiteModel({
    required this.id,
    required this.title,
    this.description = "",
    this.fields = 0,
    this.records,
    this.primary = false,
    this.color = ""
  });

  /// Reads a row. Keys are checked in both conventions the backend can send
  /// —the creation contract's uppercase (`TITLE`, `FIELDS`) and a read's
  /// usual lowercase— so parsing doesn't lock to a single shape.
  factory TableLiteModel.fromJson(Map json) => TableLiteModel(
    id: (json["id"] ?? json["ID"] ?? json["table_id"])?.toString() ?? "",
    title: json["TITLE"] ?? json["title"] ?? json["name"] ?? "",
    description: json["DESCRIPTION"] ?? json["description"] ?? "",
    fields: _count(
      json["FIELDS"] ?? json["fields"] ??
      json["fields_count"] ?? json["field_count"]
    ) ?? 0,
    records: _count(
      json["RECORDS"] ?? json["records"] ??
      json["records_count"] ?? json["record_count"]
    ),
    primary: _primary(
      json["PRIMARY"] ?? json["primary"] ?? json["is_primary"]
    ),
    color: (json["COLOR"] ?? json["color"])?.toString() ?? ""
  );

  /// Whether the row comes marked as the primary one.
  ///
  /// Unlike other flags, what isn't understood reads as **no**: there's only
  /// one primary table, and two tables both claiming the summary is theirs
  /// is worse than none. Without the data nothing is marked either, which
  /// is exactly what's known.
  static bool _primary(dynamic value) => switch (value) {
    final bool flag => flag,
    final num number => number != 0,
    final String text => switch (text.trim().toLowerCase()) {
      "1" || "true" || "yes" => true,
      _ => false
    },
    _ => false
  };

  /// Reads a count from the response.
  ///
  /// It can arrive already counted (a number, or the text of one) or as the
  /// whole list of which only the length matters —that's how fields arrive
  /// when the full structure is read—. Anything that's neither of those two
  /// (including not coming at all) reads as "unknown", which is different
  /// from zero: whoever uses it decides what to do with that.
  static int? _count(dynamic value) => switch (value) {
    final List list => list.length,
    final num number => number.toInt(),
    final String text => int.tryParse(text),
    _ => null
  };

  /// Copies the table with its texts changed. Used by the list to reflect an
  /// edit without requesting everything from the backend again: the only
  /// things edited from there are the title and the description, and the
  /// counts stay the same.
  TableLiteModel withText({String? title, String? description}) =>
    TableLiteModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      fields: fields,
      records: records,
      primary: primary,
      color: color
    );

  /// Decodes the list's response without locking to a single format: it
  /// accepts both a list of objects and the columnar table
  /// (`{"keys": [...], "values": [...]}`) already used by `/init` and
  /// `/business/list/`. That way parsing doesn't break if the backend
  /// changes shape.
  static List<TableLiteModel> fromResponse(dynamic data) {
    if (data is List) {
      return [
        for (final row in data)
          if (row is Map) TableLiteModel.fromJson(row)
      ];
    }

    if (data is Map) {
      // Some endpoints wrap the list in a key.
      final inner = data["tables"] ?? data["results"] ?? data["data"];
      if (inner != null && inner is! Map) return fromResponse(inner);

      final keys = data["keys"];
      final rows = data["values"];

      if (keys is List && rows is List) {
        return [
          for (final row in rows)
            if (row is List)
              TableLiteModel.fromJson({
                for (int i = 0; i < keys.length && i < row.length; i++)
                  keys[i].toString(): row[i]
              })
        ];
      }
    }

    return const [];
  }
}