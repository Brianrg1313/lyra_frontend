import 'package:flutter/material.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/stock/tables/table_view_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_controller.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_shape.dart';

import './record_row.dart';

/// The body of the sheet: the records and, below, the blank rows that are
/// written.
///
/// `itemExtent` is not an optional optimization, it is what makes the screen
/// possible: with fixed-height rows the list knows how tall it is without
/// building any, so a table with hundreds of thousands of records opens and
/// scrolls as fast as one of ten. Without it, measuring the height would force
/// building them all.
///
/// `addAutomaticKeepAlives` is off for the same reason: the rows have no state
/// to preserve (what is written lives in the drafts, not in the widget), and at
/// this scale not even the bookkeeping of keeping them alive is worth it.
class SheetBody extends StatelessWidget {
  const SheetBody({
    super.key,
    required this.shape,
    required this.visible
  });

  /// The shape of the sheet: one column per key, in order.
  final SheetShape shape;

  /// How many rows fit on screen. The sheet layout measures it, and it is what
  /// ensures there are always blank rows all the way down.
  final int visible;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<SheetController>();

    // While searching there are no blank rows below: what is seen are the
    // matches and it ends there (see [SheetMetrics.bodyRows]). It is the only
    // thing the body asks the service, and it only changes when starting or
    // stopping a search.
    final searching = context.select<TableViewService, bool>(
      (service) => service.isSearching
    );

    return ValueListenableBuilder<int>(
      valueListenable: controller.usedRows,
      builder: (context, used, _) {
        final rows = controller.metrics.bodyRows(
          used: used,
          visible: visible,
          blanks: !searching
        );

        // The keyboard and the chunked reading need to know how far the sheet
        // reaches. It is a bare assignment, it notifies no one: whoever reads
        // it does so after the frame.
        controller.setRows(rows);

        return ListView.builder(
          controller: controller.vBody,
          padding: EdgeInsets.zero,
          itemExtent: controller.metrics.rowHeight,
          itemCount: rows,
          addAutomaticKeepAlives: false,
          itemBuilder: (context, index) => RecordRow(index: index, shape: shape)
        );
      }
    );
  }
}
