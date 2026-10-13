part of '../sheet_controller.dart';

/// The dropdown of a list cell: choose or create an option, or (in a multi-tag column) tick several.
extension SheetOptionPicks on SheetController {
  /// Opens the dropdown of a list cell, anchored to the cell ([anchor] is its
  /// context).
  ///
  /// It's the version of [open] for the fields that are chosen: the cell ends
  /// up selected like any other and instead of the editor, **that column's
  /// options** are unfolded, which belong to the field and not to the company
  /// (see [TableFieldModel.options]).
  ///
  /// The dropdown brings a search box only past [_kOptionSearchFrom] options:
  /// with a short list the search box is one extra row between the cell and
  /// what one wants to touch, and with a long one it's what makes choosing a
  /// matter of writing three letters. And it always brings the row to create a
  /// new option, which is what lets one build the list while loading the table
  /// instead of having to define it in advance: the missing option is written
  /// right there, saved in the field, and left chosen in the cell in a single
  /// pass.
  ///
  /// Choosing the same one it already had sends nothing, like leaving a text
  /// cell without touching it. A multi-tag column ([TableFieldType.multiple])
  /// opens a check list instead ([_checkOptions]).
  Future<void> pickOption(SheetCell cell, BuildContext? anchor) async {
    select(cell);

    if (anchor == null || !anchor.mounted) return;

    // Behind the fields are the free columns: there's no field there to pull
    // options from or to add them to.
    final field = columns.fieldAt(cell.column);
    if (field == null || field.id.isEmpty) return;

    final type = TableFieldType.from(field.type);

    if (type.multiple) return _checkOptions(cell, anchor, field);

    final current = valueOf(cell);

    final picked = await showSelectMenu(
      context: anchor,
      options: _optionsOf(anchor, field, current: current),
      selected: current,
      searchPlaceholder: field.options.length > _kOptionSearchFrom
        ? S.of(anchor).table_field_option_search
        : null,
      emptyText: S.of(anchor).table_field_option_empty,
      // Hangs from a cell, which measures one row: with the usual size —a form
      // field's— five options would cover half the spreadsheet.
      dense: true,
      createText: S.of(anchor).table_field_option_create,
      createPlaceholder: S.of(anchor).table_field_option_placeholder,
      onCreate: (name) => _createOption(field, name)
    );

    if (_disposed || picked == null) return;

    _writeOption(cell, picked.value);
  }

  /// The check list of a multi-tag cell (`CATEGORIES`, `SIZES`): every option with its
  /// box, ticked or not, and the dropdown stays open while they're ticked, so the
  /// sizes a shoe comes in are a run of taps and not one dropdown per size. What is
  /// checked when it closes is written in one go, and nothing if it didn't change.
  ///
  /// A label the cell holds that the field's list no longer has (an option removed, a
  /// value imported as written) still shows, checked, after the field's options:
  /// without its row it couldn't be unticked. Labels are matched to the list the way
  /// the list matches them ([sameFieldOption]), so "m" in the cell ticks the "M".
  ///
  /// The written labels keep the list's order and not the taps', which in a `SIZES`
  /// column is its scale (the backend orders it smallest first): "38, 39, 41", never
  /// "41, 38, 39".
  Future<void> _checkOptions(
    SheetCell cell,
    BuildContext anchor,
    TableFieldModel field
  ) async {
    // A multi-tag cell is saved as a list, so what it has set is read from the
    // raw value and not from its text (see [rawOf]).
    final held = [
      for (final label in fieldLabelsOf(rawOf(cell)))
        fieldOptionLike(field.options, label) ?? label
    ];

    final loose = [
      for (final label in held)
        if (fieldOptionLike(field.options, label) == null) label
    ];

    final checked = await showCheckMenu(
      context: anchor,
      options: [
        for (final option in [...field.options, ...loose])
          SelectOption(value: option, placeholder: option)
      ],
      checked: held,
      searchPlaceholder: field.options.length > _kOptionSearchFrom
        ? S.of(anchor).table_field_option_search
        : null,
      emptyText: S.of(anchor).table_field_option_empty,
      dense: true,
      createText: S.of(anchor).table_field_option_create,
      createPlaceholder: S.of(anchor).table_field_option_placeholder,
      onCreate: (name) => _createOption(field, name)
    );

    if (_disposed) return;
    if (fieldLabelsValue(checked) == fieldLabelsValue(held)) return;

    _writeOption(cell, fieldLabelsValue(checked));
  }

  /// The options offered in a single-tag cell's dropdown.
  ///
  /// They're the field's and, above all of them, the one that empties the
  /// cell —but only if there's something to empty. Without it a list cell
  /// would have no way back: there's no editor to erase the text, so an
  /// option chosen by mistake would stay set forever.
  List<SelectOption> _optionsOf(
    BuildContext context,
    TableFieldModel field, {
    required String current
  }) => [
    if (current.isNotEmpty) SelectOption(
      value: "",
      placeholder: S.of(context).table_field_option_none,
      icon: Icons.remove
    ),
    for (final option in field.options)
      SelectOption(value: option, placeholder: option)
  ];


  /// Adds an option to the field's list from the dropdown itself.
  ///
  /// An option is a property of the column, so it's saved the way any other
  /// is: sending the field with the list it has to end up with. That
  /// re-reads the structure —it's the one that just changed— and with it comes
  /// the new list, so the next time that column is unfolded the option is
  /// already there.
  ///
  /// Writing one that was already there creates nothing and doesn't fail: the
  /// one that exists is returned, which is what whoever wrote it meant. Two
  /// options that only differ in capitals or accents are the same
  /// ([sameFieldOption]), because they'd be indistinguishable in the list.
  ///
  /// Returns `null` if it couldn't be saved; the service already showed the
  /// error and the dropdown row stays open with what was written to retry.
  Future<SelectOption?> _createOption(
    TableFieldModel field,
    String name
  ) async {
    final existing = fieldOptionLike(field.options, name);
    if (existing != null) {
      return SelectOption(value: existing, placeholder: existing);
    }

    final options = fieldOptionsWith(field.options, name);
    if (options == null) return null;

    final saved = await service.editField(_context(), field, options: options);
    if (_disposed || !saved) return null;

    final created = name.trim();
    return SelectOption(value: created, placeholder: created);
  }
}
