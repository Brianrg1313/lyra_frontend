/// The `table/normalizing` notice: the backend started preparing an imported
/// table.
///
/// It is the near end of a wait whose far end is [TableReadyModel]. The
/// structure import (`POST /inventory/products/import/structure/<format>/`)
/// answers with the table's id as soon as its columns exist —all `text`, all
/// visible, named exactly as the file named them— and leaves the slow half
/// running behind the response: reading what each column holds, asking a
/// model what it means, tidying the names and giving the table its image
/// column.
///
/// Without this event that half is invisible. A table that is still being
/// built and one that finished look the same from here —columns, no rows—,
/// so any client that did not do the import itself would draw a half-made
/// table as if it were done. That is what it is for: the table shows up in
/// the listing while it is being prepared, and is not opened until
/// `table/ready` says it is.
///
/// **It always arrives**, also when the import asked not to normalize
/// (`NORMALIZE=0`, which pairs it with an immediate `table/ready`), so both
/// can be waited for unconditionally instead of guessing which imports
/// produce them.
class TableNormalizingModel {
  /// Name of the event on the socket. It is a contract handwritten on both
  /// sides —here and in `Normalizer.prepare`—, so it lives in a single
  /// constant: a misspelled event does not fail, it just never arrives.
  static const String event = "table/normalizing";

  const TableNormalizingModel({
    this.id = "",
    this.normalize = false,
    this.ai = false
  });

  /// The table being prepared. Empty when the notice could not be read,
  /// which is the only way to discard it.
  final String id;

  /// Whether the columns are going to be typed at all. `false` when the
  /// import asked to keep the file exactly as it was written: the table is
  /// still not finished —it is missing its image column— but the wait is a
  /// blink instead of half a minute.
  final bool normalize;

  /// Whether a model reviews the measured plan. It is what separates a wait
  /// of a fifth of a second from one of a dozen: the mechanical pass only
  /// measures, and the paid one has a model writing its answer token by
  /// token.
  final bool ai;

  /// Reads the notice as it arrives from the socket.
  ///
  /// Nothing is validated against what was expected: a notice that cannot be
  /// read comes out with an empty [id] and whoever receives it discards it.
  /// It is the only reasonable thing —there is nobody to return an error to—
  /// and also the only safe one: the worst that happens is a table that is
  /// not marked as busy, which is where this started.
  factory TableNormalizingModel.fromEvent(dynamic data) {
    if (data is! Map) return const TableNormalizingModel();

    return TableNormalizingModel(
      id: (data["id"] ?? data["ID"] ?? data["table_id"])?.toString() ?? "",
      normalize: _flag(data["normalize"]),
      ai: _flag(data["ai"])
    );
  }

  /// Whether the notice carries a table that can be marked.
  bool get isEmpty => id.isEmpty;

  static bool _flag(dynamic value) => switch (value) {
    final bool flag => flag,
    final num number => number != 0,
    final String text => text == "true" || text == "1",
    _ => false
  };
}
