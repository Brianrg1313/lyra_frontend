import './sheet_cursor.dart';

/// The field row is row 1 of the spreadsheet; since the body is numbered
/// from 0 (the first record), it gets the -1.
const int kFieldsRow = -1;

/// Cell of the spreadsheet in body coordinates: row 0 is the first record
/// (row 2 of the spreadsheet, because row 1 is the fields, which is the row
/// [kFieldsRow]) and the column is the position within the spreadsheet's
/// columns.
class SheetCell {
  const SheetCell(this.row, this.column);

  final int row;
  final int column;

  bool at(int row, int column) => this.row == row && this.column == column;

  @override
  bool operator ==(Object other) =>
    other is SheetCell && other.row == row && other.column == column;

  @override
  int get hashCode => Object.hash(row, column);
}

/// How a cell stands with respect to the cursor.
///
/// It's what a cell needs to know about the cursor to paint **its border**,
/// and that's why it's a value and not three loose booleans: the cell
/// subscribes to this, so moving the cursor rebuilds it only if its state
/// changed. Of the hundreds of cells on screen, that's two.
///
/// Its **background** is something else and comes from another question
/// ([SheetCursor.isRow]): the cursor highlights the whole row, so there what
/// changes are the two rows.
enum SheetCellState {
  /// Neither selected nor being written.
  idle,

  /// Selected, without an editor: it's what's left after tapping a cell that
  /// isn't written.
  selected,

  /// Selected and with the text editor open.
  editing
}
