import 'package:flutter/foundation.dart';

import './sheet_cell.dart';

/// The chosen cell and whether it's being written.
///
/// It lives apart from the screen and notifies on its own because it's what
/// changes most often: every navigation key and every tap moves it. Cells
/// subscribe with `context.select(...)`, so moving the cursor rebuilds **the
/// two rows** that changed —the one left and the one taken— and not the whole
/// spreadsheet. It's two rows and not two cells because the cursor highlights
/// the row it stands on, not just its cell.
class SheetCursor extends ChangeNotifier {
  SheetCell? _cell;
  bool _editing = false;

  SheetCell? get cell => _cell;

  /// Row of the cursor, or `null` if there's no chosen cell. The row-number
  /// gutter looks at it to highlight the row.
  int? get row => _cell?.row;

  int? get column => _cell?.column;

  /// `true` when the cursor's cell has the text editor open.
  /// Selected without editing is what's left after tapping a cell that can't
  /// be written.
  bool get editing => _editing;

  bool isAt(int row, int column) => _cell?.at(row, column) ?? false;

  /// How that cell stands with respect to the cursor. It's what each
  /// spreadsheet cell subscribes to.
  SheetCellState stateAt(int row, int column) {
    if (!isAt(row, column)) return SheetCellState.idle;
    return _editing ? SheetCellState.editing : SheetCellState.selected;
  }

  /// `true` if the cursor is in that row, regardless of the column.
  bool isRow(int row) => _cell?.row == row;

  /// Moves the cursor. Doesn't notify if nothing changed: entering and leaving
  /// the same cell is the most common thing when moving around the
  /// spreadsheet and doesn't need to repaint.
  void move(SheetCell? cell, {bool editing = false}) {
    if (_cell == cell && _editing == editing) return;

    _cell = cell;
    _editing = editing;
    notifyListeners();
  }

  /// Closes the editor leaving the cell selected.
  void stopEditing() {
    if (!_editing) return;

    _editing = false;
    notifyListeners();
  }

  void clear() => move(null);
}
