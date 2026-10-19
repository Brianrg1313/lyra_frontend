
/// What a row's background is painted with.
///
/// They are the three states a whole row can be in, and they are here —and not
/// as two loose booleans in each cell— because they are mutually exclusive and
/// have an order: the cursor beats the mouse. A row where you are standing and
/// over which the pointer is hovering looks like the row where you are standing;
/// if it were the other way, passing the mouse over the sheet would cover the
/// only trace of where one had been.
enum SheetRowFill {
  /// The usual background: the zebra, which alternates by position.
  plain,

  /// The row the mouse is over (`table.over`).
  over,

  /// The row where the cursor is (`table.rowSelected`).
  selected,

  /// A cell inside the range selected together ([SheetSelection]). It is the cell's and not
  /// its row's, and it beats the other three: the range is what the next action acts on.
  range
}
