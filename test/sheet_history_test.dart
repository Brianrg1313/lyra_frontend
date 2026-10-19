import 'package:flutter_test/flutter_test.dart';

import 'package:app/screens/home/sections/inventory/table_view/state/sheet_cell.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_history.dart';

/// A cell holding a value, and the change that wrote [to] over what it had.
class _Cell {
  _Cell(this.at, this.value);

  final SheetCell at;
  String value;

  SheetChange write(String to) {
    final from = value;
    value = to;

    return SheetChange(
      undo: () {
        value = from;
        return at;
      },
      redo: () {
        value = to;
        return at;
      }
    );
  }
}

void main() {
  test('undo writes back what a cell had and redo writes it again', () {
    final history = SheetHistory();
    final cell = _Cell(const SheetCell(0, 0), "a");

    history.push(cell.write("b"));
    history.push(cell.write("c"));

    expect(history.undo(), [const SheetCell(0, 0)]);
    expect(cell.value, "b");
    expect(history.undo(), isNotNull);
    expect(cell.value, "a");
    expect(history.undo(), isNull, reason: "nothing left to undo");

    history.redo();
    expect(cell.value, "b");
    expect(history.canRedo, isTrue);
  });

  test('a new change forgets what was undone', () {
    final history = SheetHistory();
    final cell = _Cell(const SheetCell(0, 0), "a");

    history.push(cell.write("b"));
    history.undo();
    history.push(cell.write("z"));

    expect(history.canRedo, isFalse);
    expect(history.redo(), isNull);
  });

  test('a group is one step, undone last change first', () {
    final history = SheetHistory();
    final first = _Cell(const SheetCell(0, 0), "a");
    final second = _Cell(const SheetCell(1, 2), "x");

    history.group(() {
      history.push(first.write("b"));
      history.push(second.write("y"));
      history.group(() => history.push(first.write("c")));
    });

    expect(history.undo(), [const SheetCell(0, 0), const SheetCell(1, 2), const SheetCell(0, 0)]);
    expect((first.value, second.value), ("a", "x"));
    expect(history.canUndo, isFalse, reason: "the three changes were one step");
  });

  test('a change with nowhere to go leaves an empty step, and the oldest go past the limit', () {
    final history = SheetHistory(limit: 2);

    history.push(SheetChange(undo: () => null, redo: () => null));
    expect(history.undo(), isEmpty);

    final cell = _Cell(const SheetCell(0, 0), "0");
    for (final value in ["1", "2", "3"]) {
      history.push(cell.write(value));
    }

    history.undo();
    history.undo();
    expect(cell.value, "1");
    expect(history.canUndo, isFalse);
  });

  test('it notifies when what can be undone changes', () {
    final history = SheetHistory();
    var notices = 0;
    history.addListener(() => notices++);

    history.push(SheetChange(undo: () => null, redo: () => null));
    history.undo();
    history.clear();

    expect(notices, 3);
  });
}
