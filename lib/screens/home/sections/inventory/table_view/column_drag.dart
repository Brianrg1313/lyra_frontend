import 'package:flutter/material.dart';

// PACKAGES
import 'package:provider/provider.dart';

// WIDGETS
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_controller.dart';

import './column_drag_ghost.dart';
import './sheet_theme.dart';

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
  static const double line = 2;

  @override
  Widget build(BuildContext context) {
    final drag = context.read<SheetController>().drag;
    final style = SheetTheme.of(context);

    return ValueListenableBuilder<bool>(
      valueListenable: drag.active,
      builder: (context, active, _) => active
        ? ColumnDragGhost(drag: drag, style: style)
        : const SizedBox.shrink()
    );
  }
}
