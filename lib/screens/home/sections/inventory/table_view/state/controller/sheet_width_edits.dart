part of '../sheet_controller.dart';

/// Column widths: a drag on a header's edge resizes its column live, and
/// letting go sends the width ([SheetController.widths] holds them).
extension SheetWidthEdits on SheetController {
  /// Starts dragging a column's width: the one it had is noted, which is what
  /// it goes back to if the save doesn't go through.
  void startResize(int index) {
    _resizing = index;
    _resizedFrom = widths.valueOf(columns.keyOf(index));
  }

  /// Drags a column's width. Only that column finds out.
  void resize(int index, double delta) =>
    widths.resize(columns.keyOf(index), delta);

  /// Releases the edge: the width the column ended up with is saved.
  ///
  /// It's sent **on release** and not on every drag event, which are dozens
  /// per second. If nothing changed —a tap on the edge, or a column that was
  /// already at the minimum— nothing travels, and neither does the one of a
  /// free column at the end: it isn't a field yet, there's nowhere to save
  /// its width (it'll have it only when it's created and dragged again).
  void endResize(int index) {
    final from = _resizedFrom;
    final resizing = _resizing;

    _resizing = -1;
    if (resizing != index) return;

    final field = columns.fieldAt(index);
    if (field == null || field.id.isEmpty) return;

    final width = widths.valueOf(field.id);
    if (width == from) return;

    _columnQueue = _columnQueue.then((_) => _sendWidth(field, width, from));
  }

  /// Sends the new width. It goes through the same queue as the creations,
  /// renames, and deletions: each of those re-reads the structure, and sending
  /// the width while a re-read is in the air would write it against an old
  /// name (editing a field also sends its name, which the backend always asks
  /// for).
  ///
  /// If it doesn't go through, the column goes back to the width it had. The
  /// service already showed the error.
  Future<void> _sendWidth(
    TableFieldModel field,
    double width,
    double before
  ) async {
    if (_disposed) return;

    final saved = await service.resizeField(_context(), field, width: width);
    if (_disposed || saved) return;

    widths.restore(field.id, before);
  }
}
