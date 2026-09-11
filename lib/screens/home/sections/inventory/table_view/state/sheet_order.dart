/// The order in which the user left the columns, and the arithmetic of
/// dragging them out of place.
///
/// It lives apart and is pure for the same reason as the spreadsheet geometry
/// (`SheetMetrics`): it depends on nothing of the widget tree nor the network,
/// so it's tested on its own.
///
/// Order is stored as a list of FIELD_IDs and not of positions, and that's
/// the whole point: a list of positions breaks with any change of the
/// structure —a column created, another deleted, one the backend returns in a
/// different place— and one of ids stays equally valid. That's why the order
/// the user chose survives the whole table being re-read.
library;

import 'package:app/services/stock/tables/table_structure_model.dart';

/// The fields of [fields] set in the order of [order] (FIELD_IDs).
///
/// [order] rules. A field that isn't there —one recently created, or one that
/// another client added— goes at the end, in the order the structure brought
/// it: it's the same place where a new column is born, so nothing moves out
/// of place because of having created it.
///
/// With empty [order] there's nothing to reorder and **the same list** is
/// returned, without copying it: it's what happens while the user hasn't
/// dragged any column, which is almost always.
///
/// A field without a FIELD_ID can't be paired with anything, so it isn't
/// ordered either: it stays at the end along with those that weren't in
/// [order]. That's why `SheetColumns` doesn't allow dragging in a table that
/// has one.
List<TableFieldModel> fieldsInOrder(
  List<TableFieldModel> fields,
  List<String> order
) {
  if (order.isEmpty || fields.length < 2) return fields;

  final rank = <String, int>{};
  for (final (index, id) in order.indexed) {
    if (id.isNotEmpty) rank[id] = index;
  }

  final known = <TableFieldModel>[];
  final rest = <TableFieldModel>[];

  for (final field in fields) {
    (rank.containsKey(field.id) ? known : rest).add(field);
  }

  if (known.length < 2) return fields;

  known.sort((a, b) => rank[a.id]!.compareTo(rank[b.id]!));

  return [...known, ...rest];
}

/// From which place of the row each spreadsheet column's value comes.
///
/// [fields] are the fields as the structure provides them —which is what read
/// records are aligned against— and [ordered] the same ones, in the order in
/// which they're seen. After them go [free] free columns, which aren't fields
/// yet: they have nowhere to store, but what's written in them needs its own
/// place in the row's draft, and they're given the one they'd get if they
/// were created (behind all the fields, which is where they're born).
///
/// This is what makes dragging a column cost nothing: the only thing that
/// changes place is an `int` per column, and not a single record is touched.
List<int> slotsOf(
  List<TableFieldModel> fields,
  List<TableFieldModel> ordered, {
  required int free
}) {
  final place = {for (final (index, field) in fields.indexed) field: index};

  return [
    for (final field in ordered) place[field] ?? 0,
    for (int index = 0; index < free; index++) fields.length + index
  ];
}

/// The order left after taking column [from] to edge [to].
///
/// [to] is an **edge** and not a column: `0` is in front of the first and
/// `order.length` is behind the last. It reads that way because it's exactly
/// what the line marks while dragging —it lands *between* two columns, not
/// *on* one— and that's why dropping on the left edge of the column itself,
/// or on the right one, doesn't move it.
///
/// Returns **the same list** when there's nothing to move, so whoever calls
/// can know by comparing identities and not spend a repaint.
List<String> movedOrder(
  List<String> order, {
  required int from,
  required int to
}) {
  if (from < 0 || from >= order.length) return order;
  if (to < 0 || to > order.length) return order;

  // Dropping it where it already was: the two edges around it leave it the
  // same.
  if (to == from || to == from + 1) return order;

  final moved = [...order];
  final id = moved.removeAt(from);

// Taking it out shifted everything behind it one place, including the edge
    // where it's meant to land.
  moved.insert(to > from ? to - 1 : to, id);

  return moved;
}

/// The edge where a column dropped at [x] would land.
///
/// [edges] are the left edges of each column plus the end of the last one
/// (one value more than there are columns), and only the first [columns] are
/// looked at: past them are the free ones at the end, which aren't fields of
/// the table yet and receive nothing.
///
/// It's compared against the **middle** of each column and not against its
/// edge, which is what makes the line jump when the dragged column already
/// covers more than half a neighbor instead of as soon as it grazes it.
int dropEdgeAt(List<double> edges, double x, {required int columns}) {
  final last = columns < edges.length - 1 ? columns : edges.length - 1;

  for (int index = 0; index < last; index++) {
    if (x < (edges[index] + edges[index + 1]) / 2) return index;
  }

  return last < 0 ? 0 : last;
}
