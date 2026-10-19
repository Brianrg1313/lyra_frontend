import 'package:flutter_test/flutter_test.dart';

import 'package:app/screens/home/sections/inventory/table_view/state/sheet_cell.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_selection.dart';

void main() {
  test('a range holds every cell between its two ends, whichever way it was stretched', () {
    const range = SheetRange(SheetCell(4, 3), SheetCell(1, 1));

    expect((range.top, range.bottom, range.left, range.right), (1, 4, 1, 3));
    expect((range.rows, range.columns), (4, 3));
    expect(range.contains(2, 2), isTrue);
    expect(range.contains(0, 2), isFalse);
    expect(range.contains(2, 4), isFalse);
    expect(range.cells.first, const SheetCell(1, 1));
    expect(range.cells.length, 12);
  });

  test('one cell is no range: stretching to the cursor clears it', () {
    final selection = SheetSelection();
    var notices = 0;
    selection.addListener(() => notices++);

    selection.stretch(const SheetCell(0, 0), const SheetCell(2, 1));
    expect(selection.contains(1, 1), isTrue);

    selection.stretch(const SheetCell(0, 0), const SheetCell(2, 1));
    expect(notices, 1, reason: "the same range doesn't repaint");

    selection.stretch(const SheetCell(0, 0), const SheetCell(0, 0));
    expect(selection.range, isNull);
    expect(notices, 2);
  });
}
