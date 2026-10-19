import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

import './sheet_row_fill.dart';

/// Everything the cells need to paint themselves, resolved **only once** per
/// sheet.
///
/// A cell has nothing of its own to decide: the background color, the border,
/// and the typography are the same for all, and only change according to four
/// states (even or odd zebra row, selected or not). If each one built them on
/// its own —which is what used to happen— each repaint would allocate a new
/// [BoxDecoration] and [TextStyle] per cell, and since Flutter compares those
/// objects to decide whether it needs to repaint, two equal but distinct objects
/// force it to repaint anyway.
///
/// Here they are built once and shared: the cells receive **the same instance**
/// and the engine can skip the repaint.
class SheetStyle {
  SheetStyle({
    required this.scheme,
    required this.rowHeight,
    required this.gutterWidth
  }) : cellPadding = EdgeInsets.symmetric(horizontal: AppSize.spaceXS),
       framePadding = EdgeInsets.all(AppSize.gap),
       frameRadius = AppSize.gap,
       // All four sides are **always** there, and the two that are not the grid
       // go transparent. A border takes up space: if the cursor's only appeared
       // when selecting the cell, entering it would eat a pixel per side from
       // the content and the text would jump —right when it is about to be
       // written, which is when it is most noticeable—. This way the box
       // measures the same selected or not, and the only thing that changes when
       // selecting it is the color.
       _line = Border(
         top: const BorderSide(color: Colors.transparent),
         left: const BorderSide(color: Colors.transparent),
         right: BorderSide(color: scheme.table.lines),
         bottom: BorderSide(color: scheme.table.lines)
       ),
       _selected = Border.all(color: scheme.table.currentCell),
       value = TextStyle(fontSize: AppSize.text, color: scheme.text.primary),
       readOnlyValue = TextStyle(
         fontSize: AppSize.text,
         color: scheme.text.secondary
       ),
       semanticValue = TextStyle(fontSize: AppSize.text, color: scheme.primary),
       title = TextStyle(
         fontSize: AppSize.text,
         fontWeight: FontWeight.w600,
         color: scheme.text.primary
       ),
       pendingTitle = TextStyle(
         fontSize: AppSize.text,
         fontWeight: FontWeight.w600,
         color: scheme.text.secondary
       ),
       number = TextStyle(
         fontSize: AppSize.text * 0.85,
         color: scheme.text.secondary
       ),
       symbol = TextStyle(fontSize: AppSize.text, color: scheme.text.secondary),
       code = TextStyle(fontSize: AppSize.text, color: scheme.text.secondary);

  final SchemeColor scheme;
  final double rowHeight;
  final double gutterWidth;

  final EdgeInsets cellPadding;

  /// The air of a cell that draws **its own frame** inside (the list one, which
  /// looks like a dropdown's button).
  ///
  /// It is even on all four sides, and there lies the difference with
  /// [cellPadding]: that one separates text from the borders and only makes
  /// sense on the sides, but a frame that rests top and bottom against the grid
  /// blends in with it. It keeps the frame detached from the cell equally,
  /// which is what makes it read as something **inside** the cell and not as the
  /// cell itself.
  final EdgeInsets framePadding;

  /// How much that frame is rounded. It is a short radius on purpose: the usual
  /// one ([AppSize.corner]) is a card's, and in a box the height of a row it
  /// eats the corners.
  final double frameRadius;

  /// A cell's two borders: the usual one (the grid to the right and below,
  /// `table.lines`, and the other two sides transparent) and the cursor's (all
  /// four sides, `table.currentCell`).
  ///
  /// Both measure the same —one pixel per side, all four sides always— and that
  /// is the whole point: selecting a cell changes a color and not the box, so
  /// the content does not move.
  final Border _line;
  final Border _selected;

  /// Color of what marks where you are standing: the line of where a dragged
  /// column will land, the veil over the one traveling, and the spinner of the
  /// row being saved. It is the same as the cursor's border (`table.currentCell`),
  /// so everything that marks position reads as a single thing.
  ///
  /// It goes here and not in each piece so that no sheet colors remain outside
  /// this class: the ones that use it already receive the style.
  late final Color accent = scheme.table.currentCell;

  /// Background of the bands that are not data —the fields row and the numbers
  /// one— and of a dragged column's ghost header. It is `table.headers`.
  late final Color headerFill = scheme.table.headers;

  /// Text of a writable cell, and of a non-writable one (the fields the backend
  /// carries: they look like one more datum, but dimmed).
  final TextStyle value;
  final TextStyle readOnlyValue;

  /// Text of a cell the backend indexes by meaning: the product's name and
  /// description (see [TableFieldType.semantic]).
  ///
  /// It goes with the brand color and **always the same**: whether written or
  /// not, whether the cursor's cell or not. It is the only thing in the sheet
  /// the AI searches for, and that difference is what the color tells. That is
  /// why it is not dimmed like [readOnlyValue] either: that it is not written by
  /// hand is not what must be said about it.
  final TextStyle semanticValue;

  /// A field's title, and the same while the change travels: it is already what
  /// will remain, but it has not yet come back from the backend.
  final TextStyle title;
  final TextStyle pendingTitle;

  /// Row number of the left band.
  final TextStyle number;

  /// What accompanies a value without being the value: the currency symbol of a
  /// price, and whatever of the same nature comes after. It goes gray next to
  /// the datum so it can be read at a glance which is the number and which the
  /// unit.
  final TextStyle symbol;

  /// The text of a code: the SKU.
  ///
  /// It goes gray and not with the data color because a code is not a datum to
  /// be read: it is a label with which the product is found. No one compares two
  /// SKUs at a glance like comparing two prices, so in a sheet full of them that
  /// column does not have to weigh like the others —on the contrary, in black it
  /// is the one that makes the most noise, because they are the longest and most
  /// unreadable strings—.
  ///
  /// It is written like any cell: gray does not mean dimmed (see
  /// [readOnlyValue], which is another thing even though they look similar
  /// today).
  final TextStyle code;

  /// Decoration of a body cell.
  ///
  /// They are two independent things: the **border** is decided by the cursor
  /// ([selected] is this cell, not its row) and the **background** by the whole
  /// row ([fill]). That is why they travel separately: the cursor's cell carries
  /// its frame inside a row that is already highlighted, and not the other way
  /// around.
  ///
  /// [row] is only looked at when the background is the usual one, which is the
  /// zebra: that one alternates by position and not by what the row is (see
  /// [_cells]).
  BoxDecoration cell({
    required int row,
    required bool selected,
    SheetRowFill fill = SheetRowFill.plain
  }) => _cells[switch (fill) {
    SheetRowFill.plain => row.isOdd ? 2 : 0,
    SheetRowFill.over => 4,
    SheetRowFill.selected => 6,
    SheetRowFill.range => 8
  } + (selected ? 1 : 0)];

  /// Fill of the frame of a cell that looks like a control (the list one).
  ///
  /// It must detach from **its** row's background, and there is the detail:
  /// with the zebra the sheet uses its two surfaces every other row (see
  /// [_cells]), so there is no single color that stands out on both. In the
  /// light theme, a frame the color of an even row disappears over an even one
  /// and shows over an odd one; with the other it is the opposite.
  ///
  /// That is why the frame carries **the one its row is not using**: it is
  /// always the other, so it always shows, in both themes and both zebra bands.
  Color frameFill({required int row}) =>
    row.isOdd ? scheme.table.background : scheme.table.even;

  /// Decoration of a fields-row cell.
  BoxDecoration field({required bool selected}) =>
    selected ? _fieldSelected : _field;

  /// Decoration of a numbers-band cell.
  ///
  /// It follows its row: the highlight cannot cut off at the number, or the row
  /// would end up half painted. That is why it takes the same [SheetRowFill] as
  /// the body and not a boolean of its own.
  BoxDecoration gutter({SheetRowFill fill = SheetRowFill.plain}) =>
    switch (fill) {
      SheetRowFill.plain => _gutter,
      SheetRowFill.over => _gutterOver,
      SheetRowFill.selected || SheetRowFill.range => _gutterSelected
    };

  /// The zebra: even rows go over `table.background`, the background of any
  /// row, and odd ones over `table.even`, which the scheme offers precisely to
  /// tell a row apart from the one next to it.
  ///
  /// It alternates by **position** and nothing more: the records and the blank
  /// rows below are one continuous grid, so the band keeps going and does not
  /// cut off where the loaded data ends.
  /// The five backgrounds a cell can have —the two zebra bands, the one the
  /// mouse is over, the cursor's row and the range's— each with its two borders. The order is
  /// the one [cell] builds: in pairs, first the grid border and then the
  /// cursor's.
  late final List<BoxDecoration> _cells = [
    BoxDecoration(color: scheme.table.background, border: _line),
    BoxDecoration(color: scheme.table.background, border: _selected),
    BoxDecoration(color: scheme.table.even, border: _line),
    BoxDecoration(color: scheme.table.even, border: _selected),
    BoxDecoration(color: scheme.table.over, border: _line),
    BoxDecoration(color: scheme.table.over, border: _selected),
    BoxDecoration(color: scheme.table.rowSelected, border: _line),
    BoxDecoration(color: scheme.table.rowSelected, border: _selected),
    BoxDecoration(color: _range, border: _line),
    BoxDecoration(color: _range, border: _selected)
  ];

  /// The range's fill: the cursor's color veiled over a row's, so the cells read as one block
  /// marked the way the cursor is, in both themes.
  late final Color _range = Color.alphaBlend(
    scheme.table.currentCell.withValues(alpha: 0.16),
    scheme.table.background
  );

  late final BoxDecoration _field =
    BoxDecoration(color: headerFill, border: _line);
  late final BoxDecoration _fieldSelected =
    BoxDecoration(color: headerFill, border: _selected);

  late final BoxDecoration _gutter =
    BoxDecoration(color: headerFill, border: _line);
  late final BoxDecoration _gutterOver =
    BoxDecoration(color: scheme.table.over, border: _line);
  late final BoxDecoration _gutterSelected =
    BoxDecoration(color: scheme.table.rowSelected, border: _line);
}
