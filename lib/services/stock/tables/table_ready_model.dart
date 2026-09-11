/// The `table/ready` notice: the backend finished preparing an imported
/// table.
///
/// It exists because **the structure import answers before it's actually
/// finished**. `POST /inventory/products/import/structure/<format>/` returns
/// the table's id as soon as its columns exist —all `text` and all
/// visible— and leaves the slow half for later: reading what's in each
/// column and asking a model what it means, which takes about half a
/// minute, plus the image column every table ends up with. When that lands,
/// the backend emits it to the business's room and **that's the moment to
/// reread the table**.
///
/// It always arrives: whether it goes well or not, and also when the import
/// asked not to normalize (`NORMALIZE=0`, which leaves `ok: true, normalized:
/// false`). That's why it can be waited for unconditionally instead of
/// guessing whether it's going to come.
///
/// It's the far end of a wait whose near end is [TableNormalizingModel]:
/// that one says the preparation started, this one that it landed, and a
/// client can pair them unconditionally.
///
/// It's listened to by the two sides that show a table, each on its own and
/// for its own purpose: [TablesService], which is whoever is importing and
/// doesn't upload the file's rows until its columns are typed, and
/// [TableViewService], which rereads the table where it stands if it's
/// open.
class TableReadyModel {
  /// Name of the event on the socket. It's a contract handwritten on both
  /// sides —here and in `Normalizer.prepare`—, so it lives in a single
  /// constant: a misspelled event doesn't fail, it just never arrives.
  static const String event = "table/ready";

  /// The table that became ready. Empty when the notice couldn't be read,
  /// which is the only way to discard it.
  final String id;

  /// Whether the preparation finished without failing. Being `false`
  /// doesn't undo anything: the table exists all the same, with its columns
  /// as they ended up.
  final bool ok;

  /// Whether the columns got typed. It's `false` when the import asked not
  /// to normalize, and that's also a good ending.
  final bool normalized;

  /// How many columns changed type.
  ///
  /// It's what decides whether what was already read from the table is
  /// still good: when retyping a column the backend rewrites **the saved
  /// values** so they stop being text (`Products.recast`), so any records
  /// that were in memory are now stale even though the columns are the
  /// same.
  final int retyped;

  /// How many columns ended up with their visibility seeded (how much of
  /// them the agent sees). Doesn't change anything shown in the sheet.
  final int narrowed;

  /// How many columns ended up with a name a person reads, out of the ones
  /// the file named for a machine (`PRECIO_DISTRIBUIDOR` → `Precio
  /// distribuidor`). It never touches a name somebody typed.
  final int renamed;

  /// How many columns had their place in the stock summary seeded: which of
  /// them a person is shown at a glance in the short view. It's a different
  /// question from the visibility above —what the agent may read— and that's
  /// why it's counted apart.
  final int summarized;

  /// The table's image column, created or promoted to the first position.
  /// Empty if none came: never a reason to discard the notice.
  final String image;

  /// What failed, when [ok] is `false`. Empty if it went well.
  final String reason;

  const TableReadyModel({
    this.id = "",
    this.ok = false,
    this.normalized = false,
    this.retyped = 0,
    this.narrowed = 0,
    this.renamed = 0,
    this.summarized = 0,
    this.image = "",
    this.reason = ""
  });

  /// Reads the notice as it arrives from the socket.
  ///
  /// None of this is validated against what was expected: a notice that
  /// can't be read comes out with an empty [id] and whoever receives it
  /// discards it. It's the only reasonable thing —there's no one to return
  /// an error to— and also the only safe one: the worst that happens is the
  /// table gets reread by hand.
  factory TableReadyModel.fromEvent(dynamic data) {
    if (data is! Map) return const TableReadyModel();

    return TableReadyModel(
      id: (data["id"] ?? data["ID"] ?? data["table_id"])?.toString() ?? "",
      ok: _flag(data["ok"]),
      normalized: _flag(data["normalized"]),
      retyped: _count(data["retyped"]),
      narrowed: _count(data["narrowed"]),
      renamed: _count(data["renamed"]),
      summarized: _count(data["summarized"]),
      image: data["image"]?.toString() ?? "",
      reason: data["reason"]?.toString() ?? ""
    );
  }

  /// Whether the notice carries a table that can be reread.
  bool get isEmpty => id.isEmpty;

  /// Whether the saved values were rewritten. The only thing that forces
  /// discarding the records already read: the columns can be the same and
  /// their values not.
  bool get changedValues => retyped > 0;

  static bool _flag(dynamic value) => switch (value) {
    final bool flag => flag,
    final num number => number != 0,
    final String text => text == "true" || text == "1",
    _ => false
  };

  static int _count(dynamic value) => switch (value) {
    final num number => number.toInt(),
    final String text => int.tryParse(text) ?? 0,
    _ => 0
  };
}