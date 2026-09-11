import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

import 'body.dart';
import 'column_drag.dart';
import 'fields_row.dart';
import 'gutter.dart';
import 'sheet_style.dart';
import 'state/sheet_columns.dart';
import 'state/sheet_controller.dart';

/// The sheet: the frozen band of row numbers and, next to it, the data one with
/// the fields row on top and the records below.
///
/// It takes all it is given: there is no footer, so the last visible row reaches
/// the edge and keeps scrolling down from there.
///
/// This widget is only rebuilt when **the shape** of the grid changes: a column
/// that is added, deleted, or dragged elsewhere, or the size of the window.
/// Nothing more. Renaming a column or changing its type **does not pass through
/// here**, even though both re-read the whole structure: what is listened to is
/// [SheetColumns.shape], which stays the same, and the title and the type are
/// asked by each cell on its own.
///
/// Dragging a column does not pass through here **while it lasts** either: what
/// moves with the pointer is the ghost of [ColumnDrag], drawn on top. The grid
/// finds out a single time, on release.
///
/// The rest (the cursor, the widths, the chunks of records that keep arriving,
/// what is written) is listened to by the cells and the rows, each to its own.
class Sheet extends StatelessWidget {
  const Sheet({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<SheetController>();

    // The shape keeps its instance while the columns do not change in quantity,
    // place, or which side they read from, so comparing it by identity is
    // enough.
    final shape = context.select<SheetColumns, SheetShape>(
      (columns) => columns.shape
    );

    final style = SheetStyle(
      scheme: ThemeColor.of(context),
      rowHeight: controller.metrics.rowHeight,
      gutterWidth: controller.metrics.gutterWidth
    );

    return SheetTheme(
      style: style,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // How many rows are seen at once: it is what decides how many blank
          // rows are left over, so the sheet always reaches the bottom.
          final visible = controller.metrics.visibleRows(constraints.maxHeight);
          final available = math.max(
            0.0,
            constraints.maxWidth - style.gutterWidth
          );

          // The automatic scrollbars of each band are turned off to show only
          // one vertical (the whole sheet's) and one horizontal.
          return Focus(
            focusNode: controller.grid,
            onKeyEvent: controller.handleKey,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                scrollbars: false
              ),
              child: Scrollbar(
                controller: controller.vBody,
                notificationPredicate: (n) => n.metrics.axis == Axis.vertical,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SheetGutter(visible: visible),
                    Expanded(child: Scrollbar(
                      controller: controller.horizontal,
                      notificationPredicate: (n) =>
                        n.metrics.axis == Axis.horizontal,
                      child: SingleChildScrollView(
                        controller: controller.horizontal,
                        scrollDirection: Axis.horizontal,
                        child: ValueListenableBuilder<double>(
                          valueListenable: controller.widths.total,
                          builder: (context, total, child) => SizedBox(
                            width: math.max(total, available),
                            child: child
                          ),
                          // A column's drag is drawn on top of the grid and in
                          // the same coordinates. It receives no touches: the
                          // drag is carried by the cell the column was grabbed
                          // from.
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  FieldsRow(shape: shape),
                                  Expanded(child: SheetBody(
                                    shape: shape,
                                    visible: visible
                                  ))
                                ]
                              ),
                              const IgnorePointer(child: ColumnDrag())
                            ]
                          )
                        )
                      )
                    ))
                  ]
                )
              )
            )
          );
        }
      )
    );
  }
}
