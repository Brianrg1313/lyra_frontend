import 'package:flutter_test/flutter_test.dart';

import 'package:app/screens/home/sections/inventory/table_view/state/sheet_widths.dart';

SheetWidths _widths() =>
  SheetWidths(defaultWidth: 100, minWidth: 40, maxWidth: 400, compactWidth: 60)
    ..setKeys(["a", "b", "c"]);

void main() {
  test('a column nobody touched has the usual width', () {
    final widths = _widths();

    expect(widths.valueOf("a"), 100);
    expect(widths.total.value, 300);
  });

  test('dragging notifies only the dragged column', () {
    // It is the whole reason each column has its own notifier: a drag sends one
    // event per frame, and with a global notice each of those frames would rebuild
    // every cell on screen.
    final widths = _widths();

    int a = 0;
    int b = 0;
    widths.of("a").addListener(() => a += 1);
    widths.of("b").addListener(() => b += 1);

    widths.resize("a", 25);

    expect(widths.valueOf("a"), 125);
    expect(a, 1);
    expect(b, 0, reason: "the next column only shifts, it is not rebuilt");
  });

  test('a column cannot be collapsed until it disappears', () {
    final widths = _widths();

    widths.resize("a", -500);

    expect(widths.valueOf("a"), 40);
  });

  test('at the minimum, dragging further does not notify', () {
    // Without this guard, leaning against the edge would keep repainting that
    // column on every frame of the drag.
    final widths = _widths();
    widths.resize("a", -500);

    int notices = 0;
    widths.of("a").addListener(() => notices += 1);

    widths.resize("a", -50);

    expect(notices, 0);
  });

  test('the total width follows the drags', () {
    // It is what gives the scrollable band its width: without it, the sheet
    // could not be scrolled to the end of its last column.
    final widths = _widths();

    widths.resize("b", 60);

    expect(widths.total.value, 360);
  });

  test('adding a column adds it to the total', () {
    final widths = _widths();

    widths.setKeys(["a", "b", "c", "d"]);

    expect(widths.total.value, 400);
  });

  test('a column cannot be stretched without end either', () {
    // The width is saved and everyone sees it: a column thousands of pixels wide
    // would leave the table that way for everyone.
    final widths = _widths();

    widths.resize("a", 5000);

    expect(widths.valueOf("a"), 400);
  });

  test('a column opens with the width it was saved with', () {
    final widths = _widths();

    widths.adopt("a", 250);

    expect(widths.valueOf("a"), 250);
    expect(widths.total.value, 450);
  });

  test('a column never dragged has the usual width', () {
    // That is how the ones without a saved width arrive: there is nothing to adopt.
    final widths = _widths();

    widths.adopt("a", 0);

    expect(widths.valueOf("a"), 100);
  });

  test('a saved width does not overwrite one just dragged', () {
    // The structure is re-read on any column change (creating another, renaming
    // one) and arrives with the width saved when the request went out: it can be
    // older than the drag still travelling.
    final widths = _widths();

    widths.resize("a", 60);
    widths.adopt("a", 250);

    expect(widths.valueOf("a"), 160);
  });

  test('a saved width is adopted only once', () {
    // Second re-read of the structure: the screen already decides that column.
    final widths = _widths();

    widths.adopt("a", 250);
    widths.resize("a", -50);
    widths.adopt("a", 250);

    expect(widths.valueOf("a"), 200);
  });

  test('a width that could not be saved goes back to the one it had', () {
    final widths = _widths();

    widths.resize("a", 80);
    widths.restore("a", 100);

    expect(widths.valueOf("a"), 100);
    expect(widths.total.value, 300);
  });

  test('the position of a column is what lies to its left', () {
    // Bringing a cell into view uses it while the keyboard walks the sheet.
    final widths = _widths();
    widths.resize("a", 50);

    expect(widths.offsetOf(0), 0);
    expect(widths.offsetOf(1), 150);
    expect(widths.offsetOf(2), 250);
    expect(widths.widthAt(0), 150);
  });

  test('a column nobody sized takes the width its type suggests', () {
    // A yes / no is only a switch: at the usual width it would be mostly blank.
    final widths = _widths();

    widths.suggest("a", widths.compactWidth);

    expect(widths.valueOf("a"), 60);
    expect(widths.total.value, 260);
  });

  test('a suggestion follows a type change but never a sized column', () {
    final widths = _widths();

    widths.suggest("a", widths.compactWidth);
    widths.suggest("a", widths.defaultWidth);
    expect(widths.valueOf("a"), 100, reason: "it stopped being a yes / no");

    widths.adopt("b", 250);
    widths.suggest("b", widths.compactWidth);
    expect(widths.valueOf("b"), 250, reason: "a saved width rules");

    widths.resize("c", 20);
    widths.suggest("c", widths.compactWidth);
    expect(widths.valueOf("c"), 120, reason: "a dragged width rules");
  });
}
