import 'package:flutter/material.dart';

// WIDGETS
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_drag.dart';

import './column_drag.dart';
import './sheet_style.dart';

class ColumnDragGhost extends StatelessWidget {
  const ColumnDragGhost({super.key, required this.drag, required this.style});

  final SheetDrag drag;
  final SheetStyle style;

  @override
  Widget build(BuildContext context) => Stack(children: [
    // Where it is being taken from: the column stays in place until it is
    // released, barely veiled so you can see it is the one traveling.
    Positioned(
      left: drag.from,
      top: 0,
      bottom: 0,
      width: drag.width,
      child: ColoredBox(color: style.accent.withValues(alpha: 0.08))
    ),

    // Where it will land.
    ValueListenableBuilder<int>(
      valueListenable: drag.edge,
      builder: (context, edge, child) => Positioned(
        left: drag.edgeAt(edge) - ColumnDrag.line / 2,
        top: 0,
        bottom: 0,
        width: ColumnDrag.line,
        child: child!
      ),
      child: ColoredBox(color: style.accent)
    ),

    // The column's title following the pointer, like the header torn off the
    // fields row.
    ValueListenableBuilder<double>(
      valueListenable: drag.x,
      builder: (context, x, child) => Positioned(
        left: x,
        top: 0,
        height: style.rowHeight,
        width: drag.width,
        child: child!
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: style.headerFill.withValues(alpha: 0.95),
          border: Border.all(color: style.accent)
        ),
        child: Padding(
          padding: style.cellPadding,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              drag.label,
              overflow: TextOverflow.ellipsis,
              style: style.title
            )
          )
        )
      )
    )
  ]);
}
