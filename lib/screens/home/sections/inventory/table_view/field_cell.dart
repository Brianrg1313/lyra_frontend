import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/inventory/table_field_type.dart';

import 'cell_editor.dart';
import 'sheet_style.dart';
import 'type_arrow.dart';
import 'state/sheet_columns.dart';
import 'state/sheet_controller.dart';
import 'state/sheet_cursor.dart';
import 'state/sheet_widths.dart';

/// A field's cell: row 1 of the sheet.
///
/// It behaves like any other cell, and there lies the whole point of the
/// screen: **the field is edited where you see it**. Typing a title into a free
/// column creates it, typing another into a field renames it, emptying it
/// deletes it (with confirmation), and the arrow changes its type. Who decides
/// which of the four things it is, on leaving the cell, is `FieldEdit`.
///
/// And from the same cell the column is grabbed to take it elsewhere. The drag
/// goes through here only to start it: the controller carries it and `ColumnDrag`
/// draws it over the sheet, so moving a column does not rebuild this cell or any
/// other until it is released.
///
/// It asks its own everything: the title, the type, and whether there is a
/// change on the way. That is why renaming a column, changing its type, or
/// sending its create repaints **this cell** and not the fields row, even
/// though all three re-read the whole table structure.
class FieldCell extends StatelessWidget {
  const FieldCell({
    super.key,
    required this.index,
    required this.widthKey
  });

  final int index;
  final String widthKey;

  @override
  Widget build(BuildContext context) {
    final style = SheetTheme.of(context);
    final controller = context.read<SheetController>();

    final state = context.select<SheetCursor, SheetCellState>(
      (cursor) => cursor.stateAt(kFieldsRow, index)
    );

    // The four things change together and are read together: a comparator looks
    // at them at once and saves three subscriptions per cell.
    final (name, busy, type, isField) = context
      .select<SheetColumns, (String, bool, String, bool)>(
        (columns) => (
          columns.nameOf(index),
          columns.busyAt(index),
          columns.typeOf(index),
          columns.isFieldAt(index)
        )
      );

    // The field's model is only needed by the arrow, to send the type change.
    // It is read without subscribing: what of it is shown —name and type— is
    // already above, so this cell is redone when it changes.
    final field = isField ? context.read<SheetColumns>().fieldAt(index) : null;

    // A field's title is written like a free column's: it is the same cell, and
    // what changes is that leaving it renames the field (or deletes it, if it
    // was left empty) instead of creating one.
    final Widget content = state == SheetCellState.editing
      ? const CellEditor(type: TableFieldType.text, alignment: TextAlign.left)
      : Row(children: [
          if (isField) ...[
            Icon(
              TableFieldType.from(type).icon,
              size: AppSize.text,
              color: style.scheme.text.secondary
            ),
            SizedBox(width: AppSize.gap)
          ],
          Expanded(child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            // While the change travels (it is being created, renamed, or
            // deleted), the title looks dimmed: it is already what will remain,
            // but it has not yet come back from the backend.
            style: busy ? style.pendingTitle : style.title
          )),
          // The type arrow is only where there is a field: a free column does
          // not yet have a type to change, it is a blank cell. Nor is it there
          // while the field has a change on the way: the type change also sends
          // the name the structure carries, which until the rename comes back is
          // the old one, and it would undo it.
          if (field != null && !busy) TypeArrow(field: field)
        ]);

    // A field is dragged into place from its own cell, like in a sheet. A free
    // column is not: it is not yet a field, it has no position to save. Nor one
    // with a change on the way.
    final movable = isField && !busy;

    Widget cell = MouseRegion(
      // The pointer announces that writing happens there: it is all that remains
      // of the add-column button, and now also of the rename one. It is the
      // write one and not the sheet's because what is there is a title that is
      // typed; what is touched of this cell —the type arrow— carries its own.
      // While the change travels, nothing can be written, so it goes back to the
      // usual pointer.
      cursor: busy ? SystemMouseCursors.basic : SystemMouseCursors.text,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => controller.tap(kFieldsRow, index),
        // The horizontal drag and the tap live together in the same detector:
        // the gesture arena gives the tap to the one that did not move and the
        // drag to the one that did, which is exactly how the cell is read —it is
        // tapped to write the title, it is dragged to move the column—. The
        // right-edge strip, which changes the width, sits above this in the
        // Stack, so it keeps the drag that starts there.
        onHorizontalDragStart: movable
          ? (details) => controller.startColumnDrag(index, details)
          : null,
        onHorizontalDragUpdate: movable ? controller.updateColumnDrag : null,
        onHorizontalDragEnd: movable
          ? (_) => controller.endColumnDrag()
          : null,
        onHorizontalDragCancel: movable ? controller.cancelColumnDrag : null,
        child: Container(
          alignment: Alignment.centerLeft,
          padding: style.cellPadding,
          decoration: style.field(selected: state != SheetCellState.idle),
          child: content
        )
      )
    );

    if (isField) {
      cell = Tooltip(
        message: TableFieldType.from(type).label(context),
        child: cell
      );
    }

    return ValueListenableBuilder<double>(
      valueListenable: context.read<SheetWidths>().of(widthKey),
      builder: (context, width, child) => SizedBox(width: width, child: child),
      child: Stack(children: [
        cell,
        // Width handle: the right-edge strip of the field cell, like in a sheet.
        // Dragging it only moves this column's notifier, so the rest of the
        // sheet does not even know.
        //
        // On release, the width saves with the field (`PUT /inventory/products/builder/fields/`):
        // it is not the preference of whoever dragged it but how the table
        // stays, and the next time it is opened —by whoever opens it— the
        // columns measure this. It travels on release and not on each drag
        // event.
        Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          width: AppSize.gap,
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeLeftRight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (_) => controller.startResize(index),
              onHorizontalDragUpdate: (details) =>
                controller.resize(index, details.delta.dx),
              onHorizontalDragEnd: (_) => controller.endResize(index),
              // A drag that is cut short (the pointer was lost, something opened
              // on top) leaves the column with the width it managed to take, so
              // it saves the same: it is the one that is seen.
              onHorizontalDragCancel: () => controller.endResize(index),
              child: const SizedBox.shrink()
            )
          )
        )
      ])
    );
  }
}
