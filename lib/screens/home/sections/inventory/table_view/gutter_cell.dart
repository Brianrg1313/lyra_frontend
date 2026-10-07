import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/stock/tables/table_view_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_controller.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_cursor.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_drafts.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_hover.dart';

import './sheet_row_fill.dart';
import './sheet_theme.dart';

/// A row's number, or the spinner of the one being saved.
///
/// It listens to two small things: whether the cursor is on its row (to
/// highlight it) and whether that row's draft is traveling. **There is no
/// button**: a written row saves itself on leaving it (see [SheetController]),
/// and the only thing this band has to show is that the create is on its way.
class GutterCell extends StatelessWidget {
  const GutterCell({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final style = SheetTheme.of(context);

    final records = context.select<TableViewService, int>(
      (service) => service.records
    );

    // The subscription is always requested, even if the row is a record and
    // cannot have a draft: it must be the same on each build so as not to depend
    // on the order in which they were registered.
    final saving = context.select<SheetDrafts, bool>(
      (drafts) => index >= records
        && (drafts.at(index - records)?.saving ?? false)
    );

    final selected = context.select<SheetCursor, bool>(
      (cursor) => cursor.isRow(index)
    );

    final hovered = context.select<SheetHover, bool>(
      (hover) => hover.at(index)
    );

    // The number is highlighted with its row —otherwise the highlight would cut
    // off exactly where it starts— and it also turns it on: passing the mouse
    // over the number is being over that row, even though the band of numbers
    // is another list.
    return MouseRegion(
      onEnter: (_) => context.read<SheetHover>().enter(index),
      onExit: (_) => context.read<SheetHover>().leave(index),
      child: DecoratedBox(
        decoration: style.gutter(fill: selected
          ? SheetRowFill.selected
          : hovered
            ? SheetRowFill.over
            : SheetRowFill.plain),
        child: Center(child: saving
          ? SizedBox(
              width: AppSize.text,
              height: AppSize.text,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: style.accent
              )
            )
          // The fields row is 1, so the first record is row 2.
          : Text("${index + 2}", style: style.number))
      )
    );
  }
}
