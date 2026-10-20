part of '../sheet_controller.dart';

/// Several cells at once: the range stretched from the cursor (Shift+click, Shift+arrows) and
/// the menu of the cells (right click), which acts on the range or on the one cell clicked.
extension SheetRanges on SheetController {
  /// Stretches the range from the cursor's cell to [to]. Only the body is selected together:
  /// `false`, and nothing done, when there is no cursor or either end is the fields row.
  ///
  /// The cursor stays where it was, selected and without its editor (what it had written is
  /// sent, like leaving it), and the grid takes the keys: the range is gone through, not typed.
  bool stretchTo(SheetCell to) {
    final anchor = cursor.cell;
    if (anchor == null || anchor.row == kFieldsRow || to.row == kFieldsRow) return false;

    close();
    selection.stretch(anchor, to);

    grid.requestFocus();
    reveal(to);
    return true;
  }

  /// Shift+arrows: moves the range's far end [rows] rows and [columns] columns, within the
  /// rows drawn; from the cursor when there is no range yet.
  bool stretchBy({required int rows, required int columns}) {
    final from = selection.range?.focus ?? cursor.cell;
    final last = this.columns.length - 1;
    if (from == null || last < 0) return false;

    return stretchTo(SheetCell(
      (from.row + rows).clamp(0, math.max(0, _rows - 1)),
      (from.column + columns).clamp(0, last)
    ));
  }

  /// The cells' menu for a right click (or a long press) on [cell] (see [ContextMenuRegion]).
  ///
  /// Inside the range it acts on the range; anywhere else that cell is selected first, the way
  /// a spreadsheet does, and the menu acts on it alone. What it offers is [sheetActions] that
  /// fit the target ([SheetAction.offers]); with none it doesn't open.
  List<ContextEntry> menuEntries(SheetCell cell, BuildContext context) {
    final range = selection.range;
    final target = range != null && range.contains(cell.row, cell.column)
      ? range
      : SheetRange.single(cell);

    if (target.single) select(cell);

    final aimed = SheetTarget(
      range: target,
      types: [for (var column = target.left; column <= target.right; column++) typeAt(column)]
    );

    return [
      for (final action in sheetActions)
        if (action.offers(this, aimed)) ContextItem(
          label: action.label(context),
          icon: action.icon,
          shortcut: action.shortcut,
          onSelected: () {
            if (!_disposed) action.run(this, aimed);
          }
        )
    ];
  }
}
