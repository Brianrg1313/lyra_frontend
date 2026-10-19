import 'package:flutter/foundation.dart';

import './sheet_cell.dart';

/// One change of the sheet that can be taken back: how to undo it and how to do it again.
///
/// Each half returns the cell it wrote, which is where the cursor goes, or `null` when there
/// is nothing left to write it to (the record left the view, the column was deleted). They
/// are closures and not data so that any write of any sheet —a cell, a column, whatever comes
/// later— is remembered the same way: whoever writes knows how to write it back.
class SheetChange {
  const SheetChange({required this.undo, required this.redo});

  final SheetCell? Function() undo;
  final SheetCell? Function() redo;
}

/// What was done on the sheet, to undo it (Ctrl+Z) and redo it (Ctrl+Y, Ctrl+Shift+Z).
///
/// A step is a list of changes: one cell typed is one change, and an action over a range
/// written inside [group] is one step however many cells it touched, so one Ctrl+Z takes it
/// all back. Doing something new forgets what was undone, like any editor.
///
/// It notifies when what can be undone or redone changes, which is what a menu or a button
/// offering them listens to.
class SheetHistory extends ChangeNotifier {
  SheetHistory({this.limit = 100});

  /// How many steps back are kept; the oldest go first.
  final int limit;

  final List<List<SheetChange>> _done = [];
  final List<List<SheetChange>> _undone = [];

  /// The step being gathered by [group], while it lasts.
  List<SheetChange>? _group;

  bool get canUndo => _done.isNotEmpty;
  bool get canRedo => _undone.isNotEmpty;

  /// Remembers [change] as one step, or as part of the step [group] is gathering.
  void push(SheetChange change) {
    final group = _group;

    if (group != null) {
      group.add(change);
      return;
    }

    _keep([change]);
  }

  /// Runs [writes] and remembers every change they push as a single step. A group inside a
  /// group joins the outer one.
  void group(void Function() writes) {
    if (_group != null) return writes();

    final step = _group = [];

    try {
      writes();
    } finally {
      _group = null;
      if (step.isNotEmpty) _keep(step);
    }
  }

  /// Undoes the last step, last change first, and returns the cells it wrote; `null` when
  /// there was nothing to undo. An empty list is a step that had nowhere left to go.
  List<SheetCell>? undo() {
    if (_done.isEmpty) return null;

    final step = _done.removeLast();
    _undone.add(step);
    notifyListeners();

    return [
      for (final change in step.reversed) change.undo()
    ].whereType<SheetCell>().toList();
  }

  /// Does again the last step undone, in its order, and returns the cells it wrote; `null`
  /// when there was nothing to redo.
  List<SheetCell>? redo() {
    if (_undone.isEmpty) return null;

    final step = _undone.removeLast();
    _done.add(step);
    notifyListeners();

    return [
      for (final change in step) change.redo()
    ].whereType<SheetCell>().toList();
  }

  void clear() {
    if (_done.isEmpty && _undone.isEmpty) return;

    _done.clear();
    _undone.clear();
    notifyListeners();
  }

  void _keep(List<SheetChange> step) {
    _done.add(step);
    if (_done.length > limit) _done.removeAt(0);

    _undone.clear();
    notifyListeners();
  }
}
