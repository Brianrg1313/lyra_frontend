import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/screens/home/sections/inventory/table_view/state/sheet_keys.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_cell.dart';

/// What a key asks outside the editor (going through the sheet).
SheetKeyIntent? _key(LogicalKeyboardKey key, {bool shift = false}) =>
  SheetKeyIntent.of(key, shift: shift, editing: false);

/// The same, with the cell open and being typed in.
SheetKeyIntent? _typing(LogicalKeyboardKey key, {bool shift = false}) =>
  SheetKeyIntent.of(key, shift: shift, editing: true);

SheetCommand? _command(
  LogicalKeyboardKey key, {
  bool control = false,
  bool shift = false,
  bool writing = false
}) => SheetCommand.of(key, control: control, shift: shift, writing: writing);

void main() {
  group('what each key asks', () {
    test('Tab goes to the next cell and Shift+Tab to the previous one', () {
      expect(_key(LogicalKeyboardKey.tab), SheetKeyIntent.nextCell);
      expect(
        _key(LogicalKeyboardKey.tab, shift: true),
        SheetKeyIntent.previousCell
      );
    });

    test('Enter goes down a row, like a spreadsheet', () {
      expect(_key(LogicalKeyboardKey.enter), SheetKeyIntent.rowDown);
      expect(_key(LogicalKeyboardKey.numpadEnter), SheetKeyIntent.rowDown);
      expect(
        _key(LogicalKeyboardKey.enter, shift: true),
        SheetKeyIntent.rowUp
      );
    });

    test('while typing, the side arrows belong to the text', () {
      // They move the caret within what is being typed, which is what an open
      // cell is expected to do.
      expect(_typing(LogicalKeyboardKey.arrowRight), isNull);
      expect(_typing(LogicalKeyboardKey.arrowLeft), isNull);

      // Without an editor, they change column.
      expect(_key(LogicalKeyboardKey.arrowRight), SheetKeyIntent.columnRight);
      expect(_key(LogicalKeyboardKey.arrowLeft), SheetKeyIntent.columnLeft);
    });

    test('the up and down arrows always belong to the grid', () {
      expect(_typing(LogicalKeyboardKey.arrowDown), SheetKeyIntent.rowDown);
      expect(_typing(LogicalKeyboardKey.arrowUp), SheetKeyIntent.rowUp);
    });

    test('Escape only cancels when something is being typed', () {
      expect(_typing(LogicalKeyboardKey.escape), SheetKeyIntent.cancel);
      expect(
        _key(LogicalKeyboardKey.escape),
        isNull,
        reason: "without an editor, Escape closes whatever is open above"
      );
    });

    test('any other key goes on its way', () {
      expect(_key(LogicalKeyboardKey.keyA), isNull);
    });
  });

  group('the history and the range', () {
    test('Ctrl+Z undoes, Ctrl+Y and Ctrl+Shift+Z redo', () {
      expect(_command(LogicalKeyboardKey.keyZ, control: true), SheetCommand.undo);
      expect(_command(LogicalKeyboardKey.keyY, control: true), SheetCommand.redo);
      expect(
        _command(LogicalKeyboardKey.keyZ, control: true, shift: true),
        SheetCommand.redo
      );
      expect(_command(LogicalKeyboardKey.keyZ), isNull, reason: "a bare z is typed");
    });

    test('while typing, Ctrl+Z still reaches the sheet and redoing belongs to the text', () {
      // The sheet takes back what was typed before it undoes the history.
      expect(
        _command(LogicalKeyboardKey.keyZ, control: true, writing: true),
        SheetCommand.undo
      );
      expect(_command(LogicalKeyboardKey.keyY, control: true, writing: true), isNull);
      expect(
        _command(LogicalKeyboardKey.keyZ, control: true, shift: true, writing: true),
        isNull
      );
    });

    test('Shift+arrows stretch the range, unless something is being typed', () {
      expect(
        _command(LogicalKeyboardKey.arrowDown, shift: true)?.stretch,
        (rows: 1, columns: 0)
      );
      expect(
        _command(LogicalKeyboardKey.arrowLeft, shift: true)?.stretch,
        (rows: 0, columns: -1)
      );
      expect(_command(LogicalKeyboardKey.arrowDown), isNull);
      expect(_command(LogicalKeyboardKey.arrowDown, shift: true, writing: true), isNull);
      expect(_command(LogicalKeyboardKey.enter, shift: true), isNull);
    });
  });

  group('where the cursor lands', () {
    /// A sheet of four columns (the last one is 3).
    SheetCell move(
      SheetCell from,
      SheetKeyIntent intent, {
      int lastColumn = 3
    }) {
      final step = intent.move!;

      return sheetDestination(
        from: from,
        rows: step.rows,
        columns: step.columns,
        wrap: step.wrap,
        lastColumn: lastColumn
      );
    }

    test('Tab on the last column continues on the row below', () {
      expect(
        move(const SheetCell(2, 3), SheetKeyIntent.nextCell),
        const SheetCell(3, 0)
      );
    });

    test('Shift+Tab on the first column goes back to the end of the row above', () {
      expect(
        move(const SheetCell(2, 0), SheetKeyIntent.previousCell),
        const SheetCell(1, 3)
      );
    });

    test('the right arrow stays stuck to the last edge', () {
      // No wrap: the arrow doesn't change row.
      expect(
        move(const SheetCell(2, 3), SheetKeyIntent.columnRight),
        const SheetCell(2, 3)
      );
    });

    test('going up reaches the fields row and stops there', () {
      // The fields row is one more row of the sheet and is gone through the
      // same, but there is nothing above it.
      expect(
        move(const SheetCell(0, 1), SheetKeyIntent.rowUp),
        const SheetCell(kFieldsRow, 1)
      );
      expect(
        move(const SheetCell(kFieldsRow, 1), SheetKeyIntent.rowUp),
        const SheetCell(kFieldsRow, 1)
      );
    });

    test('going down has no limit: the sheet goes on', () {
      // Going past the last row adds another blank one, and that is solved by
      // whoever knows how many there are, not by this count.
      expect(
        move(const SheetCell(999999, 0), SheetKeyIntent.rowDown),
        const SheetCell(1000000, 0)
      );
    });

    test('with a single column, Tab goes down a row', () {
      expect(
        move(const SheetCell(1, 0), SheetKeyIntent.nextCell, lastColumn: 0),
        const SheetCell(2, 0)
      );
    });
  });
}
