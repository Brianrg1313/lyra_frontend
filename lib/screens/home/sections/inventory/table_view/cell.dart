import 'package:flutter/material.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/inventory/table_field_type.dart';
import 'package:app/services/stock/tables/table_view_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/inventory/table_view/cells/_cells.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_cell.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_columns.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_controller.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_cursor.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_draft.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_hover.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_widths.dart';

import './cell_editor.dart';
import './sheet_row_fill.dart';
import './sheet_theme.dart';

/// A cell of the sheet body.
///
/// It listens to exactly four things, and none of the four is the screen:
///
/// - **The cursor**: how it is (its border) and whether the cursor is on its row
///   (the background, which belongs to the whole row). Moving the cursor
///   triggers the comparator of all visible cells and rebuilds the two rows that
///   changed.
/// - **Whether the mouse is over its row**, which is the same but for the
///   pointer highlight: one boolean per cell and two rows repainted per
///   movement.
/// - **The width of its column**, which has its own notifier: dragging the edge
///   of a column does not touch the others, and within this one the width is the
///   only thing that is redone —the content is passed as `child` and survives
///   the whole drag intact.
/// - **The type of its column** (and with it, the symbol with which its numbers
///   are written), which is what decides which editor is used to write and which
///   way it aligns. It is asked here and not received from the row so that
///   changing a field's type repaints that column and not the grid: the rest of
///   the cells run a comparator that comes out the same as always and is not
///   redone.
///
/// Its value it does not listen to: it is handed to it already made ([saved] for
/// a record, [draft] for a row being written). The draft one is read from the
/// object on each build on purpose: while writing, the editor shows it, and when
/// the editor closes this cell is already rebuilding because of the cursor, so
/// that is where it reads the text that was left.
class SheetCellView extends StatelessWidget {
  const SheetCellView({
    super.key,
    required this.row,
    required this.position,
    required this.slot,
    required this.widthKey,
    required this.record,
    required this.saved,
    required this.draft
  });

  /// Body row (0 is the first record).
  final int row;

  /// Position of the column within the sheet: where it is seen.
  final int position;

  /// Which place of the row its value comes from.
  ///
  /// It is not the same as [position] since columns are dragged: the records
  /// arrive aligned to the fields just as the structure gives them and stay
  /// there, so moving a column into place does not touch a single read datum,
  /// it only changes where its cell looks for it.
  final int slot;

  /// Key with which the column's width is remembered.
  final String widthKey;

  /// Whether the row is a table record or one of the ones being written.
  final bool record;

  /// This row's record, or `null` if its chunk has not arrived yet.
  final TableRowModel? saved;

  /// This row's draft, or `null` if nothing has been written in it yet.
  final SheetDraft? draft;

  @override
  Widget build(BuildContext context) {
    final style = SheetTheme.of(context);
    final controller = context.read<SheetController>();

    // The two things the cursor tells a cell, in a single subscription: how it
    // is (which decides its border) and whether the cursor is on its row (which
    // decides the background of the whole row). They go together because both
    // are answered from the same datum and at the same moment: asking them
    // separately would run two comparators per cell on each cursor move.
    final (state, inCursorRow) = context
      .select<SheetCursor, (SheetCellState, bool)>(
        (cursor) => (cursor.stateAt(row, position), cursor.isRow(row))
      );

    // And whether the mouse is over its row. It is a boolean, so moving the
    // pointer from one row to another runs the comparator of the visible cells
    // and rebuilds the two rows that changed.
    final hovered = context.select<SheetHover, bool>(
      (hover) => hover.at(row)
    );

    // The type, if the column is already a field, and the symbol with which its
    // numbers are written: all three come from the same column and at the same
    // moment, so they go in a single subscription. The unit is empty in almost
    // all of them —only a price, an amount, and a measure carry one— and there
    // it costs nothing.
    final (code, isField, unit) = context
      .select<SheetColumns, (String, bool, String)>(
        (columns) => (
          columns.typeOf(position),
          columns.isFieldAt(position),
          columns.unitOf(position)
        )
      );

    final type = TableFieldType.from(code);

    // A free column has nowhere to store yet (there is no FIELD_ID), so its
    // cells are seen but not written until the column is created. And a record
    // is written once it has arrived with its id: without it there is no row of
    // the table to send the change to.
    final editable = isField
      && type.editable
      && (!record || (saved?.id.isNotEmpty ?? false));

    // A record's stock is not written but moved: a tap unfolds the movements
    // ([SheetStockMoves]), so it reads and points like something that opens.
    final moves = record
      && type == TableFieldType.stock
      && controller.stock != null
      && (saved?.id.isNotEmpty ?? false);

    // How the datum looks is decided by its type, not by this cell: each type
    // that displays differently has its widget in `cells/` (see [SheetCells.value]).
    final Widget content = state == SheetCellState.editing
      ? CellEditor(type: type, alignment: type.alignment)
      : SheetCells.value(
          type: type,
          value: record
            ? saved?.at(slot)?.toString() ?? ""
            : draft?.values[slot] ?? "",
          // The value without converting to text, for the only type that does
          // not store one: an image stores the list of ids of its gallery (see
          // [ImageCell]).
          raw: record ? saved?.at(slot) : draft?.values[slot],
          alignment: type.alignment,
          // The column's symbol, for the types whose number does not bring its
          // own (see [TableFieldType.united]).
          unit: unit,
          // The text the AI indexes by meaning always goes with the brand color,
          // whether writable or not: it is what distinguishes it from a datum
          // entered by hand. The fields the backend carries (counter, stock)
          // look like one more datum, but dimmed.
          style: type.semantic
            ? style.semanticValue
            : editable || moves || record ? style.value : style.readOnlyValue,
          row: row,
          column: position,
          // The column key, not its position: it is with it that a date
          // remembers in which format it is being read (see [DateCell]), just
          // like the width.
          columnKey: widthKey,
          editable: editable,
          // Only an empty, writable SKU offers to build itself: see
          // [SkuCell].
          onGenerateSku: editable && type == TableFieldType.sku
            ? () => controller.generateSku(SheetCell(row, position))
            : null,
          // A measure's unit is the column's: its button changes it for every
          // row (see [UnitCell]).
          onPickUnit: editable && type == TableFieldType.measure
            ? (anchor) => controller.pickUnit(position, anchor)
            : null,
          // A date's calendar opens from its button; the cell itself is written (see
          // [DateCell]).
          onPickDate: editable && row != kFieldsRow && type.isDate
            ? (anchor) => controller.pickDate(SheetCell(row, position), anchor)
            : null
        );

    return ValueListenableBuilder<double>(
      valueListenable: context.read<SheetWidths>().of(widthKey),
      builder: (context, width, child) => SizedBox(width: width, child: child),
      child: MouseRegion(
        // The pointer says what can be done there before touching: the one for
        // writing where it is written and the one for a button where something
        // unfolds (a list, an image). The type decides it, like the alignment.
        // Where nothing is written —what the backend carries, a row that has not
        // arrived— neither of the two appears: offering them would be promising
        // something that does not happen.
        cursor: moves
          ? SystemMouseCursors.click
          : editable ? type.cursor : SystemMouseCursors.basic,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // The cell's context goes with the touch because there is a type that
          // opens something anchored to it: a list unfolds its options where the
          // cell is, and that needs to know what place of the screen it
          // occupies. It is this context and not the `GestureDetector`'s on
          // purpose: the first render that hangs from it is the whole column's
          // box, which is where the dropdown has to hang from.
          onTap: () => controller.tap(row, position, anchor: context),
          child: Container(
            alignment: type.alignment == TextAlign.right
              ? Alignment.centerRight
              : Alignment.centerLeft,
            // The types that are chosen draw their own frame inside (see
            // [SelectCell]), so instead of a text's air they get a frame's:
            // even on all four sides, or top and bottom would press against the
            // grid and blend in with it.
            padding: type.picker ? style.framePadding : style.cellPadding,
            decoration: style.cell(
              row: row,
              selected: state != SheetCellState.idle,
              // The cursor beats the mouse: the row where you are standing shows
              // as such even if the pointer is passing over it.
              fill: inCursorRow
                ? SheetRowFill.selected
                : hovered
                  ? SheetRowFill.over
                  : SheetRowFill.plain
            ),
            child: content
          )
        )
      )
    );
  }
}
