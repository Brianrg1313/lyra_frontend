part of '../sheet_controller.dart';

/// A made table's records: the row number opens what the record consumes, and so does the
/// stock cell of one made to order (it has no shelf to move: `product_is_composite`). One made by
/// the batch keeps its shelf, moved like any stock.
extension SheetMadeRecords on SheetController {
  /// Whether [row] is a made record already read with its id.
  bool isMadeRecord(int row) {
    if (made == null || row == kFieldsRow || row >= service.records) return false;

    return service.rowAt(row)?.id.isNotEmpty ?? false;
  }

  /// Whether [cell] is a made record's stock cell with no shelf of its own: unread counts as
  /// none, the backend refuses to move it anyway.
  bool _madeStock(SheetCell cell) {
    if (!isMadeRecord(cell.row) || typeAt(cell.column) != TableFieldType.stock) return false;

    final consumes = service.consumesOf(service.rowAt(cell.row)!.id);

    return consumes == null || consumes.recipe.mode == RecipeMode.order;
  }

  /// Opens what the record at [row] consumes.
  Future<void> openMade(int row) async {
    final record = service.rowAt(row);
    final made = this.made;
    if (made == null || record == null || record.id.isEmpty) return;

    await made.open(record, nameOf(record.values));
  }

  /// What a row is called: its first title column with something written, else its first text.
  String nameOf(List<dynamic> values) {
    final fields = service.fields;

    for (final wanted in const [TableFieldType.title, TableFieldType.text]) {
      for (final (index, field) in fields.indexed) {
        if (TableFieldType.from(field.type) != wanted || index >= values.length) continue;

        final text = values[index]?.toString().trim() ?? "";
        if (text.isNotEmpty) return text;
      }
    }

    return "";
  }
}
