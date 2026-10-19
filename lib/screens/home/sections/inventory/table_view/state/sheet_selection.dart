import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import './sheet_cell.dart';

/// A rectangle of cells, from the cell it started at ([anchor], the cursor's) to the one it
/// was stretched to ([focus]), whichever way: every row and column between the two is in it.
class SheetRange {
  const SheetRange(this.anchor, this.focus);

  /// A range of one cell: what the menu acts on when nothing is selected.
  const SheetRange.single(SheetCell cell) : anchor = cell, focus = cell;

  final SheetCell anchor;
  final SheetCell focus;

  int get top => math.min(anchor.row, focus.row);
  int get bottom => math.max(anchor.row, focus.row);
  int get left => math.min(anchor.column, focus.column);
  int get right => math.max(anchor.column, focus.column);

  int get rows => bottom - top + 1;
  int get columns => right - left + 1;

  bool get single => anchor == focus;

  bool contains(int row, int column) =>
    row >= top && row <= bottom && column >= left && column <= right;

  /// Its cells row by row, left to right.
  Iterable<SheetCell> get cells sync* {
    for (var row = top; row <= bottom; row++) {
      for (var column = left; column <= right; column++) {
        yield SheetCell(row, column);
      }
    }
  }

  @override
  bool operator ==(Object other) =>
    other is SheetRange && other.anchor == anchor && other.focus == focus;

  @override
  int get hashCode => Object.hash(anchor, focus);
}

/// The cells selected together (Shift+click, Shift+arrows), beyond the cursor's.
///
/// It only holds a range of more than one cell: one cell is the cursor ([SheetCursor]), which
/// keeps standing on the [SheetRange.anchor] while the range is stretched. It notifies on its
/// own for the cursor's reason: each cell subscribes to whether it is in it, a boolean, so
/// stretching the range rebuilds the cells that came in or went out and not the sheet.
class SheetSelection extends ChangeNotifier {
  SheetRange? _range;

  SheetRange? get range => _range;

  bool contains(int row, int column) => _range?.contains(row, column) ?? false;

  /// Selects from [anchor] to [focus]; the same cell is no range and clears it.
  void stretch(SheetCell anchor, SheetCell focus) {
    final range = anchor == focus ? null : SheetRange(anchor, focus);
    if (range == _range) return;

    _range = range;
    notifyListeners();
  }

  void clear() {
    if (_range == null) return;

    _range = null;
    notifyListeners();
  }
}
