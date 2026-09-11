import 'package:flutter/foundation.dart';

/// Which date columns are being looked at in full.
///
/// A date is read in two different ways and both are needed: written
/// (`Feb 12, 2026`) is the one understood at a glance, and in figures with its
/// time (`2026-02-12 12:30 PM`) is the one that gets compared, copied, and
/// audited. The cell's button switches from one to the other.
///
/// **It belongs to the column, not the cell.** A date column is read as a
/// strip: if each row could be in a different format, two dates of the same
/// column would stop being comparable at a glance, which is exactly what a
/// spreadsheet has to give. So the button of any row changes the whole
/// column, like the format of an Excel column.
///
/// It's remembered by the column's key —the FIELD_ID, the same one with which
/// [SheetWidths] remembers its width— and not by its position: dragging the
/// column out of place carries the format with it.
///
/// It's its own notifier, and tiny, for the same reason as the rest: changing
/// the format must cost the cells of that column and nothing else. Each date
/// cell subscribes to **its** key, so the comparator of the others returns
/// the usual thing and they don't rebuild.
class SheetDates extends ChangeNotifier {
  final Set<String> _full = {};

  /// Whether that column is being looked at in figures with time.
  bool isFull(String column) => _full.contains(column);

  /// Switches the column from one reading to the other.
  void toggle(String column) {
    if (!_full.remove(column)) _full.add(column);
    notifyListeners();
  }
}
