/// What a normalization (`POST /inventory/products/builder/normalize/`)
/// left behind: how many columns changed type, how many had their
/// visibility seeded, how many got a real name and how many were put in the
/// stock summary.
///
/// Normalizing is what turns a table imported from an Excel file —all its
/// columns `text`, all visible to the agent— into one that can be queried:
/// the backend reads a sample of each column, gives it the type it should
/// have had from the start (a price that compares as a number, a date that
/// sorts), and decides how much of it a bot can see. It's the same pass that
/// runs on its own once an import finishes, here requested by hand.
///
/// It only reviews the columns nobody touched: one that already had its type
/// or visibility chosen is left as it is, so normalization can be repeated
/// without undoing what was fixed by hand.
///
/// **What's read from the response is what changed, not the plan**: the full
/// plan —column by column, with what was proposed for it and why— is what a
/// preview needs, and this is requested once the change is already wanted
/// done. What's needed on return is to tell the user about it and to know
/// how much of what's on screen is now stale.
class TableNormalizeModel {
  const TableNormalizeModel({
    this.id = "",
    this.retyped = 0,
    this.narrowed = 0,
    this.renamed = 0,
    this.summarized = 0,
    this.recast = 0,
    this.reindexed = false,
    this.image = ""
  });

  /// The table that was normalized. Empty if the response couldn't be read.
  final String id;

  /// How many columns changed type.
  final int retyped;

  /// How many columns ended up with their visibility seeded: how much of
  /// them the agent sees (`visible` / `declared` / `hidden`).
  final int narrowed;

  /// How many columns ended up with a real name, out of the ones the
  /// imported file left untitled.
  final int renamed;

  /// How many columns had their place in the stock summary seeded: which of
  /// them a person is shown at a glance in the short view.
  ///
  /// It's a different question from [narrowed] —what the AI agent may read—
  /// and that's why it's counted apart: a table nobody curated shows every
  /// column it ever imported in that view, which is the sheet again.
  final int summarized;

  /// How many columns had to rewrite the values they already had saved,
  /// because the new type stores them differently.
  final int recast;

  /// Whether the table was reindexed by meaning, which is what happens when
  /// a column became semantic.
  final bool reindexed;

  /// The table's image column, created or promoted to the first position.
  /// Empty if none came.
  final String image;

  /// Whether the response couldn't be read. A normalized table always has an
  /// id.
  bool get isEmpty => id.isEmpty;

  /// How many columns ended up different from how they were. It's what
  /// separates "there was nothing to fix" from "things got fixed", which
  /// are two different notices.
  int get changed => retyped + narrowed + renamed + summarized;

  /// Whether the saved values were rewritten. It's the only thing that
  /// forces discarding any records already read: the columns can be the
  /// same and their values no longer are.
  bool get changedValues => recast > 0 || retyped > 0;

  /// Reads the normalization's response.
  ///
  /// The `fields` that comes alongside it —the column-by-column plan— is
  /// ignored on purpose: the structure is requested again after this
  /// regardless, and that's what says how the columns really ended up.
  /// Keeping the plan would mean carrying two versions of the same thing,
  /// one of them without the changes the normalization didn't get to write.
  factory TableNormalizeModel.fromResponse(dynamic data) {
    if (data is! Map) return const TableNormalizeModel();

    return TableNormalizeModel(
      id: (data["id"] ?? data["ID"] ?? data["table_id"])?.toString() ?? "",
      retyped: _count(data["retyped"]),
      narrowed: _count(data["narrowed"]),
      renamed: _count(data["renamed"]),
      summarized: _count(data["summarized"]),
      recast: _count(data["recast"]),
      reindexed: _flag(data["reindexed"]),
      image: data["image"]?.toString() ?? ""
    );
  }

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