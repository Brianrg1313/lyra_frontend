import 'dart:convert';

/// A field (a column) of a table, as described by
/// `GET /inventory/products/builder/structure/<table_id>`.
///
/// It carries six things used at different moments: the [id] (the FIELD_ID,
/// the field's public UUID) is the key data is saved under in
/// `POST /inventory/products/records/manage/`; the [name] is the header the
/// user sees in the field row; the [type] (the type code: `TITLE`, `PRICE`,
/// `STOCK`...) decides which editor the cell loads with and how it's
/// aligned; the [width] is how wide the column measures on screen; the
/// [options] are the list of an `OPTIONS` or `CATEGORIES` field; and the
/// [unit] is the symbol its numbers are written with when the type doesn't
/// carry one.
class TableFieldModel {
  const TableFieldModel({
    required this.id,
    required this.name,
    this.type = "",
    this.width = 0,
    this.options = const [],
    this.unit = ""
  });

  /// FIELD_ID: the field's public UUID. Empty only if the response doesn't
  /// bring it, in which case the column shows but nothing can be saved to
  /// it.
  final String id;

  /// Visible header of the column.
  final String name;

  /// The field's type code (`TITLE`, `PRICE`, ...), or empty if none came.
  final String type;

  /// The column's width on screen, as left by whoever last dragged it, or
  /// `0` if it was never resized (there the sheet's default width takes
  /// over).
  ///
  /// It's a property **of the table** and not of whoever's looking at it:
  /// the structure brings it along with the fields, so everyone in the
  /// business opens the table with the columns at the same size.
  final double width;

  /// The options an `OPTIONS` or `CATEGORIES` field chooses among, in the
  /// order they're offered. Empty in every other type.
  ///
  /// **They belong to the field, not to the business**: two list columns
  /// never share options, and adding one to this one adds nothing to the
  /// other. They come with the structure and not separately because they're
  /// part of the column, like its type or its width: with the same read
  /// that draws the table, any of its lists can already be opened.
  ///
  /// What's saved in the cell is the label itself (one in an `OPTIONS`,
  /// several in a `CATEGORIES`) and not an index into it, so a loaded value
  /// survives its option being removed from this list: it keeps reading
  /// exactly as it was captured.
  final List<String> options;

  /// The symbol the column's numbers are written with: the currency code of
  /// a `PRICE` or a `CURRENCY`, the unit of a `MEASURE` (`USD`, `Bs.`,
  /// `kg`). Empty in every other type.
  ///
  /// **It belongs to the column and not to the value**: a saved amount is a
  /// bare number, and this is what says what currency it's in. That's why
  /// it travels with the structure and not with each record —it would be
  /// the same text repeated in every row— and that's why a column with no
  /// unit isn't an error: a price without one is written in the currency
  /// the business bills in, which is where it came from before columns
  /// could have their own.
  final String unit;

  /// Reads a field. Keys are checked in lowercase (as the structure sends
  /// them) and in uppercase (the creation contract's convention), so
  /// parsing doesn't lock to a single shape.
  factory TableFieldModel.fromJson(Map json) {
    final id = (json["id"] ?? json["ID"] ?? json["field_id"] ?? json["FIELD_ID"])
      ?.toString() ?? "";
    final name = (json["name"] ?? json["NAME"] ?? json["title"] ?? json["TITLE"] ?? "")
      .toString();

    return TableFieldModel(
      id: id,
      // Without a name, the id works as a title before leaving the column blank.
      name: name.isNotEmpty ? name : id,
      type: (json["type"] ?? json["TYPE"] ?? "").toString(),
      width: _width(json["width"] ?? json["WIDTH"]),
      options: _options(json["options"] ?? json["OPTIONS"]),
      unit: (json["unit"] ?? json["UNIT"] ?? "").toString().trim()
    );
  }

  /// The options of a list field. Accepted as a list (the shape the
  /// structure sends them in) and as the JSON text of that list, in case the
  /// backend returns the column undecoded.
  ///
  /// Anything that can't be read is discarded and the field is left with no
  /// options: an odd list leaves the column as an empty list —to which
  /// options can still be added— instead of breaking the table's load.
  static List<String> _options(dynamic raw) {
    if (raw == null) return const [];

    if (raw is String) {
      if (raw.trim().isEmpty) return const [];

      try {
        return _options(jsonDecode(raw));
      } catch (_) {
        return const [];
      }
    }

    if (raw is! List) return const [];

    return [
      for (final option in raw)
        if (option != null && option.toString().trim().isNotEmpty)
          option.toString().trim()
    ];
  }

  /// The column's saved width. A column that was never dragged arrives as
  /// `null`, and anything that can't be read as a valid width —a text, a
  /// zero, a negative— is treated the same way: `0`, which the sheet reads
  /// as "the usual one". That way an odd value leaves the column at its
  /// default width instead of breaking the table's load.
  static double _width(dynamic raw) {
    if (raw == null) return 0;

    final width = raw is num
      ? raw.toDouble()
      : double.tryParse(raw.toString()) ?? 0;

    return width > 0 ? width : 0;
  }
}

/// A table's structure: its header (name, description, color, date, how
/// many records it has) and its fields, as returned by
/// `GET /inventory/products/builder/structure/<table_id>`.
///
/// It's the first of the two phases a table opens with. The structure is
/// requested only once —it doesn't change while navigating through the
/// data— and it's what lets the whole sheet be drawn (the field row and the
/// columns) before the first piece of data arrives. The second phase, the
/// records, is read separately and paginated.
///
/// The fields arrive in the columnar shape (`{"keys": [...], "values":
/// [...]}`) already used by `/init` and `/business/list/`: [keys] names the
/// properties and each row of [values] is a field, aligned by position.
class TableStructureModel {
  const TableStructureModel({
    this.id = "",
    this.name = "",
    this.description = "",
    this.color = "",
    this.date,
    this.records = 0,
    this.fields = const []
  });

  /// The table's UUID.
  final String id;

  /// The table's visible name. It's the screen's title.
  final String name;

  /// Empty when the table was created without a description (it's optional
  /// at creation).
  final String description;

  /// ARGB literal the table is visually identified with (`0xFF2196F3`),
  /// exactly as it travels to the backend. Empty if none came.
  final String color;

  /// Creation date, or `null` if none came or it couldn't be read.
  final DateTime? date;

  /// How many records the table has in total, not in the page currently
  /// being viewed.
  final int records;

  /// The table's columns, in the order they're shown.
  final List<TableFieldModel> fields;

  /// `true` while the structure is still unloaded: a table always has an id.
  bool get isEmpty => id.isEmpty;

  /// Decodes the structure without locking to a single format: fields are
  /// accepted in the contract's columnar shape and also as a list of
  /// objects, in case the backend changes shape.
  factory TableStructureModel.fromResponse(dynamic data) {
    if (data is! Map) return const TableStructureModel();

    // Some endpoints wrap the response in a key: go down one level before
    // giving up.
    if (data["id"] == null && data["ID"] == null) {
      final inner = data["data"] ?? data["table"] ?? data["structure"];
      if (inner is Map) return TableStructureModel.fromResponse(inner);
    }

    final records = data["records"] ?? data["RECORDS"] ?? data["count"];

    return TableStructureModel(
      id: (data["id"] ?? data["ID"] ?? data["table_id"])?.toString() ?? "",
      name: (data["name"] ?? data["NAME"] ?? data["title"] ?? data["TITLE"] ?? "")
        .toString(),
      description: (data["description"] ?? data["DESCRIPTION"] ?? "").toString(),
      color: (data["color"] ?? data["COLOR"] ?? "").toString(),
      date: _date(data["date"] ?? data["DATE"] ?? data["created_at"]),
      records: records is num
        ? records.toInt()
        : int.tryParse(records?.toString() ?? "") ?? 0,
      fields: _fields(data["fields"] ?? data["FIELDS"] ?? data["keys"])
    );
  }

  /// Reads the fields in either of their two shapes: the contract's
  /// columnar table or a list of objects.
  static List<TableFieldModel> _fields(dynamic raw) {
    if (raw is Map) {
      final keys = raw["keys"] ?? raw["KEYS"];
      final values = raw["values"] ?? raw["VALUES"];

      if (keys is List && values is List) {
        return [
          for (final row in values)
            if (row is List)
              TableFieldModel.fromJson({
                for (int i = 0; i < keys.length && i < row.length; i++)
                  keys[i].toString(): row[i]
              })
            // Just in case the row already comes as an object.
            else if (row is Map)
              TableFieldModel.fromJson(row)
        ];
      }

      return const [];
    }

    if (raw is List) {
      return [
        for (final field in raw)
          if (field is Map)
            TableFieldModel.fromJson(field)
          // A bare field only gives the name: it's still shown, though
          // without an id nothing can be saved to it.
          else if (field != null)
            TableFieldModel(id: "", name: field.toString())
      ];
    }

    return const [];
  }

  /// The date arrives in ISO 8601 (`2026-07-14T10:32:11.000Z`). An
  /// unreadable date doesn't break the table's load: it's discarded and the
  /// structure is used all the same.
  static DateTime? _date(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }
}