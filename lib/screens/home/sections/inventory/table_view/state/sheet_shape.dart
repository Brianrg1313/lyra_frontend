


/// The **shape** of the spreadsheet: how many columns there are, which one
/// goes in each place, and where what's shown in it comes from.
///
/// They're two parallel lists, as long as there are columns, and both are
/// needed because the order in which columns are **seen** and the order in
/// which **data** sits stopped being the same once they can be dragged:
///
/// - [keys] is how the width of each column is remembered (its FIELD_ID, or
///   its place if it isn't a field yet). It goes in the order in which columns
///   are seen.
/// - [slots] says, for each column, which position of the row its value sits
///   at. Records arrive aligned to the fields **exactly as the structure
///   provides them** and stay there: moving a column doesn't touch a single
///   datum read, it only changes where it's looked up.
///
/// It's a single thing and not two because it's what the spreadsheet listens
/// to in order to know if it has to rebuild the grid: while it's the same
/// instance, the columns are the same, sit in the same place, and read from
/// the same side.
class SheetShape {
  const SheetShape(this.keys, this.slots);

  static const SheetShape empty = SheetShape([], []);

  /// Width key of each column, in the order in which they're seen.
  final List<String> keys;

  /// Position inside the row from which each column's value comes.
  final List<int> slots;

  int get length => keys.length;
}
