
/// A written, unsaved row. Stores each cell's text by column position and
/// whether that particular row is being sent, so the spinner on its row number
/// affects only the row being saved.
class SheetDraft {
  final Map<int, String> values = {};
  bool saving = false;

  /// `true` if the row has something written: it's what makes it saveable.
  bool get hasData => values.values.any((value) => value.trim().isNotEmpty);
}
