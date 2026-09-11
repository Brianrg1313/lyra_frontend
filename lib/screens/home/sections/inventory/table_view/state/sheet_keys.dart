import 'package:flutter/services.dart';

import 'sheet_cursor.dart';

/// What a key asks of the spreadsheet.
///
/// Navigation is that of an Excel: Tab and Shift+Tab move between cells, Enter
/// and the up/down arrows go down and up, Escape cancels what was being
/// written. While writing, the left and right arrows are let through —they
/// move the cursor within the text, which is what's expected of an open
/// cell— and without an editor, on the other hand, they change column.
///
/// It lives apart from the focus handler so it can be read (and tested)
/// without mounting the spreadsheet.
enum SheetKeyIntent {
  /// Tab: the next cell, wrapping around the line when going past the end.
  nextCell,

  /// Shift+Tab: the previous cell, with the same wrap.
  previousCell,

  rowDown,
  rowUp,
  columnRight,
  columnLeft,

  /// Escape: undo what was written in the cell.
  cancel;

  /// How much it moves the cursor, or `null` if it isn't a movement.
  ({int rows, int columns, bool wrap})? get move => switch (this) {
    nextCell => (rows: 0, columns: 1, wrap: true),
    previousCell => (rows: 0, columns: -1, wrap: true),
    rowDown => (rows: 1, columns: 0, wrap: false),
    rowUp => (rows: -1, columns: 0, wrap: false),
    columnRight => (rows: 0, columns: 1, wrap: false),
    columnLeft => (rows: 0, columns: -1, wrap: false),
    cancel => null
  };

  /// What that key asks, or `null` if the spreadsheet doesn't use it and it has
  /// to continue its way.
  static SheetKeyIntent? of(
    LogicalKeyboardKey key, {
    required bool shift,
    required bool editing
  }) {
    if (key == LogicalKeyboardKey.tab) {
      return shift ? previousCell : nextCell;
    }

    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      return shift ? rowUp : rowDown;
    }

    if (key == LogicalKeyboardKey.arrowDown) return rowDown;
    if (key == LogicalKeyboardKey.arrowUp) return rowUp;

    // With the editor open these two belong to the text, not the grid.
    if (!editing && key == LogicalKeyboardKey.arrowRight) return columnRight;
    if (!editing && key == LogicalKeyboardKey.arrowLeft) return columnLeft;

    if (editing && key == LogicalKeyboardKey.escape) return cancel;

    return null;
  }
}

/// Where the cursor lands when moving it [rows] rows and [columns] columns
/// from [from].
///
/// With [wrap] (what Tab does) going past the last column continues in the
/// first of the next row; without it, the cursor stays stuck to the edge.
/// Going upward reaches the field row, which is one more row of the
/// spreadsheet and is traversed the same.
///
/// The row it returns can land **below** the end of the spreadsheet: going
/// past the last row adds another blank one, and that's not decided by this
/// account but by whoever calls it, who is the one that knows how many rows
/// there are.
SheetCell sheetDestination({
  required SheetCell from,
  required int rows,
  required int columns,
  required bool wrap,
  required int lastColumn
}) {
  int row = from.row + rows;
  int column = from.column + columns;

  if (column > lastColumn) {
    if (!wrap) {
      column = lastColumn;
    } else {
      column = 0;
      row += 1;
    }
  } else if (column < 0) {
    if (!wrap) {
      column = 0;
    } else {
      column = lastColumn;
      row -= 1;
    }
  }

  if (row < kFieldsRow) row = kFieldsRow;

  return SheetCell(row, column);
}
