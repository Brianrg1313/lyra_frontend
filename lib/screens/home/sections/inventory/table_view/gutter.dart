import 'package:flutter/material.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/stock/tables/table_view_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_controller.dart';

import './gutter_cell.dart';
import './sheet_theme.dart';

/// The frozen column on the left: at the top the corner (the number of the
/// fields row, which is 1) and below the number of each row, which on the one
/// being saved gives way to a spinner.
class SheetGutter extends StatelessWidget {
  const SheetGutter({super.key, required this.visible});

  final int visible;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<SheetController>();
    final style = SheetTheme.of(context);

    // The band of numbers enumerates exactly the body's rows, so it counts the
    // same as it: while searching there are no blank rows to number.
    final searching = context.select<TableViewService, bool>(
      (service) => service.isSearching
    );

    return SizedBox(
      width: style.gutterWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The corner carries the row height by hand: it is the only cell not
          // inside an `itemExtent`, and without it it would shrink to its text's
          // height, shifting the whole band of numbers up relative to the rows
          // it enumerates.
          SizedBox(
            height: style.rowHeight,
            child: DecoratedBox(
              decoration: style.gutter(),
              child: Center(child: Text("1", style: style.number))
            )
          ),
          Expanded(child: ValueListenableBuilder<int>(
            valueListenable: controller.usedRows,
            builder: (context, used, _) => ListView.builder(
              controller: controller.vGutter,
              padding: EdgeInsets.zero,
              itemExtent: style.rowHeight,
              itemCount: controller.metrics.bodyRows(
                used: used,
                visible: visible,
                blanks: !searching
              ),
              addAutomaticKeepAlives: false,
              itemBuilder: (context, index) => GutterCell(index: index)
            )
          ))
        ]
      )
    );
  }
}
