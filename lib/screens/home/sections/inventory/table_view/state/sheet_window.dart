import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// The columns a row builds: from [first] to [last], after [lead] pixels standing for the
/// columns to their left, which are measured and not built.
///
/// It is what keeps a wide table as cheap as a narrow one: the horizontal band is as wide as
/// every column together, but each row builds the ones the band shows and one more on each
/// side, so sixty columns cost the same as the fifteen that fit on screen.
@immutable
class SheetSpan {
  const SheetSpan(this.first, this.last, this.lead);

  /// Every column: what a row builds before the band has measured itself.
  static const SheetSpan all = SheetSpan(0, 1 << 30, 0);

  final int first;
  final int last;
  final double lead;

  /// The columns seen with the band at [offset] across [viewport], [margin] more on each
  /// side, out of [edges] (`SheetWidths.edges`: each column's left edge and the end of the
  /// last one). The columns in [keep] stay built wherever the band is, and so do the ones
  /// between them and the band: a row is one run of cells.
  factory SheetSpan.of(
    List<double> edges, {
    required double offset,
    required double viewport,
    int margin = 1,
    Iterable<int> keep = const []
  }) {
    final count = edges.length - 1;
    if (count <= 0) return const SheetSpan(0, -1, 0);

    var first = _columnAt(edges, offset) - margin;
    var last = _columnAt(edges, offset + viewport) + margin;

    for (final column in keep) {
      if (column < 0 || column >= count) continue;
      first = math.min(first, column);
      last = math.max(last, column);
    }

    first = first.clamp(0, count - 1);
    last = last.clamp(first, count - 1);

    return SheetSpan(first, last, edges[first]);
  }

  /// The column whose box holds [x]: the last one with its left edge at or before it.
  static int _columnAt(List<double> edges, double x) {
    var low = 0, high = edges.length - 2;

    while (low < high) {
      final middle = (low + high + 1) >> 1;
      if (edges[middle] <= x) {
        low = middle;
      } else {
        high = middle - 1;
      }
    }

    return low;
  }

  bool contains(int column) => column >= first && column <= last;

  @override
  bool operator ==(Object other) =>
    other is SheetSpan && other.first == first && other.last == last && other.lead == lead;

  @override
  int get hashCode => Object.hash(first, last, lead);
}

/// The [SheetSpan] the rows build, as something to subscribe to.
///
/// It notifies only when the span changes: scrolling sideways within a column, or dragging
/// a width that moves no edge across the band's, reaches no row.
class SheetWindow extends ChangeNotifier {
  SheetSpan _span = SheetSpan.all;

  SheetSpan get span => _span;

  void update(SheetSpan span) {
    if (span == _span) return;

    _span = span;
    notifyListeners();
  }

  /// Sets the span without notifying, for the sheet's layout: the band's width is known
  /// there, and the rows read the span right after, in the same build.
  void measure(SheetSpan span) => _span = span;
}
