/// A free column at the end of the spreadsheet: its title while it's being
/// written and whether it's already being created. It's an object and not a
/// loose string because the creation travels queued and has to find its
/// column afterwards, even if by then it has moved places.
class FreeColumn {
  String name = "";
  bool creating = false;

  /// A free column is blank while it has no title. The one being created never
  /// is: it already belongs to the table even if the backend doesn't return it
  /// yet.
  bool get isBlank => name.isEmpty && !creating;

  /// Leaves [columns] with exactly [free] blank columns at the end.
  ///
  /// It's the only rule of the spreadsheet's horizontal growth, and it applies
  /// after every title change: if the last free one was filled, another
  /// appears behind it; if one was emptied, the leftover one goes away. The
  /// ones in the middle are respected even if blank: they're a gap the user
  /// left on purpose.
  static void normalize(List<FreeColumn> columns, {int free = 2}) {
    while (columns.isNotEmpty && columns.last.isBlank) {
      columns.removeLast();
    }

    for (int i = 0; i < free; i++) {
      columns.add(FreeColumn());
    }
  }
}
