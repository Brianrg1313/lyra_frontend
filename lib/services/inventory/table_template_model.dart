/// A column a starting table comes with, as `GET .../builder/templates/` previews it.
class TableTemplateField {
  const TableTemplateField({required this.name, required this.type});

  final String name;

  /// The backend's `TYPE` code (`title`, `price`, `stock`…), as `TableFieldType` reads it.
  final String type;

  factory TableTemplateField.fromJson(Map json) => TableTemplateField(
    name: json["name"]?.toString() ?? "",
    type: json["type"]?.toString() ?? ""
  );
}

/// A starting table the company can create in one tap: the backend's catalogue
/// (`model:/tables/templates.js`), offered by the company's activity. [id] travels as
/// `TEMPLATE` on creation and the backend builds the columns; [fields] is only the preview.
///
/// The names come from the backend in its language (its own debt, not translated here).
class TableTemplateModel {
  const TableTemplateModel({
    required this.id,
    required this.name,
    this.description = "",
    this.color = "",
    this.fields = const []
  });

  final String id;
  final String name;
  final String description;

  /// Flutter ARGB literal (`0xFFE91E63`), or empty.
  final String color;

  /// In display order, without the picture column every table opens with.
  final List<TableTemplateField> fields;

  factory TableTemplateModel.fromJson(Map json) => TableTemplateModel(
    id: json["id"]?.toString() ?? "",
    name: json["name"]?.toString() ?? "",
    description: json["description"]?.toString() ?? "",
    color: json["color"]?.toString() ?? "",
    fields: [
      for (final field in (json["fields"] is List ? json["fields"] as List : const []))
        if (field is Map) TableTemplateField.fromJson(field)
    ]
  );

  /// The answer's `templates`, compressed (`{keys, values}`) or as a plain list. A row
  /// without an id can't be created and is dropped.
  static List<TableTemplateModel> listFrom(dynamic data) {
    final List<Map> rows;

    if (data is List) {
      rows = [for (final row in data) if (row is Map) row];
    } else if (data is Map && data["keys"] is List && data["values"] is List) {
      final keys = data["keys"] as List;
      rows = [
        for (final row in data["values"] as List)
          if (row is List) {
            for (int i = 0; i < keys.length && i < row.length; i++) keys[i].toString(): row[i]
          }
      ];
    } else {
      rows = const [];
    }

    return [
      for (final row in rows)
        if (TableTemplateModel.fromJson(row) case final template when template.id.isNotEmpty) template
    ];
  }
}
