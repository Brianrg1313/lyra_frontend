import 'dart:math' as math;

import 'package:flutter/material.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/stock/tables/table_view_model.dart';
import 'package:app/services/stock/tables/table_view_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_cursor.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_draft.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_drafts.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_hover.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_shape.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_window.dart';

import './cell.dart';
import './sheet_row_fill.dart';
import './sheet_theme.dart';

/// A row of the sheet body.
///
/// It is the one that listens to **its** chunk of records, and that is why the
/// subscription lives here and not in each cell: when a page arrives the whole
/// row arrives, so rebuilding it whole is the right granularity, and there are a
/// few dozen comparators per page instead of several hundred.
///
/// A record whose chunk has not arrived yet is still a record —the row exists,
/// its place is reserved— so it is seen empty and not editable until it
/// arrives. That is why what matters is how many records the table has and not
/// that there is data.
///
/// Of the columns it knows nothing more than their shape: how many there are,
/// with which key each one's width is remembered, and from which place of the
/// row its value comes. The type is asked by each cell, so changing a field's
/// type does not pass through this row.
///
/// It builds only the columns the band shows ([SheetWindow]): the ones to their left are one
/// blank as wide as they are. Scrolling sideways builds only the cells that come in: the
/// ones that stay in view are the same widgets as before (see [_RecordRowState._cells]).
class RecordRow extends StatefulWidget {
  const RecordRow({
    super.key,
    required this.index,
    required this.shape
  });

  final int index;

  /// The shape of the sheet: one column per key, in order.
  final SheetShape shape;

  @override
  State<RecordRow> createState() => _RecordRowState();
}

class _RecordRowState extends State<RecordRow> {
  /// The cells already made, by column position, and what they were made from.
  ///
  /// A cell handed the same instance again is not built again (Flutter compares widgets by
  /// identity), so while the row, its record and its draft stay the ones they were, the
  /// cells are kept: the window moving sideways only makes the ones that come in. Anything
  /// else a cell shows (the cursor, its column's type, its width) it listens to on its own,
  /// and rebuilds itself when it changes.
  final Map<int, SheetCellView> _cells = {};
  Object? _madeFrom;

  @override
  Widget build(BuildContext context) {
    final index = widget.index;
    final shape = widget.shape;

    // The records and the table's length travel together: if how many there are
    // changes, the rows being written shift place and this one can go from being
    // a draft to being a record.
    final (records, saved) = context
      .select<TableViewService, (int, TableRowModel?)>(
        (service) => (service.records, service.rowAt(index))
      );

    final record = index < records;

    // It is always asked, even if the row is a record and there will be no
    // draft: the subscriptions must be the same on each build so as not to
    // depend on the order in which they were registered. Over a record this
    // costs nothing, because the index falls negative and there is nothing to
    // look up.
    final draft = context.select<SheetDrafts, SheetDraft?>(
      (drafts) => record ? null : drafts.at(index - records)
    );

    // Who announces where the mouse passes is the row and not each cell: one
    // notice per row instead of one per cell, and it is also the only one that
    // knows that moving **within** the row —from one column to the next— is not
    // changing rows. The highlight is painted under the cells ([RowBand]).
    final hover = context.read<SheetHover>();

    final span = context.select<SheetWindow, SheetSpan>((window) => window.span);
    final last = math.min(span.last, shape.length - 1);

    final from = (index, shape, record, saved, draft);
    if (from != _madeFrom) {
      _cells.clear();
      _madeFrom = from;
    }

    return MouseRegion(
      onEnter: (_) => hover.enter(index),
      onExit: (_) => hover.leave(index),
      child: RowBand(
        index: index,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (span.first > 0) SizedBox(width: span.lead),
            for (var position = span.first; position <= last; position++)
              _cells[position] ??= SheetCellView(
                key: ValueKey(shape.keys[position]),
                row: index,
                position: position,
                slot: shape.slots[position],
                widthKey: shape.keys[position],
                record: record,
                saved: saved,
                draft: draft
              )
          ]
        )
      )
    );
  }
}

/// A body row's background ([SheetStyle.band]): the zebra, the row the mouse is over, the
/// cursor's row.
///
/// It is a widget of its own so that is all that changes: the mouse crossing a row or the
/// cursor stepping into it rebuilds this box, and its [child] (the row's cells, the same
/// instance) is not built again.
class RowBand extends StatelessWidget {
  const RowBand({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cursor = context.select<SheetCursor, bool>((cursor) => cursor.isRow(index));
    final hovered = context.select<SheetHover, bool>((hover) => hover.at(index));

    return DecoratedBox(
      // The cursor beats the mouse: the row where you are standing shows as such even if the
      // pointer is passing over it.
      decoration: SheetTheme.of(context).band(
        row: index,
        fill: cursor
          ? SheetRowFill.selected
          : hovered ? SheetRowFill.over : SheetRowFill.plain
      ),
      child: child
    );
  }
}
