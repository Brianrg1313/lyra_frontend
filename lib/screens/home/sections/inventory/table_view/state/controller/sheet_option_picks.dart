part of '../sheet_controller.dart';

/// The dropdown of a list cell: choose, create or (in a multi-tag column) toggle an option.
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
  /// cell without touching it. In a multi-tag column
  /// ([TableFieldType.multiple]) choosing is **putting or taking off** that
  /// tag: the dropdown is a single-choice one, so touching one that was
  /// already set takes it off instead of replacing all the others, which is
  /// the only thing a single touch can mean there.
  Future<void> pickOption(SheetCell cell, BuildContext? anchor) async {
    select(cell);

    if (anchor == null || !anchor.mounted) return;

    // Behind the fields are the free columns: there's no field there to pull
    // options from or to add them to.
    final field = columns.fieldAt(cell.column);
    if (field == null || field.id.isEmpty) return;

    final type = TableFieldType.from(field.type);

    // A multi-tag cell is saved as a list, so what it has set is read from the
    // raw value and not from its text (see [rawOf]).
    final chosen = type.multiple
      ? fieldLabelsOf(rawOf(cell))
      : const <String>[];

    final current = type.multiple ? "" : valueOf(cell);

    final picked = await showSelectMenu(
      context: anchor,
      options: _optionsOf(anchor, field, current: current, chosen: chosen),
      // With several set there's no "the chosen one": which is set and which
      // isn't is told by the check of each row ([_optionsOf]).
      selected: type.multiple ? null : current,
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

    if (!type.multiple) {
      _writeOption(cell, picked.value);
      return;
    }

    // Emptying the cell is a row of the dropdown like any other and arrives
    // with the empty value: there's no tag to put on or take off there.
    _writeOption(
      cell,
      picked.value.isEmpty
        ? ""
        : fieldLabelsValue(fieldLabelsToggled(chosen, picked.value))
    );
  }

  /// The options offered in a cell's dropdown.
  ///
  /// They're the field's and, above all of them, the one that empties the
  /// cell —but only if there's something to empty. Without it a list cell
  /// would have no way back: there's no editor to erase the text, so an
  /// option chosen by mistake would stay set forever.
  ///
  /// In a multi-tag column, the ones the cell already has set go with a
  /// check: the dropdown can't mark them as "the chosen one" —it only knows
  /// about one— and without the mark there'd be no way to see, before
  /// touching, whether that row is going to put the tag on or take it off.
  /// [chosen] arrives empty in a single-tag column, where `selected` says it.
  List<SelectOption> _optionsOf(
    BuildContext context,
    TableFieldModel field, {
    required String current,
    required List<String> chosen
  }) => [
    if (current.isNotEmpty || chosen.isNotEmpty) SelectOption(
      value: "",
      placeholder: S.of(context).table_field_option_none,
      icon: Icons.remove
    ),
    for (final option in field.options)
      SelectOption(
        value: option,
        placeholder: option,
        icon: fieldOptionLike(chosen, option) != null ? Icons.check : null
      )
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
