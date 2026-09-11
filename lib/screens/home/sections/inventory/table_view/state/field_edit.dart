/// What to do with a field when leaving its cell, according to what was
/// written.
///
/// The spreadsheet has no buttons to add, rename, or delete a column: the
/// three things are the same —writing in the field's cell— and the only thing
/// that distinguishes them is what was there before and what was left after.
/// That rule lives apart from the screen because it has to be readable at a
/// glance (and testable without mounting the spreadsheet).
enum FieldEdit {
  /// The title stayed as it was: entering and leaving the cell sends nothing.
  none,

  /// A free column that got a title written: creation of the field.
  create,

  /// A field with a different title: rename.
  rename,

  /// A field whose title was erased: deletion. It's the only one that asks
  /// first, because it takes the column and everything loaded in it.
  delete;

  /// Decides the case of the field-row cell that was just left.
  ///
  /// [isField] says whether the column is already a field of the table or is
  /// still one of the free ones at the end, [current] is the title it had and
  /// [text] what was left written. Spaces don't count: a title with only
  /// spaces is an empty title.
  static FieldEdit of({
    required bool isField,
    required String current,
    required String text
  }) {
    final name = text.trim();

    // A free column left blank stays free: there's nothing to create nor
    // delete.
    if (!isField) return name.isEmpty ? FieldEdit.none : FieldEdit.create;

    if (name == current.trim()) return FieldEdit.none;

    return name.isEmpty ? FieldEdit.delete : FieldEdit.rename;
  }
}
