import 'package:flutter/foundation.dart';

import './sheet_order.dart';

/// The drag of a column, while it lasts.
///
/// It's what changes most often in the whole spreadsheet —a pointer event per
/// frame, like a width drag— so it **can't touch the grid**. What moves is a
/// ghost drawn on top of the cells; the columns don't find out about anything
/// until it's dropped, and then they reorder all at once.
///
/// That's why there are three notifiers and not one:
///
/// - [active] notifies when the drag starts and ends. It's two notices per
///   drag and the only thing that mounts and unmounts the ghost.
/// - [x] moves with the pointer, and only the ghost listens to it.
/// - [edge] changes when the column passes the middle of a neighbor, which is
///   the only thing that moves the line.
///
/// With a single notifier, each drag frame would repaint the three things; and
/// if the state lived in the columns, it would repaint the whole spreadsheet.
///
/// Everything else ([source], [label], [width], [edges]) is fixed at the
/// start and doesn't change: widths can't be dragged while a column is
/// moving, so the geometry is computed **once** and from then on each pointer
/// event is a subtraction and a lookup over a list of `double`.
///
/// The coordinates are **those of the content** of the scrollable band (0 is
/// the left edge of the first column, not of the screen), which are the same
/// ones [edges] sit in and in which the ghost is drawn. Whoever translates
/// the pointer into those coordinates is the controller, which is the one
/// that knows where the band stands.
class SheetDrag {
  /// Column being dragged, or `-1` if there's no drag.
  int source = -1;

  /// Title of that column, for the ghost.
  String label = "";

  /// Width of that column.
  double width = 0;

  /// Which part of the cell it was grabbed by. It's what keeps the ghost from
  /// jumping under the pointer when it starts moving.
  double grab = 0;

  /// Left edges of all columns, plus the end of the last one.
  List<double> edges = const [];

  /// How many of those columns are fields of the table: past them are the free
  /// ones, and nothing can be dropped there.
  int fields = 0;

  /// Whether a column is in the air.
  final ValueNotifier<bool> active = ValueNotifier(false);

  /// Left edge of the ghost.
  final ValueNotifier<double> x = ValueNotifier(0);

  /// Edge where the column would land if it were dropped right now.
  final ValueNotifier<int> edge = ValueNotifier(-1);

  /// Where edge [index] is, to draw the line.
  double edgeAt(int index) =>
    index >= 0 && index < edges.length ? edges[index] : 0;

  /// Where the column being dragged starts, to mark it.
  double get from => edgeAt(source);

  void start({
    required int source,
    required String label,
    required double grab,
    required List<double> edges,
    required int fields
  }) {
    this.source = source;
    this.label = label;
    this.grab = grab;
    this.edges = edges;
    this.fields = fields;
    width = edges[source + 1] - edges[source];

    edge.value = source;
    x.value = edges[source];
    active.value = true;
  }

  /// The pointer is at [pointer] (in content coordinates).
  ///
  /// The edge where it would land is computed from the **middle of the
  /// ghost** and not from the pointer: it's the ghost that's seen moving, so
  /// it's what has to decide when the line jumps. Grabbing a wide column at
  /// one end and watching the pointer's position would read as the line
  /// lagging behind.
  void moveTo(double pointer) {
    final left = pointer - grab;
    x.value = left;

    final at = dropEdgeAt(edges, left + width / 2, columns: fields);
    if (at == edge.value) return;

    edge.value = at;
  }

  /// Ends the drag and returns which column was dropped and at which edge, or
  /// `(-1, -1)` if there was none in the air.
  (int, int) stop() {
    if (!active.value) return (-1, -1);

    final moved = (source, edge.value);

    active.value = false;
    source = -1;
    label = "";
    width = 0;
    grab = 0;
    edges = const [];
    fields = 0;

    return moved;
  }

  void dispose() {
    active.dispose();
    x.dispose();
    edge.dispose();
  }
}
