import 'package:flutter/material.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/stock/tables/table_view_model.dart';
import 'package:app/services/stock/tables/table_view_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_draft.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_drafts.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_hover.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_shape.dart';

import './cell.dart';

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
class RecordRow extends StatelessWidget {
  const RecordRow({
    super.key,
    required this.index,
    required this.shape
  });

  final int index;

  /// The shape of the sheet: one column per key, in order.
  final SheetShape shape;

  @override
  Widget build(BuildContext context) {
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
    // changing rows. The highlight is then painted by each cell, which is the
    // one that knows what color its background is (see [SheetStyle.cell]).
    final hover = context.read<SheetHover>();

    return MouseRegion(
      onEnter: (_) => hover.enter(index),
      onExit: (_) => hover.leave(index),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (position, key) in shape.keys.indexed)
            SheetCellView(
              row: index,
              position: position,
              slot: shape.slots[position],
              widthKey: key,
              record: record,
              saved: saved,
              draft: draft
            )
        ]
      )
    );
  }
}
