import 'package:flutter/foundation.dart';

/// The row the pointer is over.
///
/// It's its own state and not a part of [SheetCursor] because they're two
/// different things that look alike: the cursor is **where you're standing**
/// —keys and taps move it, and it survives the mouse leaving the screen—, and
/// this is **where the mouse is passing by**, which doesn't choose anything
/// and is lost as soon as the pointer leaves.
///
/// It notifies on its own for the same reason as the cursor: it changes with
/// every mouse movement between rows, so if this hung off the screen's state,
/// moving through the spreadsheet with the mouse would repaint it whole. Each
/// cell subscribes with `context.select(...at(fila))`, which is a boolean:
/// passing the mouse from one row to another runs the comparator of the cells
/// on view and rebuilds **the two rows** that changed, not the spreadsheet.
///
/// [kNoRow] is "none", and it's a number and not a null so that [at] is a bare
/// comparison: every visible cell in each movement answers it.
class SheetHover extends ChangeNotifier {
  /// No row. It's an index that doesn't exist: rows start at 0.
  static const int kNoRow = -1;

  int _row = kNoRow;

  /// The row under the pointer, or [kNoRow] if the mouse isn't over any.
  int get row => _row;

  /// `true` if the pointer is in that row. It's what each cell subscribes to.
  bool at(int row) => _row == row;

  /// The pointer entered [row].
  void enter(int row) {
    if (_row == row) return;

    _row = row;
    notifyListeners();
  }

  /// The pointer left [row].
  ///
  /// It's asked with the row and not plain because enter and leave notices
  /// don't always arrive in that order: moving quickly from one row to the
  /// next, the `onEnter` of the one below can arrive before the `onExit` of
  /// the one above, and without this check that exit would turn off the
  /// highlight of the row the pointer is already over.
  void leave(int row) {
    if (_row != row) return;

    _row = kNoRow;
    notifyListeners();
  }

  /// Turns off the highlight, whatever the row. For when the mouse leaves the
  /// whole spreadsheet.
  void clear() => leave(_row);
}
