import 'dart:math' as math;

/// The geometry of the spreadsheet: how tall a row is, how many there are,
/// which ones are seen, and where it has to scroll for a cell to fit on
/// screen.
///
/// It's pure arithmetic and that's why it lives apart: it used to be computed
/// inside `build` and stored in the `State` for the keyboard to read, which
/// tied key handling to the order in which the tree was built. Here it depends
/// on nothing of the tree and is tested on its own.
///
/// All of this only works because the two vertical bands have `itemExtent`:
/// with fixed-height rows, going from a row to an offset (and back) is a
/// multiplication, and a table of hundreds of thousands of records measures
/// its height without having to build a single row.
class SheetMetrics {
  const SheetMetrics({
    required this.rowHeight,
    required this.gutterWidth,
    this.minBlankRows = 5,
    this.prefetch = 10
  });

  /// Height of a row and of the field row. It's the same for both: the field
  /// row is row 1 of the spreadsheet, not a separate header.
  final double rowHeight;

  /// Width of the row-number gutter.
  final double gutterWidth;

  /// Blank rows that always remain at the end, even when the screen is already
  /// full: the spreadsheet never ends at the last written row.
  final int minBlankRows;

  /// How many rows before reaching them the next batch of records is requested.
  /// It's the margin the reading has to arrive in time: it's requested when
  /// [prefetch] rows are still to come in, not when they're already in view.
  final int prefetch;

  /// How many body rows fit in [height]. The field row is deducted, since it's
  /// frozen on top and doesn't scroll.
  int visibleRows(double height) => ((height - rowHeight) / rowHeight).ceil();

  /// How many rows the body has.
  ///
  /// [used] are the occupied rows (records, drafts, and the ones gained by
  /// going down with the keyboard) and to those are added the ones that always
  /// remain blank. Never fewer than those that fit on screen, so the
  /// spreadsheet always reaches all the way down.
  ///
  /// With [blanks] as `false` the body measures exactly what's occupied: it's
  /// the spreadsheet filtered by a search, where the blank rows wouldn't be
  /// for writing —what was written there wouldn't be part of the search— but
  /// empty lines making it seem the result continues.
  int bodyRows({
    required int used,
    required int visible,
    bool blanks = true
  }) => blanks ? math.max(used + minBlankRows, visible) : used;

  /// First and last row seen with the band at [offset]. The last one counts
  /// even if it's half seen, and neither of the two goes out of [rows].
  (int, int) rangeAt({
    required double offset,
    required double viewport,
    required int rows
  }) {
    if (rows <= 0) return (0, -1);

    final first = math.max(0, offset ~/ rowHeight);
    final last = math.min(rows - 1, ((offset + viewport) / rowHeight).ceil());

    return (first, math.max(first, last));
  }

  /// Where the vertical band has to be brought for row [row] to be seen, or
  /// `null` if it's already seen.
  double? revealRow({
    required int row,
    required double offset,
    required double viewport,
    required double maxExtent
  }) {
    // The field row is frozen on top: it's always seen.
    if (row < 0) return null;

    final top = row * rowHeight;

    if (top < offset) return math.max(0, top);
    if (top + rowHeight > offset + viewport) {
      return math.min(top + rowHeight - viewport, maxExtent);
    }

    return null;
  }

  /// Where the horizontal band has to be brought for a column that starts at
  /// [left] and measures [width] to be seen, or `null` if it's already seen.
  double? revealColumn({
    required double left,
    required double width,
    required double offset,
    required double viewport,
    required double maxExtent
  }) {
    if (left < offset) return math.max(0, left);
    if (left + width > offset + viewport) {
      return math.min(left + width - viewport, maxExtent);
    }

    return null;
  }
}
