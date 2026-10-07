part of '../sheet_controller.dart';

/// Columns dragged by their header to another place, with the view scrolling
/// on its own while the pointer rests against an edge.
extension SheetColumnDrag on SheetController {
  /// Starts dragging column [index] out of place, grabbing it by its field
  /// cell.
  ///
  /// Only the table's fields are dragged, and only while they don't have a
  /// change on the way: a free column at the end has no position to save, and
  /// one being created or deleted still doesn't have a known place to fall.
  ///
  /// Whatever was being written is closed first: the cell is about to change
  /// place and the editor can't follow it.
  void startColumnDrag(int index, DragStartDetails details) {
    close();

    final column = columns.at(index);
    if (column == null || !column.isField || columns.busyAt(index)) return;

    // The spreadsheet's geometry is solved **once**: from here on, each
    // pointer event is a subtraction and a search over this list.
    final edges = widths.edges();
    if (index + 1 >= edges.length) return;

    drag.start(
      source: index,
      label: columns.nameOf(index),
      grab: details.localPosition.dx,
      edges: edges,
      fields: columns.fieldCount
    );

    // Where the 0 of the content is: the pointer fell on `edges[index]` plus
    // how much it moved inside the cell.
    _dragOrigin =
      details.globalPosition.dx - edges[index] - details.localPosition.dx;
    _dragPointer = details.globalPosition.dx;
  }

  void updateColumnDrag(DragUpdateDetails details) {
    if (!drag.active.value) return;

    _dragPointer = details.globalPosition.dx;
    drag.moveTo(_dragPointer - _dragOrigin);

    _edgeScroll();
  }

  /// Releases the column where the line ended up.
  ///
  /// The new order is applied **now**, without waiting for the backend: the
  /// spreadsheet reorders itself (which costs no more than redoing the grid,
  /// because the records don't move from where they are) and the positions
  /// travel behind.
  void endColumnDrag() {
    _stopEdgeScroll();

    final (from, to) = drag.stop();
    if (from < 0) return;

    final before = columns.reorder(from, to);
    if (before == null) return;

    // The column moved to another place and took with it the meaning of the
    // chosen cell: the cursor points at a position that is now another column.
    cursor.clear();

    _columnQueue = _columnQueue.then((_) => _sendOrder(before));
  }

  /// The drag was cut without releasing (the pointer was lost, something
  /// opened on top): the column stays where it was.
  void cancelColumnDrag() {
    _stopEdgeScroll();
    drag.stop();
  }

  /// Sends the new order. It goes through the same queue as the creations,
  /// renames, and deletions: each of those re-reads the structure, and sending
  /// the positions while a re-read is in the air would write them against old
  /// names.
  ///
  /// If it doesn't go through, the spreadsheet goes back to the order it had.
  /// The service already showed the error.
  Future<void> _sendOrder(List<String> before) async {
    if (_disposed) return;

    final saved = await service.reorderFields(_context(), columns.ordered);
    if (_disposed || saved) return;

    columns.restoreOrder(before);
  }

  /// Scrolls the spreadsheet when the dragged column reaches an edge, so it
  /// can be taken further than what's seen.
  ///
  /// The pointer can stay still against the edge, so the scroll can't be
  /// triggered by the event: a tick is turned on for as long as it's needed
  /// and goes off as soon as the column comes back to the middle.
  void _edgeScroll() {
    if (_edgeOvershoot() == 0) {
      _stopEdgeScroll();
      return;
    }

    _dragScroll ??= Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _edgeStep()
    );
  }

  /// How much the pointer went into a side's margin, with sign: negative
  /// against the left, positive against the right, `0` in the middle.
  ///
  /// It's what decides whether to scroll the spreadsheet and at what speed:
  /// grazing the edge scrolls it slowly and leaning against it goes fast, like
  /// in any spreadsheet.
  double _edgeOvershoot() {
    if (!horizontal.hasClients) return 0;

    final left = _dragOrigin + horizontal.offset;
    final right = left + horizontal.position.viewportDimension;

    if (_dragPointer < left + _kEdgeMargin) {
      return _dragPointer - left - _kEdgeMargin;
    }

    if (_dragPointer > right - _kEdgeMargin) {
      return _dragPointer - right + _kEdgeMargin;
    }

    return 0;
  }

  /// A tick: scrolls the spreadsheet what's due and goes off when there's no
  /// direction left (the column came back to the middle, or the band reached
  /// the end).
  void _edgeStep() {
    final step = _disposed || !drag.active.value ? 0.0 : _edgeOvershoot();

    if (step == 0) {
      _stopEdgeScroll();
      return;
    }

    final to = (horizontal.offset + step.clamp(-_kEdgeStep, _kEdgeStep))
      .clamp(0.0, horizontal.position.maxScrollExtent);

    final moved = to - horizontal.offset;
    if (moved == 0) {
      _stopEdgeScroll();
      return;
    }

    horizontal.jumpTo(to);

    // The content moved under a pointer that didn't: the same place on the
    // screen is now another place of the content, so the ghost has to follow
    // the spreadsheet and not the pointer.
    _dragOrigin -= moved;
    drag.moveTo(_dragPointer - _dragOrigin);
  }

  void _stopEdgeScroll() {
    _dragScroll?.cancel();
    _dragScroll = null;
  }
}
