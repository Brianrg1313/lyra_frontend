import 'package:app/services/kitchen/kitchen_report_model.dart';
import 'package:app/services/kitchen/made_consumes_model.dart';
import 'package:app/services/stock/tables/table_structure_model.dart';

/// A column of a table, as described by a page of
/// `POST /inventory/products/records/list/`.
///
/// It carries three things used at different moments: the [id] (the
/// FIELD_ID, the field's public UUID) is the key data is saved under in
/// `POST /inventory/products/records/manage/`; the [name] is the header the
/// user sees; and the [type] (the type code: `TEXT`, `PRICE`, `NUMBER`...)
/// decides which editor the cell loads with.
class TableColumnModel {
  const TableColumnModel({
    required this.id,
    required this.name,
    this.type = ""
  });

  /// FIELD_ID: the field's public UUID. Empty only if the response doesn't
  /// bring it, in which case the column can't be saved.
  final String id;

  /// Visible header.
  final String name;

  /// The field's type code (`TEXT`, `PRICE`, ...), or empty if none came.
  final String type;
}

/// A row of data. Values go in the same order as
/// [TableViewModel.columns], so they're read by position.
class TableRowModel {
  const TableRowModel(this.values, {this.id = "", this.unit = ""});

  final List<dynamic> values;

  /// The record's identifier, which travels outside the fields: it's the
  /// first column of the page (`keys: ["id", <field_id>, ...]`) and isn't
  /// shown.
  ///
  /// It's what makes an already-saved row editable: without it it can be
  /// read, but there's no record to send the change to. Empty in the rows of
  /// a response that doesn't bring it.
  final String id;

  /// What this product's stock is counted in when it is not its stock column's
  /// (`PUT /inventory/units`, the page's `units`). Empty: the column's, the table's default.
  final String unit;

  /// The cell's value at column [index], or `null` if the row is shorter.
  dynamic at(int index) =>
    index >= 0 && index < values.length ? values[index] : null;

  /// The same row with a different value at [index].
  ///
  /// It's copied instead of overwritten because rows are compared by
  /// identity to decide what gets repainted: a new row is the signal that
  /// that cell changed. A row shorter than [index] is padded with empties,
  /// which is the case for a just-created column that has nothing in it yet.
  TableRowModel withValue(int index, dynamic value) {
    if (index < 0) return this;

    final next = List<dynamic>.of(values);
    while (next.length <= index) {
      next.add(null);
    }
    next[index] = value;

    return TableRowModel(next, id: id, unit: unit);
  }

  /// The same row counted in [unit] (empty: its column's). A new row, like [withValue].
  TableRowModel withUnit(String unit) => TableRowModel(values, id: id, unit: unit);
}

/// A page of a table's data: the headers (the columns, with their FIELD_ID)
/// and that page's rows. It's what `DataTableView` from `core/tables` paints.
///
/// The read is paginated (`POST /inventory/products/records/list/`), so each
/// [TableViewModel] is only a stretch of the table, not the whole thing;
/// [TableViewService] is what paginates.
class TableViewModel {
  const TableViewModel({
    this.columns = const [],
    this.rows = const [],
    this.consumes = const {},
    this.costs = const {},
    this.units = const {}
  });

  final List<TableColumnModel> columns;
  final List<TableRowModel> rows;

  /// A `made` table's page: what each record consumes and how many can be sold now, by
  /// record id (`cocina-frontend.md` §3). Empty on any other table.
  final Map<String, MadeConsumes> consumes;

  /// A `made` table's page, to whoever may read the kitchen's reports: what each record costs
  /// to make and what its price leaves, by record id (`cocina-frontend.md` §9). Empty otherwise.
  final Map<String, DishCost> costs;

  /// What each product that does not count in its stock column's unit is counted in, by
  /// record id (`records/list` `units`). [alignedTo] puts each on its row ([TableRowModel.unit]).
  final Map<String, String> units;

  bool get isEmpty => rows.isEmpty;

  /// Returns this page reordered against the structure's columns.
  ///
  /// The structure, loaded earlier and only once, is what decides the
  /// columns; the page only contributes the values. Since each page brings
  /// its own headers, its values are rearranged to the structure's order by
  /// looking up each field by FIELD_ID (and, if the page doesn't bring it, by
  /// name), so a column's cell always shows that column's data even when the
  /// two responses don't agree on order.
  ///
  /// A field the page doesn't bring stays `null`, which shows as an empty
  /// cell. If the page brings no headers, positional order is kept: it's the
  /// only thing that can be assumed.
  ///
  /// The same pass produces each record's id ([_idPosition]), which is the
  /// column that **isn't** any field's: it isn't shown, but it's what later
  /// lets the row be edited.
  TableViewModel alignedTo(List<TableFieldModel> fields) {
    if (fields.isEmpty) return this;

    final structure = [
      for (final field in fields)
        TableColumnModel(id: field.id, name: field.name, type: field.type)
    ];

    if (columns.isEmpty) return TableViewModel(columns: structure, rows: rows, consumes: consumes, costs: costs, units: units);

    final order = [for (final field in fields) _positionOf(field)];
    final identifier = _idPosition(order);

    return TableViewModel(
      columns: structure,
      rows: [
        for (final row in rows)
          _aligned(row, order, identifier < 0 ? "" : row.at(identifier)?.toString() ?? "")
      ],
      consumes: consumes,
      costs: costs,
      units: units
    );
  }

  TableRowModel _aligned(TableRowModel row, List<int> order, String id) {
    return TableRowModel(
      [
        for (final position in order)
          position < 0 ? null : row.at(position)
      ],
      id: id,
      unit: units[id] ?? ""
    );
  }

  /// Which of the page's headers is the record's id, or `-1` if it can't be
  /// told apart.
  ///
  /// Only searched among the columns that didn't end up matched to any field
  /// ([used]): the id travels alongside the data but isn't one of the
  /// fields, and a field named "id" is a field like any other. Of those, the
  /// one named like an identifier is picked, and if none is, the page's
  /// first one, which is where the contract puts it.
  int _idPosition(List<int> used) {
    int? first;

    for (final (index, column) in columns.indexed) {
      if (used.contains(index)) continue;

      final name = column.name.toUpperCase();
      if (name == "ID" || name.endsWith("_ID")) return index;

      first ??= index;
    }

    return first == 0 ? 0 : -1;
  }

  /// The position [field] occupies in this page's headers, or `-1` if the
  /// page doesn't bring it.
  int _positionOf(TableFieldModel field) {
    if (field.id.isNotEmpty) {
      final byId = columns.indexWhere((column) => column.id == field.id);
      if (byId >= 0) return byId;

      // The contract sends bare headers as the FIELD_IDs themselves
      // (`keys: ["id", <field_id>, ...]`), so there the column's "name" is
      // its id: the first column, the record's id, doesn't match any field
      // and so isn't shown.
      final byKey = columns.indexWhere(
        (column) => column.id.isEmpty && column.name == field.id
      );
      if (byKey >= 0) return byKey;
    }

    // Without a FIELD_ID on the page, the name is the only thing left to
    // match them by.
    return columns.indexWhere(
      (column) => column.id.isEmpty && column.name == field.name
    );
  }

  /// Decodes a page without locking to a single format: it accepts the
  /// columnar table (`{"keys": [...], "values": [...]}`) already used by
  /// `/init` and `/business/list/`, a list of objects, or either of those two
  /// wrapped in a key. That way parsing doesn't break if the backend changes
  /// shape.
  ///
  /// In the columnar format each header (`keys[i]`) can come as an object
  /// with the FIELD_ID, the name and the type, or as bare text (in which case
  /// only the name is known). Rows (`values`) are aligned by position with the
  /// headers.
  ///
  /// [tableId] names the table a made page's `consumes` belong to.
  factory TableViewModel.fromResponse(dynamic data, {String tableId = ""}) {
    if (data is Map) {
      final keys = data["keys"] ?? data["columns"] ?? data["fields"];
      final values = data["values"] ?? data["rows"];

      if (keys is List && values is List) {
        final columns = [for (final key in keys) _column(key)];

        return TableViewModel(
          consumes: MadeConsumes.mapFrom(data["consumes"], tableId: tableId),
          costs: DishCost.mapFrom(data["costs"]),
          units: _units(data["units"]),
          columns: columns,
          rows: [
            for (final row in values)
              if (row is List)
                TableRowModel(List<dynamic>.of(row))
              // Just in case the row comes as an object: it's ordered
              // against the columns, looking up the value by FIELD_ID and,
              // failing that, by name.
              else if (row is Map)
                TableRowModel([
                  for (final column in columns)
                    row[column.id] ?? row[column.name]
                ])
          ]
        );
      }

      // Some endpoints wrap the page (and its pagination metadata) in a key:
      // go down one level to find the data.
      final inner = data["data"] ?? data["results"] ?? data["table"] ?? data["page"];
      if (inner is List || inner is Map) {
        final page = TableViewModel.fromResponse(inner, tableId: tableId);
        if (data["consumes"] == null && data["costs"] == null && data["units"] == null) return page;

        return TableViewModel(
          columns: page.columns,
          rows: page.rows,
          consumes: page.consumes.isNotEmpty ? page.consumes : MadeConsumes.mapFrom(data["consumes"], tableId: tableId),
          costs: page.costs.isNotEmpty ? page.costs : DishCost.mapFrom(data["costs"]),
          units: page.units.isNotEmpty ? page.units : _units(data["units"])
        );
      }
    }

    // List of objects: each row is a map. Columns come from the first row
    // (with no FIELD_ID, since that format doesn't bring one) and the order
    // is the JSON's.
    if (data is List) {
      final maps = [for (final row in data) if (row is Map) row];
      if (maps.isEmpty) return const TableViewModel();

      final columns = [
        for (final key in maps.first.keys)
          TableColumnModel(id: "", name: key.toString())
      ];

      return TableViewModel(
        columns: columns,
        rows: [
          for (final row in maps)
            TableRowModel([for (final column in columns) row[column.name]])
        ]
      );
    }

    return const TableViewModel();
  }

  /// Reads a header in either of its two forms: an object with the FIELD_ID,
  /// the name and the type, or bare text that only gives the name. Keys are
  /// checked in uppercase (the contract) and lowercase (a common reading) just
  /// in case.
  /// `units` as the page sends it: `{ <record id>: unit }`, only the products that have one.
  static Map<String, String> _units(dynamic data) => data is Map
    ? {
        for (final MapEntry(:key, :value) in data.entries)
          if (value is String && value.trim().isNotEmpty) "$key": value.trim()
      }
    : const {};

  static TableColumnModel _column(dynamic key) {
    if (key is Map) {
      final id = (key["ID"] ?? key["id"] ?? key["FIELD_ID"] ?? key["field_id"] ?? key["uuid"])?.toString() ?? "";
      final name = (key["NAME"] ?? key["name"] ?? key["TITLE"] ?? key["title"] ?? "").toString();

      return TableColumnModel(
        id: id,
        // Without a name, the id works as a header before leaving the
        // column blank.
        name: name.isNotEmpty ? name : id,
        type: (key["TYPE"] ?? key["type"] ?? "").toString()
      );
    }

    return TableColumnModel(id: "", name: key?.toString() ?? "");
  }
}
