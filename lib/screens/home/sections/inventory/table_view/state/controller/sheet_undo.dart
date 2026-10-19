part of '../sheet_controller.dart';

/// Ctrl+Z and Ctrl+Y: what a record's cell was corrected to, written back or again.
///
/// A change is remembered by the record's id and the field's, never by where it was seen: a
/// search, a reload or a dragged column move the cell, and the undo finds it where it is now.
/// The draft rows below are not remembered (they are not records yet), nor a stock (its figure
/// is a movement of the inventory, not the cell's), nor an image (its gallery travels apart).
extension SheetUndo on SheetController {
  void undo() {
    if (history.canUndo) _step(history.undo);
  }

  void redo() {
    if (history.canRedo) _step(history.redo);
  }

  /// Remembers that [cell], a record's, went from [before] to [after].
  void _remember(SheetCell cell, String before, String after) {
    if (before.trim() == after.trim()) return;

    final record = service.rowAt(cell.row);
    final field = columns.fieldAt(cell.column);
    if (record == null || record.id.isEmpty || field == null || field.id.isEmpty) return;

    final id = record.id;
    final fieldId = field.id;

    history.push(SheetChange(
      undo: () => _rewrite(id, fieldId, before),
      redo: () => _rewrite(id, fieldId, after)
    ));
  }

  /// Writes [value] in record [id]'s [fieldId], seen at once and sent behind like any
  /// correction ([TableViewService.editRecord]); if it doesn't go through, the service gives
  /// the cell back and says so. `null` when the record or the field are no longer on the sheet.
  SheetCell? _rewrite(String id, String fieldId, String value) {
    final row = service.rowOf(id);
    final slot = service.fields.indexWhere((field) => field.id == fieldId);
    final column = columns.keys.indexOf(fieldId);

    if (row == null || slot < 0 || column < 0) return null;

    unawaited(service.editRecord(
      _context(),
      row: row,
      slot: slot,
      fieldId: fieldId,
      value: value.trim()
    ));

    return SheetCell(row, column);
  }

  /// Leaves the cursor on what a step wrote, and the range over it when it was several cells.
  ///
  /// The editor is closed before the step runs: a cell open on the record being written back
  /// would otherwise send what it holds over it on closing.
  void _step(List<SheetCell>? Function() run) {
    close();
    final cells = run();
    if (cells == null) return;

    if (cells.isEmpty) {
      final context = _context();
      if (context.mounted) FloatFlag.of(context).alert(message: S.of(context).sheet_history_gone);
      return;
    }

    var top = cells.first.row, bottom = top, left = cells.first.column, right = left;
    for (final cell in cells) {
      if (cell.row < top) top = cell.row;
      if (cell.row > bottom) bottom = cell.row;
      if (cell.column < left) left = cell.column;
      if (cell.column > right) right = cell.column;
    }

    final corner = SheetCell(top, left);
    select(corner);
    selection.stretch(corner, SheetCell(bottom, right));
  }
}
