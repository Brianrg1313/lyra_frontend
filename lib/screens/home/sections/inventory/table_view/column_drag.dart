import 'package:flutter/material.dart';

// PACKAGES
import 'package:provider/provider.dart';

import 'sheet_style.dart';
import 'state/sheet_controller.dart';
import 'state/sheet_drag.dart';

/// What is seen while a column is in the air: the one being carried, the ghost
/// that follows the pointer, and the line that marks where it will land.
///
/// It is drawn **on top** of the sheet and in the same coordinates (those of the
/// scrollable band's content), so nothing needs to be corrected for the scroll:
/// if the band moves, this moves with it.
///
/// And it is not a presentation detail: it is what allows dragging a column to
/// not touch the grid. The cells only learn of the change on release; until then
/// the only things moving on screen are these three, and each listens to its own
/// notifier:
///
/// - That there is a drag is listened to by this widget, which is two notices
///   per drag.
/// - The ghost listens to where the pointer is, which changes every frame, and
///   its content goes as `child`: it moves without being rebuilt.
/// - The line listens to which edge it would land on, which only changes when
///   passing the middle of a neighbor.
///
/// The band that marks the column being carried listens to nothing: it is fixed
/// when the drag starts and does not move until release.
class ColumnDrag extends StatelessWidget {
  const ColumnDrag({super.key});

  /// Width of the line that marks the edge where it will land.
  static const double _line = 2;

  @override
  Widget build(BuildContext context) {
    final drag = context.read<SheetController>().drag;
    final style = SheetTheme.of(context);

    return ValueListenableBuilder<bool>(
      valueListenable: drag.active,
      builder: (context, active, _) => active
        ? _Ghost(drag: drag, style: style)
        : const SizedBox.shrink()
    );
  }
}

class _Ghost extends StatelessWidget {
  const _Ghost({required this.drag, required this.style});

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
        left: drag.edgeAt(edge) - ColumnDrag._line / 2,
        top: 0,
        bottom: 0,
        width: ColumnDrag._line,
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
