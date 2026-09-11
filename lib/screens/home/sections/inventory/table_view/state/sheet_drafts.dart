import 'package:flutter/foundation.dart';

/// A written, unsaved row. Stores each cell's text by column position and
/// whether that particular row is being sent, so the spinner on its row number
/// affects only the row being saved.
class SheetDraft {
  final Map<int, String> values = {};
  bool saving = false;

  /// `true` if the row has something written: it's what makes it saveable.
  bool get hasData => values.values.any((value) => value.trim().isNotEmpty);
}

/// The written rows that haven't been saved yet, in the order in which they
/// appear below the backend's records.
///
/// A blank row **has no draft**: one is only created when something is written
/// in it, so the dozens of empty rows the spreadsheet shows (and the hundreds
/// of thousands of record rows above them) cost nothing.
///
/// Notifies only when something visible changes: a row going from empty to
/// written —there the spreadsheet gains a row and another blank appears
/// behind—, starting or finishing saving, or being removed. Each key, on the
/// other hand, doesn't notify: the editor of that cell already shows the text.
///
/// That last saving works **because there's an editor in front**. The cells
/// that don't have one —a list, chosen in a dropdown— leave their value via
/// [choose], which always notifies: there the only thing showing what was
/// chosen is the cell itself, and without a notice nobody rebuilds.
class SheetDrafts extends ChangeNotifier {
  final List<SheetDraft> _drafts = [];

  int get length => _drafts.length;

  /// The draft of that row, or `null` if nothing has been written in it yet.
  SheetDraft? at(int index) =>
    index >= 0 && index < _drafts.length ? _drafts[index] : null;

  /// What's written in that cell.
  String textAt(int index, int column) => at(index)?.values[column] ?? "";

  /// Dumps the text of a cell that's being **written**.
  ///
  /// A cell left empty is erased from the draft, so a row that's emptied
  /// stops counting as pending. It only notifies if the row changed state:
  /// writing the second letter doesn't move anything on screen, because what
  /// is being written is already shown by that cell's editor.
  void write(int index, int column, String text) => _put(index, column, text);

  /// Dumps the value of a cell that's **chosen** (a list).
  ///
  /// It's [write] but always notifying when the value changes: a list cell has
  /// no editor in front, so what's chosen isn't seen until the cell itself
  /// rebuilds, and what rebuilds it is this notice. It's once per choice —a
  /// tap on a dropdown— and not once per key, which is what [write] saves.
  void choose(int index, int column, String value) =>
    _put(index, column, value, silent: false);

  /// The dumping of a cell into the draft. [silent] is the only thing that
  /// distinguishes the two ways of leaving a value: whether it's enough for
  /// the row to notify when its state changes, or if it also has to notify
  /// when only the value changed.
  void _put(int index, int column, String text, {bool silent = true}) {
    if (index < 0) return;

    final had = at(index)?.hasData ?? false;
    final before = textAt(index, column);

    if (text.trim().isEmpty) {
      at(index)?.values.remove(column);
    } else {
      // Only here does the blank row become a draft: writing is what creates
      // it, not selecting it.
      while (_drafts.length <= index) {
        _drafts.add(SheetDraft());
      }
      _drafts[index].values[column] = text;
    }

    if (had != (at(index)?.hasData ?? false)) {
      notifyListeners();
      return;
    }

    if (silent || before == textAt(index, column)) return;
    notifyListeners();
  }

  void setSaving(SheetDraft draft, bool saving) {
    if (draft.saving == saving) return;

    draft.saving = saving;
    notifyListeners();
  }

  /// Removes a row that's already persisted: it's now a record of the table.
  ///
  /// Whoever removes it has to do so **at the same instant** the table starts
  /// counting the new record: the rows down here are located by subtracting
  /// the number of records, so one thing without the other moves them out of
  /// place (see `SheetController._dropPersisted`).
  void remove(SheetDraft draft) {
    if (!_drafts.remove(draft)) return;
    notifyListeners();
  }

  void clear() {
    if (_drafts.isEmpty) return;

    _drafts.clear();
    notifyListeners();
  }
}
