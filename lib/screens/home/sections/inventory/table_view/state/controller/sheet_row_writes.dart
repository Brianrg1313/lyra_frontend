part of '../sheet_controller.dart';

/// What a row sends: the blank rows below become records when the cursor
/// leaves them, and a record's cell is corrected when it is left.
extension SheetRowWrites on SheetController {
  /// The cursor leaves the row it was in, towards [to] (or towards none, if
  /// what was lost is focus). If the one it leaves is one of the blank rows
  /// below and it was left with something written, that row saves itself.
  ///
  /// **Leaving the row is what creates the record**, the same way leaving the
  /// cell is what sends a record's correction ([close]) or a column's creation
  /// ([finishField]). There's nothing to confirm: it's written and on it
  /// goes.
  ///
  /// It's the row and not the cell because the row is written across several
  /// columns: crossing it with Tab sends nothing and leaving it sends the
  /// whole thing, which is **one** creation and not one per column. Saving
  /// cell by cell would also turn the row into a record in the middle of the
  /// load, and from there on each Tab would be a correction on a row just
  /// created.
  void _leaveRow(int? to) {
    final from = cursor.cell?.row;
    if (from == null || from == to || from == kFieldsRow) return;

    _queueDraft(drafts.at(draftIndex(from)));
  }

  /// Puts a draft row in the creations queue, if it has something to save and
  /// isn't being saved already.
  ///
  /// The queue is one for the whole spreadsheet: two creations in flight at
  /// the same time would step on the re-read with which each one says goodbye
  /// to its draft (see [_saveDraft]).
  void _queueDraft(SheetDraft? draft) {
    if (draft == null || !draft.hasData || draft.saving) return;

    _rowQueue = _rowQueue.then((_) => _saveDraft(draft)).catchError(
      // What the service rethrows (an expired session) follows its usual way
      // —the zone's handler, like any write that isn't awaited— but can't stay
      // in the queue: one such error alone would leave without
      // saving all the rows written afterwards.
      (Object error, StackTrace stack) =>
        Zone.current.handleUncaughtError(error, stack)
    );
  }

  /// Sends a draft row as a new item (`POST /inventory/products/records/manage/`).
  ///
  /// It builds the creation's `DATA` indexed by FIELD_ID, skipping the empty
  /// cells and the columns without an id. A row written **only** in free
  /// columns still has nowhere to save itself: it stays as it is, without
  /// saying anything, and leaves on its own the next time it's left, when
  /// those columns are already fields.
  ///
  /// If it doesn't go through, the draft stays intact and the row is still a
  /// written blank row: it's retried with just leaving it again. The service
  /// already showed the error.
  Future<void> _saveDraft(SheetDraft draft) async {
    if (_disposed || draft.saving) return;

    final fields = service.fields;
    final values = <String, dynamic>{};
    final row = List<dynamic>.filled(fields.length, null);

    draft.values.forEach((index, text) {
      if (index < 0 || index >= fields.length) return;

      final field = fields[index];
      final value = text.trim();
      if (value.isEmpty || field.id.isEmpty) return;

      values[field.id] = value;
      row[index] = value;
    });

    if (values.isEmpty) return;

    drafts.setSaving(draft, true);

    // Noted as persisted before it travels: the service places the record (with what was
    // written) in the same notice that counts it, and that notice is the one that removes
    // the draft ([_onRows]), so the row never shows empty nor twice.
    _persisted = draft;
    _persistedAt = service.records;

    final saved = await service.add(_context(), values, row: row);
    if (_disposed) return;

    if (!saved) {
      _persisted = null;
      drafts.setSaving(draft, false);
      return;
    }

    // If the count didn't move (the re-read didn't arrive, or the table doesn't
    // tell how many records it has) nobody will remove it from [_onRows]: it's
    // removed here, because otherwise it would stay repeated over the record
    // that just appeared.
    _dropPersisted(force: true);
  }

  /// Removes from the spreadsheet the row that's already persisted, now that
  /// the table counts it as a record.
  ///
  /// Both things —the record count going up and the draft going away— have to
  /// happen **together**: the rows below place themselves subtracting one from
  /// the other ([draftIndex]), so if one gets ahead, for a while each blank
  /// row shows its neighbor's draft. That while lasts a whole re-read, which
  /// is exactly the time spent writing the next row.
  ///
  /// That's why this hangs from [_onRows], which runs **inside** the service's
  /// notice and before a single cell is redone: when the spreadsheet looks,
  /// both things already happened.
  void _dropPersisted({bool force = false}) {
    final draft = _persisted;
    if (draft == null) return;
    if (!force && service.records <= _persistedAt) return;

    _persisted = null;
    drafts.remove(draft);
  }

  /// Sends the correction of a cell in a record that was just left.
  ///
  /// It's compared to what the cell had when it opened: crossing a row with
  /// Tab without touching anything sends nothing, which is what lets one
  /// navigate a whole table without writing over it. That "before" is
  /// [_initial] —what the editor found when it opened— unless another is
  /// passed in [before], which is what the cell does that has no editor: a
  /// list is chosen from a dropdown, so what it had is read at the moment of
  /// choosing.
  ///
  /// It's neither queued nor awaited: each cell is an independent write
  /// —different fields of different rows— and none re-reads the table, so
  /// there's nothing for them to step on between them. The change is already
  /// seen in the spreadsheet; if it doesn't go through, the service gives the
  /// cell back what it had and says so.
  void finishRecord(SheetCell cell, String text, {String? before}) {
    if (text == (before ?? _initial)) return;

    if (movesStock(cell)) {
      unawaited(correctStock(cell, text));
      return;
    }

    // Behind the fields are the free columns: there's nowhere to save there.
    final field = columns.fieldAt(cell.column);
    if (field == null || field.id.isEmpty) return;

    unawaited(service.editRecord(
      _context(),
      row: cell.row,
      slot: columns.slotAt(cell.column),
      fieldId: field.id,
      value: text.trim()
    ));
  }
}
