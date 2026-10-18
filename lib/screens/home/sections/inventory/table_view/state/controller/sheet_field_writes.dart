part of '../sheet_controller.dart';

/// What a header sends: a column created, renamed, deleted or given another type.
extension SheetFieldWrites on SheetController {
  /// Carries out what [FieldEdit] decides for the field cell that was just
  /// left: create the column, rename the field, or delete it.
  void finishField(int column, String text) {
    if (column < 0) return;

    // Behind the fields are the free columns: there's still no field there.
    final field = columns.fieldAt(column);

    switch (FieldEdit.of(
      isField: field != null,
      current: field?.name ?? "",
      text: text
    )) {
      case FieldEdit.none:
        return;
      case FieldEdit.create:
        _createColumn(column);
      case FieldEdit.rename:
        _renameColumn(field!, text.trim());
      case FieldEdit.delete:
        _confirmDelete(field!);
    }
  }

  /// Sends a field's new title. It goes through the same queue as the
  /// creations: each change reloads the table, so two in a row are sent one
  /// after the other.
  ///
  /// Until it comes back, the cell shows the new title dimmed: it's what the
  /// user just wrote, and going back to the old one for an instant would read
  /// as the change being lost. If it fails, the structure that arrives brings
  /// the old one and the cell goes back to it on its own; the service already
  /// showed the error.
  void _renameColumn(TableFieldModel field, String name) {
    columns.startRename(field.id, name);

    _columnQueue = _columnQueue.then((_) async {
      if (_disposed) return;

      await service.editField(_context(), field, name: name);
      if (_disposed) return;

      columns.endRename(field.id);
    });
  }

  /// Asks before deleting the field whose title was emptied and, if confirmed,
  /// sends it.
  ///
  /// It's the only thing in the spreadsheet that's asked: adding a column or
  /// renaming it is undone by writing again, but the deletion takes the column
  /// **and everything loaded in it**, and that doesn't come back. Canceling
  /// touches nothing: the cell keeps showing the field as it was, because the
  /// emptied title never left the editor.
  Future<void> _confirmDelete(TableFieldModel field) async {
    final context = _context();

    final confirmed = await showAlertModal(
      context: context,
      title: S.of(context).table_field_delete_title,
      message: S.of(context).table_field_delete_message(field.name),
      confirmText: S.of(context).table_field_delete_confirm,
      cancelText: S.of(context).cancel
    );

    if (_disposed || !confirmed) return;

    columns.startDelete(field.id);

    _columnQueue = _columnQueue.then((_) async {
      if (_disposed) return;

      final deleted = await service.deleteField(_context(), field);
      if (_disposed) return;

      columns.endDelete(field.id);

      // The column is no longer there: the cursor pointed at a place that is now
      // another column.
      if (deleted) cursor.clear();
    });
  }

  /// Creates the field of the free column that was left with a title. It's all
  /// that's needed to add a column: write its title and leave the cell,
  /// without any forms in between.
  ///
  /// The type is `TEXT`, the one that serves for everything: the spreadsheet
  /// doesn't ask and the backend can always read what's loaded there.
  void _createColumn(int column) {
    final free = columns.freeAt(column);
    if (free == null || free.creating || free.name.isEmpty) return;

    columns.startCreate(free);
    _columnQueue = _columnQueue.then((_) => _sendColumn(free));
  }

  /// Sends the field's creation. When it comes back well, the column stops
  /// being free: the service's reload already brings it as a field of the
  /// table, in the same place where it was written.
  ///
  /// Nothing is said when it's done: the creation confirms itself when the
  /// column appears, like in a spreadsheet. If it failed, the column stays
  /// free and with its title set, and it's retried by leaving the cell again.
  Future<void> _sendColumn(FreeColumn free) async {
    if (_disposed) return;

    final created = await service.addField(
      _context(),
      name: free.name,
      description: "",
      type: TableFieldType.text.value
    );
    if (_disposed) return;

    columns.endCreate(free, created: created);
  }

  /// Opens the dropdown of a column's types, anchored to the arrow of its
  /// field cell ([anchor] is the arrow's context, which is what gives its
  /// position on screen).
  ///
  /// It's the usual dropdown ([showSelectMenu]): it doesn't stretch further
  /// than a few options —the types are many and they filled the screen— and it
  /// brings a search box, which with this list is what makes choosing a matter
  /// of writing three letters instead of going through it all.
  ///
  /// Choosing a type sends it; choosing the one it already had, or closing the
  /// dropdown without choosing, does nothing. The error, if any, was already
  /// shown by the service.
  Future<void> pickType(BuildContext anchor, TableFieldModel field) async {
    final current = TableFieldType.from(field.type);

    final picked = await showSelectMenu(
      context: anchor,
      options: TableFieldType.menu(anchor, kind: kind, current: current),
      selected: current.value,
      searchPlaceholder: S.of(anchor).table_field_type_placeholder,
      emptyText: S.of(anchor).table_field_type_empty,
      maxOptions: 4
    );

    if (_disposed || picked == null || picked.value == current.value) return;

    await service.editField(_context(), field, type: picked.value);
  }
}
