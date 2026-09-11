import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/inventory/table_field_type.dart';

/// How much the AI model sees of a column.
///
/// There are three states and not a switch because there is a middle ground
/// that gets used all the time: a column the agent can **use** to filter
/// without being able to **say** what it holds. The cost price is the usual
/// example: it's good for picking what to offer and can't go out over
/// WhatsApp.
///
/// The codes are the backend's (`visible` · `declared` · `hidden`) and have to
/// match exactly: it's what travels when the table is read.
enum TableFieldVisibility {
  /// The agent reads its values and can quote them.
  visible,

  /// The agent knows the column exists and filters by it, but never says what
  /// it holds.
  declared,

  /// The agent doesn't know the column exists.
  hidden;

  /// The unknown falls into [visible], which is how a column is born: a
  /// visibility this version doesn't know yet is shown as the most common
  /// state instead of leaving the column without one.
  static TableFieldVisibility from(dynamic raw) =>
    switch (raw?.toString().trim().toLowerCase()) {
      "declared" => declared,
      "hidden" => hidden,
      _ => visible
    };

  /// Code the backend uses. Not translated.
  String get value => name;

  String label(BuildContext context) => switch (this) {
    visible => S.of(context).field_visibility_visible,
    declared => S.of(context).field_visibility_declared,
    hidden => S.of(context).field_visibility_hidden
  };

  /// What the state means, spelled out. The three names look too much alike
  /// to explain themselves, and nobody guesses the middle one.
  String hint(BuildContext context) => switch (this) {
    visible => S.of(context).field_visibility_visible_hint,
    declared => S.of(context).field_visibility_declared_hint,
    hidden => S.of(context).field_visibility_hidden_hint
  };

  IconData get icon => switch (this) {
    visible => CI.eye,
    declared => CI.info,
    hidden => CI.eye_hidden
  };
}

/// A column of the table, as described by
/// `GET /inventory/products/builder/details/<table_id>`.
///
/// It's the same column the sheet draws but told in full: besides its name and
/// type it carries what it's for, where it sits, how much of it the model
/// sees, whether it's in the inventory summary, and its two dates. None of
/// that is needed to paint the grid, which is why it doesn't come with the
/// structure (see `TableFieldModel`).
class TableDetailFieldModel {
  const TableDetailFieldModel({
    required this.id,
    required this.name,
    this.description = "",
    this.position = 0,
    this.type = TableFieldType.text,
    this.options = const [],
    this.unit = "",
    this.visibility = TableFieldVisibility.visible,
    this.summary = true,
    this.date,
    this.updated
  });

  /// FIELD_ID: the column's public UUID.
  final String id;

  /// The column's visible title.
  final String name;

  /// Empty when the column was created without a description, which is the
  /// norm for columns imported from a spreadsheet.
  final String description;

  /// Its position from left to right, starting at zero.
  final int position;

  final TableFieldType type;

  /// The options of a list column, in the order they're offered. Empty in
  /// every other type.
  final List<String> options;

  /// The symbol the column's numbers are written with: the currency code of a
  /// price or an amount, the unit of a measurement (`USD`, `Bs.`, `kg`).
  /// Empty in every other type, and also in a money column that didn't
  /// declare its own: there, the business's billing currency takes over.
  ///
  /// A percentage doesn't carry one: there the unit **is** the type (see
  /// [TableFieldType.united]).
  final String unit;

  final TableFieldVisibility visibility;

  /// Whether the column shows in the **inventory summary**: the short view
  /// that answers "what do we have and how much", as opposed to the full
  /// sheet, which has everything the business ever imported.
  ///
  /// It's a different question from [visibility] and that's why it's a
  /// different field: one says what **the AI** can read, and this one says
  /// what's shown to **a person** at a glance, and the two don't go together.
  /// A cost price is hidden from the agent and is exactly what the owner
  /// wants to see in their summary; a color is `declared` for the agent and
  /// is noise in a summary.
  ///
  /// It's born `true` —a table nobody curated shows the summary it always
  /// showed, the full sheet— so this trims a view rather than emptying one.
  final bool summary;

  /// When the column was created.
  final DateTime? date;

  /// When it was last renamed, had its type changed, was resized, had its
  /// visibility moved, or was taken out of the summary.
  final DateTime? updated;

  /// The same column with a different type, visibility, options, unit, in or
  /// out of the summary, or several of those five.
  ///
  /// It's what lets a change made from the detail view show up as soon as the
  /// backend accepts it, without waiting for the whole thing to be re-read:
  /// what was chosen is already known on this side. `null` means "not
  /// touched", the same as in the body that travels ([editFieldRequest]).
  ///
  /// Options and unit are emptied by passing an empty value (an empty list, an
  /// empty text) and not `null`: it's the same rule the backend follows, where
  /// empty is a value and absence isn't.
  TableDetailFieldModel withEdits({
    TableFieldType? type,
    TableFieldVisibility? visibility,
    List<String>? options,
    String? unit,
    bool? summary
  }) => TableDetailFieldModel(
    id: id,
    name: name,
    description: description,
    position: position,
    type: type ?? this.type,
    options: options ?? this.options,
    unit: unit ?? this.unit,
    visibility: visibility ?? this.visibility,
    summary: summary ?? this.summary,
    date: date,
    updated: updated
  );

  factory TableDetailFieldModel.fromJson(Map json) {
    final name = (json["name"] ?? json["NAME"] ?? "").toString();
    final id = (json["id"] ?? json["ID"] ?? json["field_id"])?.toString() ?? "";

    return TableDetailFieldModel(
      id: id,
      // Without a name, the id works as a title before leaving the row blank.
      name: name.isNotEmpty ? name : id,
      description: (json["description"] ?? json["DESCRIPTION"] ?? "").toString(),
      position: _int(json["position"] ?? json["POSITION"]) ?? 0,
      type: TableFieldType.from(json["type"] ?? json["TYPE"]),
      options: _options(json["options"] ?? json["OPTIONS"]),
      unit: (json["unit"] ?? json["UNIT"] ?? "").toString().trim(),
      visibility: TableFieldVisibility.from(
        json["visibility"] ?? json["VISIBILITY"]
      ),
      summary: _flag(json["summary"] ?? json["SUMMARY"]),
      date: _date(json["date"] ?? json["DATE"]),
      updated: _date(json["updated"] ?? json["UPDATED"])
    );
  }
}

/// How many columns the table has and of what kind.
///
/// The counting is done by the backend over the rows it already has in hand,
/// not by this app over [TableDetailModel.fields]: they're the answer to "how
/// big is this table" and have to be readable without scanning twenty
/// columns.
class TableColumnsSummary {
  const TableColumnsSummary({
    this.total = 0,
    this.types = const {},
    this.visibility = const {},
    this.summary = 0,
    this.untyped = 0
  });

  /// How many columns there are.
  final int total;

  /// How many of each type. A code this version doesn't know falls into
  /// [TableFieldType.text], same as in the sheet.
  final Map<TableFieldType, int> types;

  /// How many of each visibility state.
  final Map<TableFieldVisibility, int> visibility;

  /// How many are in the inventory summary. In a table nobody trimmed, that's
  /// all of them, which is what makes the offer to trim it an honest one.
  final int summary;

  /// How many are still bare text, which is the type every imported column is
  /// born with.
  ///
  /// It's not an error —a table can legitimately be all text— but it's the
  /// difference between a table that answers questions and one that only
  /// stores them, so the screen says so.
  final int untyped;

  factory TableColumnsSummary.fromJson(Map json) {
    // Types are summed instead of assigned: two different codes this version
    // doesn't know both fall into `text`, and the second can't overwrite the
    // first.
    final types = <TableFieldType, int>{};
    final rawTypes = json["types"] ?? json["TYPES"];

    if (rawTypes is Map) {
      for (final entry in rawTypes.entries) {
        final type = TableFieldType.from(entry.key);
        types[type] = (types[type] ?? 0) + (_int(entry.value) ?? 0);
      }
    }

    final visibility = <TableFieldVisibility, int>{};
    final rawVisibility = json["visibility"] ?? json["VISIBILITY"];

    if (rawVisibility is Map) {
      for (final entry in rawVisibility.entries) {
        final state = TableFieldVisibility.from(entry.key);
        visibility[state] = (visibility[state] ?? 0) + (_int(entry.value) ?? 0);
      }
    }

    return TableColumnsSummary(
      total: _int(json["total"] ?? json["TOTAL"]) ?? 0,
      types: types,
      visibility: visibility,
      summary: _int(json["summary"] ?? json["SUMMARY"]) ?? 0,
      untyped: _int(json["untyped"] ?? json["UNTYPED"]) ?? 0
    );
  }

  /// How many columns are in that state.
  int of(TableFieldVisibility state) => visibility[state] ?? 0;

  /// The types present, from most used to least, and at equal count in the
  /// order they're offered when creating a column. It's how they're read:
  /// first what the table is, then the details.
  List<MapEntry<TableFieldType, int>> get sorted {
    final order = TableFieldType.ordered;

    return types.entries.toList()
      ..sort((a, b) {
        final count = b.value.compareTo(a.value);
        if (count != 0) return count;

        return order.indexOf(a.key).compareTo(order.indexOf(b.key));
      });
  }
}

/// What the AI model can do with this table.
///
/// There are four answers that come out of its columns' types and not out of
/// a separate setting: the table enables the agent by what it holds inside.
class TableAgentSummary {
  const TableAgentSummary({
    this.searchable = false,
    this.filterable = 0,
    this.stock = false,
    this.image = false
  });

  /// `true` if it has a column indexed by meaning (`TITLE` or `DESCRIPTION`,
  /// see [TableFieldType.semantic]), which is what lets the agent be asked
  /// about something described in words rather than by an exact value.
  final bool searchable;

  /// How many columns it can filter and sort by: all the ones that aren't
  /// hidden.
  final int filterable;

  /// `true` if a stock column ties it to the inventory engine, which is also
  /// what enables reserving products.
  final bool stock;

  /// `true` if it has an image column, i.e. whether the agent can send photos
  /// of these records.
  final bool image;

  factory TableAgentSummary.fromJson(Map json) => TableAgentSummary(
    searchable: json["searchable"] == true,
    filterable: _int(json["filterable"]) ?? 0,
    stock: json["stock"] == true,
    image: json["image"] == true
  );
}

/// A channel that reads this table.
///
/// It's the bot seen from the table rather than from the channel list: what
/// matters here is its name, which network it answers on, and whether it's
/// working, which is what answers "who is using this data".
class TableChannelReader {
  const TableChannelReader({
    required this.id,
    required this.name,
    this.description = "",
    this.provider = "",
    this.connectionName = "",
    this.scopeName = "",
    this.role = "",
    this.enabled = true,
    this.ready = false
  });

  final String id;
  final String name;
  final String description;

  /// Network code (`whatsapp`, `instagram`, ...). Used to look up the name and
  /// icon in the channel catalog.
  final String provider;

  /// Name the business gave the account it answers through.
  final String connectionName;

  /// What it handles on that account (direct messages, comments), already
  /// resolved to text by the backend.
  final String scopeName;

  /// What role the agent answers with (`seller`, `support`, `agent`).
  final String role;

  /// The business's switch: a paused channel stays connected to the table but
  /// doesn't answer.
  final bool enabled;

  /// `true` when everything its network requires is loaded.
  final bool ready;

  factory TableChannelReader.fromJson(Map json) => TableChannelReader(
    id: (json["id"] ?? json["ID"])?.toString() ?? "",
    name: (json["name"] ?? json["NAME"] ?? "").toString(),
    description: (json["description"] ?? json["DESCRIPTION"] ?? "").toString(),
    provider: (json["provider"] ?? json["PROVIDER"] ?? "").toString(),
    connectionName: (json["connection_name"] ?? "").toString(),
    scopeName: (json["scope_name"] ?? json["scope"] ?? "").toString(),
    role: (json["role"] ?? "").toString(),
    enabled: json["enabled"] != false && json["enabled"] != 0,
    ready: json["ready"] == true
  );

  static List<TableChannelReader> listOf(dynamic raw) => [
    if (raw is List)
      for (final row in raw)
        if (row is Map) TableChannelReader.fromJson(row)
  ];
}

/// How far the table's reach goes: which bots read it and why.
///
/// Two lists come in and not one because they're two different things and
/// only one is a choice. [linked] are the ones that picked this table as a
/// source; [open] are the ones that **configured none at all**, which the
/// runtime reads as "all of the business's" and so read this one too, without
/// anyone having asked for it.
///
/// Showing only the first would be the comfortable answer and the wrong one: a
/// business looking at "not connected to any channel" while a sourceless bot
/// dictates its cost prices over WhatsApp is exactly what this screen exists
/// to prevent.
class TableChannelsSummary {
  const TableChannelsSummary({
    this.reached = false,
    this.linked = const [],
    this.open = const []
  });

  /// `true` if any bot reaches this table, by whatever path.
  final bool reached;

  /// The ones that name this table as a data source.
  final List<TableChannelReader> linked;

  /// The ones that configured no source at all and so read all of them.
  final List<TableChannelReader> open;

  factory TableChannelsSummary.fromJson(Map json) {
    final linked = TableChannelReader.listOf(json["linked"]);
    final open = TableChannelReader.listOf(json["open"]);

    return TableChannelsSummary(
      // Recalculated over what could actually be read instead of taking the
      // backend's boolean as-is: saying the table is reached without being
      // able to show by whom would be an alarm with no explanation.
      reached: json["reached"] == true || linked.isNotEmpty || open.isNotEmpty,
      linked: linked,
      open: open
    );
  }
}

/// Everything worth knowing about a table except its rows, as returned by
/// `GET /inventory/products/builder/details/<table_id>`.
///
/// It's a table's settings screen in a single read, which is why it's a
/// separate endpoint and not a bigger structure: it answers things that live
/// in three different stores —the header and columns in MySQL, how many
/// records there are in Mongo, which bots read it in the business's own
/// database— and is requested every so often. The structure
/// (`/inventory/products/builder/structure/`) stays the cheap read that draws
/// the sheet on every click.
///
/// **There are two dates because the table has two**, and merging them would
/// lose whichever one was being asked about: [updated] is the last
/// **structure** change —the table itself or any of its columns— and
/// [lastRecord] is when the last piece of data came in. A price list imported
/// in March and reloaded this morning has an old [updated] and a [lastRecord]
/// of today.
///
/// [records] is `null` —not zero— when the count couldn't be read: the rows
/// live in a different store than the columns, so it can fail on its own. A
/// table whose records couldn't be counted isn't an empty table, and the
/// difference matters exactly on the screen that offers to delete it.
class TableDetailModel {
  const TableDetailModel({
    this.id = "",
    this.name = "",
    this.description = "",
    this.color = "",
    this.date,
    this.updated,
    this.records,
    this.lastRecord,
    this.columns = const TableColumnsSummary(),
    this.agent = const TableAgentSummary(),
    this.channels = const TableChannelsSummary(),
    this.fields = const []
  });

  /// The table's UUID.
  final String id;

  /// The table's visible name.
  final String name;

  /// Empty when the table was created without a description.
  final String description;

  /// ARGB literal that identifies the table (`0xFF2196F3`), exactly as it
  /// travels to the backend. Empty if none came.
  final String color;

  /// When the table was created.
  final DateTime? date;

  /// The last structure change, whether to the table or to one of its
  /// columns.
  final DateTime? updated;

  /// How many rows it has, or `null` if they couldn't be counted. See the
  /// class note.
  final int? records;

  /// When the last row came in, or `null` if the table is empty (or if the
  /// count couldn't be read).
  final DateTime? lastRecord;

  final TableColumnsSummary columns;
  final TableAgentSummary agent;
  final TableChannelsSummary channels;

  /// The columns, in the order they're shown.
  final List<TableDetailFieldModel> fields;

  /// `true` while the detail is still unloaded: a table always has an id.
  bool get isEmpty => id.isEmpty;

  /// The same detail with a different name, a different description, or both.
  ///
  /// It's what lets a change made from the detail view show up right away:
  /// the write already came back fine and the only thing that changed is the
  /// text just written, so there's no need to wait to re-read all three
  /// stores to show it. Everything else —the counts, the columns, the
  /// channels— a header edit doesn't touch.
  ///
  /// `null` means "not changed", not "emptied", the same as in the body that
  /// travels to the backend: a description is cleared by passing it empty.
  TableDetailModel withText({String? name, String? description}) =>
    TableDetailModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color,
      date: date,
      updated: updated,
      records: records,
      lastRecord: lastRecord,
      columns: columns,
      agent: agent,
      channels: channels,
      fields: fields
    );

  /// The same detail with one of its columns changed.
  ///
  /// Replaces the column whose id matches [field]'s and leaves the rest as
  /// they were. If it isn't there —the detail was reloaded and the column no
  /// longer exists— nothing changes: a column the backend didn't return isn't
  /// added.
  ///
  /// **The summaries above are not recalculated.** How many columns there are
  /// of each type, how many are still bare text, and what the model can do
  /// with the table are counted by the backend (see [TableColumnsSummary]),
  /// and counting them here would mean writing the same rule twice just to be
  /// a second early. They arrive with the reread that the write itself
  /// triggers, while the bar up top signals that it's reloading.
  TableDetailModel withField(TableDetailFieldModel field) {
    final index = fields.indexWhere((current) => current.id == field.id);
    if (index < 0) return this;

    return TableDetailModel(
      id: id,
      name: name,
      description: description,
      color: color,
      date: date,
      updated: updated,
      records: records,
      lastRecord: lastRecord,
      columns: columns,
      agent: agent,
      channels: channels,
      fields: List<TableDetailFieldModel>.from(fields)..[index] = field
    );
  }

  /// The table's color already parsed, or `null` if none came or it can't be
  /// read: it's decoration and the screen looks the same without it.
  Color? get tint {
    if (color.isEmpty) return null;

    final parsed = int.tryParse(color);
    return parsed == null ? null : Color(parsed);
  }

  /// Decodes the response without locking to a single shape, like the rest of
  /// the app's reads: columns are accepted in the columnar table form
  /// (`{"keys": [...], "values": [...]}`) they travel compressed in, and also
  /// as a list of objects.
  factory TableDetailModel.fromResponse(dynamic data) {
    if (data is! Map) return const TableDetailModel();

    // Some endpoints wrap the response in a key: go down one level before
    // giving up.
    if (data["id"] == null && data["ID"] == null) {
      final inner = data["data"] ?? data["table"] ?? data["details"];
      if (inner is Map) return TableDetailModel.fromResponse(inner);
    }

    final records = data["records"];

    return TableDetailModel(
      id: (data["id"] ?? data["ID"])?.toString() ?? "",
      name: (data["name"] ?? data["NAME"] ?? "").toString(),
      description: (data["description"] ?? data["DESCRIPTION"] ?? "").toString(),
      color: (data["color"] ?? data["COLOR"] ?? "").toString(),
      date: _date(data["date"] ?? data["DATE"]),
      updated: _date(data["updated"] ?? data["UPDATED"]),
      // The whole object being `null` means "couldn't be counted"; an
      // unreadable total is read the same way, because saying nothing is the
      // right answer to both.
      records: records is Map ? _int(records["total"]) : null,
      lastRecord: records is Map ? _date(records["last"]) : null,
      columns: data["columns"] is Map
        ? TableColumnsSummary.fromJson(data["columns"] as Map)
        : const TableColumnsSummary(),
      agent: data["agent"] is Map
        ? TableAgentSummary.fromJson(data["agent"] as Map)
        : const TableAgentSummary(),
      channels: data["channels"] is Map
        ? TableChannelsSummary.fromJson(data["channels"] as Map)
        : const TableChannelsSummary(),
      fields: _fields(data["fields"] ?? data["FIELDS"])
    );
  }

  static List<TableDetailFieldModel> _fields(dynamic raw) {
    if (raw is Map) {
      final keys = raw["keys"] ?? raw["KEYS"];
      final values = raw["values"] ?? raw["VALUES"];

      if (keys is! List || values is! List) return const [];

      return [
        for (final row in values)
          if (row is List)
            TableDetailFieldModel.fromJson({
              for (int i = 0; i < keys.length && i < row.length; i++)
                keys[i].toString(): row[i]
            })
          // Just in case the row already comes as an object.
          else if (row is Map)
            TableDetailFieldModel.fromJson(row)
      ];
    }

    if (raw is List) {
      return [
        for (final field in raw)
          if (field is Map) TableDetailFieldModel.fromJson(field)
      ];
    }

    return const [];
  }
}

/// The options of a list column. Accepted as a list (the shape they travel
/// in) and as the JSON text of that list, in case the column arrives
/// undecoded.
List<String> _options(dynamic raw) {
  if (raw is String) {
    final text = raw.trim();
    if (text.isEmpty) return const [];

    try {
      return _options(jsonDecode(text));
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

/// A `1`/`0` flag from the response, read with the same criteria used on the
/// other side: the only thing that turns it off is a recognizable "no".
///
/// Everything else —including the `null` of a row written before the column
/// existed— leaves it on. It's on purpose: an unreadable flag can't silently
/// pull a column out of the view it was always in.
bool _flag(dynamic raw) => switch (raw) {
  final bool value => value,
  final num number => number != 0,
  final String text => switch (text.trim().toLowerCase()) {
    "0" || "false" => false,
    _ => true
  },
  _ => true
};

/// An integer from the response, or `null` if none came or it can't be read
/// as one: MySQL sends counts as text more often than it seems.
int? _int(dynamic raw) => switch (raw) {
  final num number => number.toInt(),
  final String text => int.tryParse(text.trim()),
  _ => null
};

/// Dates arrive in ISO 8601 (`2026-07-14T10:32:11.000Z`). An unreadable date
/// doesn't break the screen: it's discarded and that row says there is none.
DateTime? _date(dynamic raw) {
  if (raw == null) return null;
  return DateTime.tryParse(raw.toString());
}
