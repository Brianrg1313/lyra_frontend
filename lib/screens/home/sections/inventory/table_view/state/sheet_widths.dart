import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// The width of each column of the spreadsheet.
///
/// Each column has **its own** [ValueNotifier] instead of a map with a single
/// `notifyListeners`, and that's the whole point: dragging a column's edge
/// fires pointer events at screen speed, and with a global notice each of
/// those frames would rebuild all visible cells. This way only the column
/// being dragged finds out; its cells change width, the `Row` containing them
/// re-arranges itself, and the sibling columns aren't rebuilt, only shifted.
///
/// Widths don't belong to this session: each field brings its own in the
/// structure and they're adopted when the table opens ([adopt]), so everyone
/// sees the columns at the same measure. What's dragged travels to the
/// backend on drop, and there's the reason for [_pinned]: since a column was
/// touched in this screen, the width that rules is this one. A re-read of the
/// structure —adding a column, renaming another— arrives with the width that
/// was stored when the request went out, which can be older than the one just
/// dragged.
class SheetWidths {
  SheetWidths({
    required this.defaultWidth,
    required this.minWidth,
    this.maxWidth = 1200,
    double? compactWidth
  }) : compactWidth = compactWidth ?? defaultWidth;

  /// Width of a column that hasn't been resized yet.
  final double defaultWidth;

  /// Width of a column that hasn't been resized and whose cells hold only a mark (a
  /// yes / no's switch): at the usual one it would be mostly blank.
  final double compactWidth;

  /// Minimum width to which a column can be dragged, so it can't be collapsed
  /// until it disappears.
  final double minWidth;

  /// Maximum width to which a column can be dragged. It's the other end of the
  /// same thing: a column of thousands of pixels covers the whole
  /// spreadsheet, and besides the width is saved, so leaving it without a
  /// ceiling would leave a table that opens that way for everyone.
  final double maxWidth;

  final Map<String, ValueNotifier<double>> _widths = {};

  /// Columns whose width this screen already decides: the ones that were
  /// dragged and the ones that already adopted the saved one. It's what keeps
  /// [adopt] from overwriting a drag with the width a re-read structure
  /// brings.
  final Set<String> _pinned = {};

  /// Sum of all the columns' widths. Only the `SizedBox` that gives the
  /// scrollable band its width listens to it.
  final ValueNotifier<double> total = ValueNotifier(0);

  /// The current columns, in order, by their width key.
  List<String> _keys = const [];

  /// The width of that column, as something to subscribe to.
  ValueNotifier<double> of(String key) =>
    _widths.putIfAbsent(key, () => ValueNotifier(defaultWidth));

  /// The width of that column, without subscribing. It's used by the geometry
  /// calculations (bringing a cell into view), which run outside the build.
  double valueOf(String key) => _widths[key]?.value ?? defaultWidth;

  double widthAt(int index) =>
    index >= 0 && index < _keys.length ? valueOf(_keys[index]) : 0;

  /// How much there is to the left of column [index].
  double offsetOf(int index) {
    double left = 0;
    for (int i = 0; i < index && i < _keys.length; i++) {
      left += valueOf(_keys[i]);
    }
    return left;
  }

  int get length => _keys.length;

  /// The left edges of all columns, plus the end of the last one (one value
  /// more than there are columns).
  ///
  /// It's the whole horizontal geometry of the spreadsheet solved in one
  /// pass, and it exists for column drag: without it, each pointer event —one
  /// per frame— would have to sum the widths again to know which neighbor
  /// it's over. It's computed once when the drag starts, which is when it's
  /// known the widths won't move: a width and a column can't be dragged at
  /// the same time.
  List<double> edges() {
    final edges = List<double>.filled(_keys.length + 1, 0);

    for (int index = 0; index < _keys.length; index++) {
      edges[index + 1] = edges[index] + valueOf(_keys[index]);
    }

    return edges;
  }

  /// Tells it which the columns are right now. The controller calls it each
  /// time the spreadsheet gains or loses one.
  void setKeys(List<String> keys) {
    _keys = keys;
    _recount();
  }

  /// Drags a column's width.
  void resize(String key, double delta) {
    // From the moment it's dragged, the width of this column is ruled by the
    // screen: the one a re-read structure brings no longer touches it.
    _pinned.add(key);

    // Already at an extreme, keeping dragging toward that side changes
    // nothing: without this guard every drag frame would notify anyway.
    if (!_write(key, valueOf(key) + delta)) return;

    _recount();
  }

  /// Adopts the width the column was saved with, the first time it's seen.
  ///
  /// It's what makes the table open the way the last person who arranged it
  /// left it, and **only the first time**: a structure is re-read on any
  /// column change, and the one arriving can bring a width older than the one
  /// just dragged. A [width] that isn't a width (`0`, negative) is ignored:
  /// that column was never resized and gets the usual one.
  void adopt(String key, double width) {
    if (width <= 0 || !_pinned.add(key)) return;
    if (!_write(key, width)) return;

    _recount();
  }

  /// Measures a column that nobody sized to what its type needs ([width]), without pinning
  /// it: a saved or dragged width still rules ([adopt], [resize]), and a column whose type
  /// changes is measured again.
  void suggest(String key, double width) {
    if (_pinned.contains(key)) return;
    if (!_write(key, width)) return;

    _recount();
  }

  /// Returns the column to the width it had, after a drag the backend didn't
  /// accept. It's the equivalent of `SheetColumns.restoreOrder` for width:
  /// what is seen applies instantly and the save travels behind, so if it
  /// doesn't go through it has to be undone.
  void restore(String key, double width) {
    if (!_write(key, width)) return;
    _recount();
  }

  /// Sets the column to [width], clamped to what can be measured. Returns
  /// `false` if that changed nothing, which is what avoids notifying too
  /// much.
  bool _write(String key, double width) {
    final notifier = of(key);
    final value = math.min(maxWidth, math.max(minWidth, width));

    if (value == notifier.value) return false;

    notifier.value = value;
    return true;
  }

  void _recount() {
    double sum = 0;
    for (final key in _keys) {
      sum += valueOf(key);
    }
    total.value = sum;
  }

  void dispose() {
    for (final notifier in _widths.values) {
      notifier.dispose();
    }
    _widths.clear();
    _pinned.clear();
    total.dispose();
  }
}
