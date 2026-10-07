import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/stock/tables/table_structure_model.dart';
import 'package:app/services/stock/tables/table_view_service.dart';

import './free_column.dart';
import './sheet_column.dart';
import './sheet_order.dart';
import './sheet_shape.dart';

/// The columns of the spreadsheet and the state of the changes that are
/// traveling.
///
/// Brings together the two halves of a single list: the fields the structure
/// provided ([TableViewService.fields]) and the free columns at the end, which
/// don't exist in the backend yet.
///
/// **It doesn't notify every time the service reports something**: the service
/// also notifies for each batch of records coming in, and repainting the field
/// row for that would be wasted work. Since the structure builds a new list
/// of fields each time it's re-read, comparing identities is enough.
///
/// And when it does notify, not everyone listening has to rebuild. Whoever
/// looks at the **shape** of the spreadsheet (how many columns and which one
/// goes in each place) listens to [shape], which keeps its instance while that
/// shape doesn't change; whoever looks at the **content** of a column (its
/// title, its type, whether it has a change in flight) asks by index from its
/// own cell. That way a rename repaints one cell and not the grid, and a type
/// change repaints that column.
///
/// ---
///
/// **The user sets the order, not the structure.** Columns are dragged around
/// like in a spreadsheet, and that order is kept here as a list of FIELD_ID
/// ([_order]) applied over the fields the structure provides. It's stored that
/// way, and not by rearranging fields or data, for three reasons that are the
/// same:
///
/// - **Records are untouched.** A read row is a list of values aligned with
///   the structure's fields; moving a column only changes the [SheetShape.slots]
///   with which its cell looks up the value, so dragging a column in a table of
///   hundreds of thousands of records costs the same as in one of ten.
/// - **Nothing has to be re-read.** The new order is seen on drop; what
///   travels to the backend is only each field's position, and it doesn't ask
///   for the table again.
/// - **The order survives.** Since they're ids and not positions, re-reading
///   the whole structure —creating a column, renaming it, saving a row— doesn't
///   lose it.
class SheetColumns extends ChangeNotifier {
  SheetColumns(this._service, {this.freeColumns = 2}) {
    _fields = _service.fields;
    FreeColumn.normalize(_free, free: freeColumns);
    _rebuild();

    _service.addListener(_onService);
  }

  final TableViewService _service;

  /// Free columns that always remain to the right, for the same reason as the
  /// blank rows: the spreadsheet doesn't end at the last field.
  final int freeColumns;

  /// Free columns at the end: the ones that aren't a field of the table yet.
  /// There are always [freeColumns] blank at the end, and in between the ones
  /// that have a title but are still being created.
  final List<FreeColumn> _free = [];

  /// New titles still traveling, by FIELD_ID. The cell shows the new one
  /// (dimmed, like that of a column being created) instead of going back to
  /// the old one for a moment while the backend responds.
  final Map<String, String> _renaming = {};

  /// Fields whose deletion is in flight, by FIELD_ID. Their cell looks dimmed
  /// and can't be written until the column disappears.
  final Set<String> _deleting = {};

  /// The fields [_list] was built with, **as the structure provides them**.
  /// It's kept to know, when the service notifies, whether what changed was
  /// the columns or just the data, and it's the order the read records are
  /// aligned against.
  List<TableFieldModel> _fields = const [];

  /// The same fields, in the order the user left them.
  List<TableFieldModel> _ordered = const [];

  /// The order the user chose, by FIELD_ID. Empty while no column has been
  /// dragged, which is the usual case: then the structure rules and there's
  /// nothing to reorder.
  List<String> _order = const [];

  List<SheetColumn> _list = const [];

  SheetShape _shape = SheetShape.empty;

  /// The spreadsheet's columns, in order.
  List<SheetColumn> get list => _list;

  int get length => _list.length;

  /// How many of the columns are fields of the table. Past that position the
  /// free ones start.
  int get fieldCount => _fields.length;

  /// The table's fields in the order in which they're seen. It's what gets
  /// sent when saving the new order: each field's position is its place in
  /// this list.
  List<TableFieldModel> get ordered => _ordered;

  SheetColumn? at(int index) =>
    index >= 0 && index < _list.length ? _list[index] : null;

  /// The field occupying that position, or `null` if there's still a free
  /// column there.
  TableFieldModel? fieldAt(int index) =>
    index >= 0 && index < _ordered.length ? _ordered[index] : null;

  /// The free column occupying that position of the spreadsheet, or `null` if
  /// there's a field there.
  FreeColumn? freeAt(int index) {
    final local = index - _fields.length;
    return local >= 0 && local < _free.length ? _free[local] : null;
  }

  /// The title the column gets: the one just written if the rename is still
  /// traveling and, otherwise, the one the structure provides.
  String nameOf(int index) {
    final column = at(index);
    if (column == null) return "";

    return column.id.isEmpty
      ? column.name
      : _renaming[column.id] ?? column.name;
  }

  /// `true` while the column has a change in flight: it's being created,
  /// renamed, or deleted. Its cell looks dimmed and isn't written until the
  /// change comes back.
  bool busyAt(int index) {
    final column = at(index);
    if (column == null) return false;

    return column.creating ||
      (column.id.isNotEmpty &&
        (_renaming.containsKey(column.id) || _deleting.contains(column.id)));
  }

  /// Whether that column's title can be written: the free ones expect one and
  /// already-created fields are renamed (or deleted, emptying them) from right
  /// there. The only ones that can't are those with a change in flight and
  /// those of a field without a FIELD_ID, which the backend wouldn't know
  /// which is.
  bool canEditAt(int index) {
    final column = at(index);
    if (column == null) return false;

    return !busyAt(index) && (!column.isField || column.id.isNotEmpty);
  }

  /// Key with which a column's width is remembered: the FIELD_ID if it came
  /// and, otherwise, the position.
  String keyOf(int index) {
    final column = at(index);
    final id = column?.id ?? "";

    return id.isNotEmpty ? id : "col_$index";
  }

  /// The shape of the spreadsheet: the width keys and where each column's value
  /// comes from.
  ///
  /// While it's the same instance, the grid has the same columns in the same
  /// place —even if one changed its name, type, or is busy— and that's why
  /// it's this, and not [list], that the spreadsheet listens to: renaming a
  /// column can't cost the whole grid. What changes inside each cell is
  /// listened to by each cell.
  SheetShape get shape => _shape;

  /// The width keys of all columns, in order. It's with these that
  /// `SheetWidths` remembers how wide each one is.
  ///
  /// They're the FIELD_IDs, not the positions, and that's why dragging a
  /// column carries its width with it without having to move anything.
  List<String> get keys => _shape.keys;

  /// From which position of the row the value of column [index] comes.
  ///
  /// Records arrive aligned with the fields exactly as the structure provides
  /// them, so this is the field's index there —which isn't where it's seen if
  /// it was dragged out of place—. The free columns at the end also have
  /// theirs, behind all the fields: there's nowhere to store yet, but what's
  /// written in them needs its own place in the row's draft.
  int slotAt(int index) =>
    index >= 0 && index < _shape.slots.length ? _shape.slots[index] : index;

  /// Code of the column's type, or empty (which reads as text) if it's still
  /// not a field of the table.
  String typeOf(int index) => at(index)?.type ?? "";

  /// The options that column chooses among, if it's a list field.
  ///
  /// Empty in any other type: a list without options unfolds the same anyway,
  /// with the button to create the first one.
  List<String> optionsOf(int index) => at(index)?.options ?? const [];

  /// The symbol with which that column's numbers are written: the currency of
  /// a price, the magnitude of a measure. Empty where the type doesn't carry
  /// one, and also in a price that never declared its own —there the
  /// company's currency rules, and the cell resolves it.
  String unitOf(int index) => at(index)?.unit ?? "";

  /// Whether the column is already a field of the table. A free one looks the
  /// same but has nowhere to store, so its cells aren't written.
  bool isFieldAt(int index) => at(index)?.isField ?? false;

  /// Writes the title of a free column while typing.
  ///
  /// Returns `true` if that changed the number of columns: filling the last
  /// free one adds another behind it and emptying it takes away the leftover,
  /// and that does need repainting. Merely changing the text doesn't notify:
  /// that cell has the editor open and already shows what's being written.
  bool writeFree(int index, String name) {
    final free = freeAt(index);
    if (free == null) return false;

    final before = _free.length;
    free.name = name.trim();
    FreeColumn.normalize(_free, free: freeColumns);

    if (_free.length == before) return false;

    _rebuild();
    notifyListeners();
    return true;
  }

  /// Marks that the free column is traveling (the field is being created).
  void startCreate(FreeColumn free) {
    free.creating = true;
    notifyListeners();
  }

  /// The free column is now a field of the table: it's taken out of the end.
  /// If the creation failed ([created] is `false`) it stays free, with its
  /// title set, to retry by leaving the cell again.
  void endCreate(FreeColumn free, {required bool created}) {
    free.creating = false;

    if (created) {
      _free.remove(free);
      FreeColumn.normalize(_free, free: freeColumns);
      _rebuild();
    }

    notifyListeners();
  }

  void startRename(String id, String name) {
    _renaming[id] = name;
    notifyListeners();
  }

  void endRename(String id) {
    if (_renaming.remove(id) == null) return;
    notifyListeners();
  }

  void startDelete(String id) {
    _deleting.add(id);
    notifyListeners();
  }

  void endDelete(String id) {
    if (!_deleting.remove(id)) return;
    notifyListeners();
  }

  /// Takes column [from] to edge [to] (see [movedOrder]).
  ///
  /// Returns the order that was there before, or `null` if nothing moved.
  /// That last one is what the controller needs for two things: to know if
  /// there's something to send to the backend, and to be able to return the
  /// spreadsheet to how it was if the change doesn't go through.
  ///
  /// The free columns at the end aren't moved —they're not fields of the
  /// table, there's nothing to reorder in them— nor are those of a table
  /// that has some field without a FIELD_ID: order is stored by id, and
  /// without it there'd be no way to write it nor to apply it again when the
  /// structure is re-read.
  List<String>? reorder(int from, int to) {
    if (from < 0 || from >= _ordered.length) return null;
    if (to < 0 || to > _ordered.length) return null;

    for (final field in _ordered) {
      if (field.id.isEmpty) return null;
    }

    final before = _order.isNotEmpty
      ? _order
      : [for (final field in _ordered) field.id];

    final after = movedOrder(before, from: from, to: to);
    if (identical(after, before)) return null;

    _order = after;
    _rebuild();
    notifyListeners();

    return before;
  }

  /// Goes back to order [order], which is the one there was before a drag the
  /// backend didn't accept.
  void restoreOrder(List<String> order) {
    if (listEquals(_order, order)) return;

    _order = order;
    _rebuild();
    notifyListeners();
  }

  /// The service notifies about everything: the structure, each batch of
  /// records, each creation. Here only whether the fields changed matters,
  /// and the structure builds a new list each time it's re-read, so identity
  /// is enough.
  void _onService() {
    if (identical(_service.fields, _fields)) return;

    _fields = _service.fields;
    _rebuild();
    notifyListeners();
  }

  void _rebuild() {
    _ordered = fieldsInOrder(_fields, _order);

    _list = [
      for (final field in _ordered) SheetColumn.field(field),
      for (final free in _free) SheetColumn.free(free)
    ];

    final keys = [
      for (int index = 0; index < _list.length; index++) keyOf(index)
    ];

    final slots = slotsOf(_fields, _ordered, free: _free.length);

    // The previous instance is kept if the shape is the same: it's the
    // identity with which the spreadsheet decides whether it has to rebuild
    // the grid, and a re-read structure brings new objects even if nothing
    // about the table's shape changed.
    if (listEquals(_shape.keys, keys) && listEquals(_shape.slots, slots)) {
      return;
    }

    _shape = SheetShape(keys, slots);
  }

  @override
  void dispose() {
    _service.removeListener(_onService);
    super.dispose();
  }
}
