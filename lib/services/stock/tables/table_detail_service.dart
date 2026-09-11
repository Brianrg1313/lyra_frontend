import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;

import 'package:app/services/inventory/table_field_request.dart';
import 'package:app/services/inventory/table_field_type.dart';
import 'package:app/services/inventory/table_request.dart';
import 'package:app/services/stock/tables/table_detail_model.dart';
import 'package:app/toolkit/api.dart';

/// State of the read of a table's detail
/// (`GET /inventory/products/builder/details/<table_id>`).
enum TableDetailStatus { idle, loading, ready, error }

/// The detail of a table opened in its settings screen: its header, its
/// columns, how many records it has, and which bots read it.
///
/// **It isn't cached, and that's on purpose.** It's the opposite of
/// [TablesService]: the list is looked at all the time and barely changes,
/// while this is opened every so often and precisely to check the table's
/// state —how many rows came in, when the last change was, who's reading
/// it—. A saved response from the previous visit would answer those three
/// questions with old data, which is worse than not answering them.
///
/// For the same reason it's owned by the screen and not the app's scope: it's
/// created on entry and discarded on exit, same as [TableViewService].
///
/// A reread over an already-drawn detail **doesn't go back to a blank
/// screen** ([isReloading]): it's signaled up top and what's there stays
/// where it is. It's what lets it refresh without the page jumping, which is
/// the only thing done from here.
class TableDetailService extends ChangeNotifier {
  TableDetailService({this.onSummaryChanged});

  /// Notice that a column changed in something the **inventory summary**
  /// draws: whether it's in it or what type it is.
  ///
  /// The panel opens to the side, over the section where that summary keeps
  /// showing (see `showTableSettings`), so switching on a column's checkbox
  /// has to show up there right away and not only once the panel closes.
  ///
  /// It's a notice and not the summary's service: this doesn't know whether
  /// one is watching —the same panel opens from the sheet too, where there
  /// isn't one— nor is it its place to know.
  final VoidCallback? onSummaryChanged;

  TableDetailStatus _status = TableDetailStatus.idle;
  TableDetailModel _detail = const TableDetailModel();

  /// Table being looked at. Empty until the first [load].
  String _tableId = "";

  /// `true` while a read over an already-drawn detail is in flight.
  bool _reloading = false;

  TableDetailStatus get status => _status;
  TableDetailModel get detail => _detail;
  String get tableId => _tableId;
  bool get isReloading => _reloading;

  /// Reads [tableId]'s detail.
  ///
  /// It's the screen's only read: the endpoint gathers into a single response
  /// what lives in three different stores, so there's nothing else to
  /// request afterward.
  Future<void> load(String tableId) async {
    if (tableId.isEmpty) {
      _status = TableDetailStatus.error;
      notifyListeners();
      return;
    }

    if (_status == TableDetailStatus.loading || _reloading) return;

    // A detail is already drawn: this is a reread, not a load. Going through
    // `loading` would unmount the whole page —with its scroll position— for
    // a refresh that almost always returns the same thing.
    final reload = _status == TableDetailStatus.ready && _tableId == tableId;

    _tableId = tableId;

    if (reload) {
      _reloading = true;
    } else {
      _status = TableDetailStatus.loading;
      _detail = const TableDetailModel();
    }

    notifyListeners();

    // No trailing slash: the id is a path segment (`params:
    // ["TABLE_ID"]`), and an extra slash would leave it empty on the other
    // side.
    final data = await api
      .get(path: "/inventory/products/builder/details/$tableId", version: "v1")
      .catchError((error) {
        if (kDebugMode) print("loadTableDetail failed: $error");
        return null;
      });

    // The flag is lowered before checking whether the table changed:
    // releasing it later would leave a discarded reread blocking the next
    // one forever, because the guard above checks it to avoid stepping on a
    // read already in flight.
    _reloading = false;

    // Another table was requested while the read was traveling: what
    // arrived belongs to the previous one and has nowhere to go.
    if (_tableId != tableId) return;

    if (data == null) {
      // A reread that fails leaves what was already there: the old detail is
      // still the table's, and discarding it would leave the screen in
      // error over a refresh that didn't go well.
      if (!reload) _status = TableDetailStatus.error;

      notifyListeners();
      return;
    }

    final detail = TableDetailModel.fromResponse(data);

    // A response that doesn't even bring the table's id isn't a detail: it's
    // treated as a failed read instead of drawing a screen full of gaps.
    if (detail.isEmpty) {
      if (!reload) _status = TableDetailStatus.error;

      notifyListeners();
      return;
    }

    _detail = detail;
    _status = TableDetailStatus.ready;

    notifyListeners();
  }

  /// Rereads the table being looked at.
  Future<void> refresh() => load(_tableId);

  /// Retries after an error. It's [load] again: the failed read left
  /// nothing to keep.
  Future<void> retry() {
    if (_status == TableDetailStatus.error) _status = TableDetailStatus.idle;
    return load(_tableId);
  }

  /// Changes the name and/or description of the table being looked at,
  /// against `PUT /inventory/products/builder/details/`.
  ///
  /// It's a **partial** write: only what was touched travels (see
  /// [editTableDetailsRequest]), so correcting the description doesn't
  /// rewrite the name nor disconnect any channel. That's the difference with
  /// `PUT /inventory/products/builder/structure/`, which is the sheet's
  /// rename box and so always asks for the name.
  ///
  /// What was written is painted right away over the detail already on
  /// screen, and only then is it reread. Those are two different things: the
  /// new text is already fully known on this side —whoever's looking just
  /// wrote it—, but the "structure updated" date is set by the backend on
  /// save, and that date shows on this same page. Without the reread it
  /// would be left showing the previous change right next to the one that
  /// was just made.
  ///
  /// The reread isn't awaited: it's an expensive read (three stores) and
  /// whoever saved can already leave. While it travels, the bar up top shows
  /// it's reloading and the panel stays with what it has.
  ///
  /// Returns `true` if the change went through. On error it shows the
  /// floating banner and returns `false`, with the panel as it was.
  Future<bool> edit(
    BuildContext context, {
    String? name,
    String? description
  }) async {
    if (_tableId.isEmpty) return false;

    // Nothing to send. It's not an error: it's that whoever called didn't
    // change either of the two texts, and the backend rejects a body with
    // nothing to write.
    if (name == null && description == null) return false;

    try {
      await api.put(
        path: "/inventory/products/builder/details/",
        version: "v1",
        data: editTableDetailsRequest(
          id: _tableId,
          name: name,
          description: description
        )
      );
    } catch (error) {
      if (kDebugMode) print("editTableDetail failed: $error");

      if (context.mounted) _report(context, error);

      return false;
    }

    // What's saved travels trimmed, so the panel shows the same thing that
    // ended up on the other side and not what was typed with extra spaces.
    _detail = _detail.withText(
      name: name?.trim(),
      description: description?.trim()
    );

    notifyListeners();

    // See the note above: the change's date is set by the backend.
    unawaited(refresh());

    return true;
  }

  /// Changes a column's type, visibility, options, or summary flag, against
  /// `PUT /inventory/products/builder/fields/`.
  ///
  /// It's the write for this screen's column list, where each column is a
  /// row with its three dropdowns and its summary checkbox. Only what was
  /// chosen travels; the name always goes because the backend asks for it,
  /// so changing a column's type sends the name it already had and touches
  /// neither its description, its width, nor its position.
  ///
  /// It's the same endpoint the sheet uses ([TableViewService.editField]) and
  /// there's nothing to sync between the two: the sheet has its own service,
  /// which dies with the screen and rereads the structure when it opens.
  ///
  /// What was chosen is painted right away over the column and then reread,
  /// for the same reason as in [edit]: the new value is already known on
  /// this side, but the counts up top —how many columns of each type, how
  /// many are still untyped, how many are in the summary, what the model can
  /// do with the table— are computed by the backend and change with this. A
  /// type change also rewrites the values already loaded in that column on
  /// the other side, so a successful response isn't the end of the story
  /// either.
  ///
  /// Returns `true` if the change went through. On error it shows the
  /// floating banner and returns `false`, with the column as it was.
  Future<bool> editField(
    BuildContext context,
    TableDetailFieldModel field, {
    TableFieldType? type,
    TableFieldVisibility? visibility,
    List<String>? options,
    String? unit,
    bool? summary
  }) async {
    // Without a FIELD_ID there's no column to edit: it's a column that was
    // read but that the backend didn't identify.
    if (field.id.isEmpty) return false;

    // Nothing to write: none of the column's data was touched, and the
    // backend rejects a body that changes nothing.
    final untouched = type == null &&
      visibility == null &&
      options == null &&
      unit == null &&
      summary == null;

    if (untouched) return false;

    // What actually ends up saved: the body trims the options and the unit
    // and discards empty options, and the column has to show that and not
    // what was typed.
    final saved = options == null
      ? null
      : [
          for (final option in options)
            if (option.trim().isNotEmpty) option.trim()
        ];

    final symbol = unit?.trim();

    try {
      await api.put(
        path: "/inventory/products/builder/fields/",
        version: "v1",
        data: editFieldRequest(
          id: field.id,
          name: field.name,
          type: type?.value,
          visibility: visibility?.value,
          summary: summary,
          options: saved,
          unit: symbol
        )
      );
    } catch (error) {
      if (kDebugMode) print("editTableField failed: $error");

      if (context.mounted) _report(context, error);

      return false;
    }

    _detail = _detail.withField(field.withEdits(
      type: type,
      visibility: visibility,
      options: saved,
      unit: symbol,
      summary: summary
    ));

    notifyListeners();

    // The inventory summary draws the columns that have their flag switched
    // on and writes each value according to its own type and unit, so those
    // three changes have to show up there right away. Visibility and options
    // mean nothing to it —one is what the model sees and the other is what
    // a list offers on load— and that's why they don't move it.
    if (summary != null || type != null || unit != null) {
      onSummaryChanged?.call();
    }

    // See the note above: the panel's counts are computed by the backend.
    unawaited(refresh());

    return true;
  }

  /// Shows a write's error the same way the rest of the services do: the
  /// floating banner with whatever the backend said, and the raw one to the
  /// console even when it was shown (the on-screen text is usually
  /// trimmed).
  void _report(BuildContext context, Object error) {
    if (error is Map && error["action"] != null) throw error["action"];

    FloatFlag.of(context).fromError(
      error is Map && error.isNotEmpty ? error : {"message": error.toString()}
    );
  }
}