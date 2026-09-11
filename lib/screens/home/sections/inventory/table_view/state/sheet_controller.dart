import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:core/form/select_input.dart' show SelectOption;
import 'package:core/form/select_menu.dart';
import 'package:core/widgets/tables/linked_scroll.dart';

// SERVICES
import 'package:app/services/files/image_file.dart';
import 'package:app/services/inventory/product_date.dart';
import 'package:app/services/inventory/product_image.dart';
import 'package:app/services/inventory/sku_generator.dart';
import 'package:app/services/inventory/table_field_options.dart';
import 'package:app/services/inventory/table_field_type.dart';
import 'package:app/services/stock/tables/table_structure_model.dart';
import 'package:app/services/stock/tables/table_view_service.dart';

// WIDGETS
import 'package:app/screens/modals/shared/image_viewer/_image_viewer.dart';

import 'field_edit.dart';
import 'free_column.dart';
import 'sheet_columns.dart';
import 'sheet_cursor.dart';
import 'sheet_dates.dart';
import 'sheet_drafts.dart';
import 'sheet_drag.dart';
import 'sheet_hover.dart';
import 'sheet_keys.dart';
import 'sheet_metrics.dart';
import 'sheet_widths.dart';

/// Strip at the sides of the spreadsheet in which, while dragging a column,
/// the band starts scrolling on its own.
const double _kEdgeMargin = 48;

/// How much it scrolls at most in each frame of that scrolling.
const double _kEdgeStep = 24;

/// From how many options the dropdown of a list cell brings a search box.
///
/// Below that the list is gone through at a glance and the search box would
/// be one more row between the cell and what one wants to tap; above that,
/// it's what turns choosing into typing three letters.
const int _kOptionSearchFrom = 10;

// The actions of an image cell's dropdown. They're internal values —they're
// not stored nor travel anywhere— and they're named so that the `switch` that
// dispatches them reads well.
const String _kImageView = "view";
const String _kImageUpload = "upload";
const String _kImageLibrary = "library";
const String _kImageRemove = "remove";

/// The brain of the spreadsheet: everything that can be *done* on it.
///
/// It's not a [Listenable] on purpose. If it were, any widget that wanted to
/// call an action would have to subscribe to it, and with that we'd be back
/// to square one: a single notice that repaints the whole screen. Here
/// widgets read it (`context.read`) to ask it for things, and listen to the
/// little pieces of state that do notify and that are small on purpose:
/// [cursor], [columns], [drafts], and the widths of [widths], one per column.
///
/// The division is: this object decides **what happens**, the notifiers say
/// **who finds out**, and the widgets only draw.
class SheetController {
  SheetController({
    required this.service,
    required this.metrics,
    required this.widths,
    required BuildContext Function() context
  }) : _context = context {
    columns = SheetColumns(service);
    _onColumns();

    _vertical = LinkedScrollGroup([vGutter, vBody]);

    columns.addListener(_onColumns);
    drafts.addListener(_onRows);
    service.addListener(_onRows);
    vBody.addListener(_prefetch);

    _onRows();
  }

  /// The state of the open table: the structure and the records. The screen
  /// owns it, not this controller, which only uses it.
  final TableViewService service;

  /// The geometry of the spreadsheet. It's immutable and pure.
  final SheetMetrics metrics;

  /// The width of each column, with one notifier per column.
  final SheetWidths widths;

  /// The context of the screen. It's needed for what leaves the spreadsheet
  /// —asking for confirmation, showing an error flag, translating— and it's
  /// requested as a function because the controller outlives any `build`.
  final BuildContext Function() _context;

  final SheetCursor cursor = SheetCursor();
  final SheetDrafts drafts = SheetDrafts();

  /// The row the mouse is over. Nothing the spreadsheet does looks at it —it
  /// doesn't change what happens when tapping or writing—: it's only what
  /// that row is painted with.
  final SheetHover hover = SheetHover();

  /// In which format each date column is being read. Like [hover], it doesn't
  /// change what the spreadsheet does: it's only what that column is written
  /// with.
  final SheetDates dates = SheetDates();

  /// The column being dragged out of place, while it lasts. The grid doesn't
  /// listen to it: only the ghost drawn on top does.
  final SheetDrag drag = SheetDrag();

  late final SheetColumns columns;

  // Spreadsheet bands: the row-number one (frozen on the left) and the data
  // one. They scroll together vertically; the horizontal one is only for the
  // data band, so the row numbers don't leave the screen.
  final ScrollController vGutter = ScrollController();
  final ScrollController vBody = ScrollController();
  final ScrollController horizontal = ScrollController();

  // The reference is kept to keep alive the listeners that synchronize the two
  // vertical bands.
  // ignore: unused_field
  late final LinkedScrollGroup _vertical;

  /// Focus of the whole spreadsheet. It handles the navigation keys when the
  /// cursor is in a cell that isn't written (a field the backend carries, a
  /// row that hasn't arrived yet), where there's no editor to receive them,
  /// so the grid can keep being traversed.
  final FocusNode grid = FocusNode();

  /// Occupied rows: records + drafts + the ones gained by going down with the
  /// keyboard. It's the only thing the spreadsheet body listens to; the extra
  /// blank rows are put by the `build`, which is the one that knows how many
  /// fit on screen.
  final ValueNotifier<int> usedRows = ValueNotifier(0);

  /// The cell whose photo is being uploaded, while it lasts, or `null` if there
  /// is none.
  ///
  /// It's a single one —two uploads can't be started without closing the first
  /// one's dropdown— and that's why it's a value and not a list. Each image
  /// cell listens to it, which is the only thing that needs repainting: the
  /// row doesn't change size or content while the photo travels, only that
  /// little square shows its loading (see [ImageCell]).
  final ValueNotifier<SheetCell?> uploading = ValueNotifier(null);

  // Editor of the active cell. A new one is created per cell (the same
  // [FocusNode] isn't reused between two positions of the tree) and the
  // previous one is released after the frame, when its [TextField] has been
  // unmounted.
  TextEditingController? editor;
  FocusNode? focus;

  /// What the cell had when it opened. It's what Escape goes back to, because
  /// every key was already dumped into the draft (or the column's title) and
  /// without this there'd be nothing to undo.
  String _initial = "";

  /// Queued column writes (creations, renames, and deletions). Each one
  /// reloads the table and the service ignores a reload while another is in
  /// progress, so two consecutive changes are sent one after the other and
  /// not at the same time.
  Future<void> _columnQueue = Future.value();

  /// Queued row creations. It's the same reason as the column queue:
  /// each creation re-reads the table and the service ignores a creation
  /// while another is in progress, so two rows written one after the other
  /// —which is the norm when loading— are sent in line and not at once.
  Future<void> _rowQueue = Future.value();

  /// The row that's already saved but is still drawn, and how many records the
  /// table had when it was sent.
  ///
  /// The two halves of the spreadsheet are separated by the number of records
  /// ([draftIndex]), so the draft can't be removed before the table counts
  /// the new record: between one thing and the other, the rows below would
  /// move out of place, and that's precisely the moment spent writing the
  /// next row. See [_dropPersisted].
  SheetDraft? _persisted;
  int _persistedAt = 0;

  /// Extra blank rows gained by going down with the keyboard past the end of
  /// the spreadsheet.
  int _extraRows = 0;

  /// Where, on the screen, the left edge of the first column lands. It's the
  /// only thing needed to take the pointer to the content coordinates
  /// (`content = screen - origin`), which are the ones the column edges sit
  /// in and in which the ghost is drawn. It's solved once when the drag
  /// starts and corrected when the band scrolls on its own.
  double _dragOrigin = 0;

  /// Last position of the pointer on the screen. The auto-scroll needs it:
  /// while the band scrolls under a still pointer, the column still changes
  /// neighbors.
  double _dragPointer = 0;

  /// Scrolls the spreadsheet while a column is dragged against an edge.
  Timer? _dragScroll;

  /// The column whose width is being dragged, and the width it had when
  /// starting: it's what's compared at release to know if there's something
  /// to save, and what it goes back to if the save doesn't go through.
  int _resizing = -1;
  double _resizedFrom = 0;

  /// How many rows the body has right now. The `build` sets it, which is the
  /// one that knows how many fit on screen, and the keyboard and the batch
  /// reading read it.
  int _rows = 0;

  bool _disposed = false;
  bool _prefetchScheduled = false;

  int get rows => _rows;

  /// Tells it how many rows stayed drawn. It's called from the `build`, that's
  /// why it's a bare assignment: it doesn't notify anyone.
  void setRows(int rows) => _rows = rows;

  // ---- Cursor and editing --------------------------------------------------

  /// Tap on a cell: if it can be written, it opens the editor; if not (a field
  /// the backend carries, a row that hasn't arrived yet, a column being
  /// created) it just selects it, like a spreadsheet in which everything can
  /// be traversed even if not everything is written.
  ///
  /// Fields that are **chosen** instead of written (a list) open their
  /// dropdown instead of the editor, anchored to the cell: that's what
  /// [anchor] is for, which is the context of the tapped cell. Without it —a
  /// tap that doesn't pass it— the cell stays selected and nothing else,
  /// which is the same thing the keyboard does.
  void tap(int row, int column, {BuildContext? anchor}) {
    final cell = SheetCell(row, column);

    if (!canEdit(row, column)) {
      select(cell);
      return;
    }

    // The field row is always written: what's there is the column's title, not
    // a datum of its type.
    if (row != kFieldsRow && isPicker(column)) {
      if (typeAt(column) == TableFieldType.image) {
        pickImage(cell, anchor);
      } else {
        pickOption(cell, anchor);
      }
      return;
    }

    open(cell);
  }

  /// Whether that column is tapped instead of written: a list or an image,
  /// whose cells unfold something and don't open a text editor.
  bool isPicker(int column) => typeAt(column).picker;

  /// The type of that column. A free column —which isn't a field yet— has no
  /// type and falls into text, like any unknown code.
  TableFieldType typeAt(int column) =>
    TableFieldType.from(columns.typeOf(column));

  /// Leaves the cell selected but without an editor (a cell that isn't
  /// written). Focus moves to the spreadsheet so the navigation keys keep
  /// arriving, since there's no editor to receive them.
  void select(SheetCell cell) {
    close();
    _leaveRow(cell.row);
    cursor.move(cell);

    grid.requestFocus();
    reveal(cell);
  }

  /// Opens the editor in [cell] with what that cell already had written.
  ///
  /// A new [TextEditingController] and [FocusNode] are created per cell
  /// instead of reusing the same ones: the [TextField] changes place in the
  /// tree and a [FocusNode] can't be shared between two positions. The
  /// previous ones are released after the frame, when their widget has been
  /// unmounted.
  void open(SheetCell cell) {
    // Tapping the cell that's already being edited (a double click, for
    // example) must not recreate the editor: `cursor.move` doesn't notify if
    // the cell and the state don't change, so closing and reopening would
    // leave the `TextField` mounted using a `FocusNode` that this method
    // already sent to dispose.
    if (cursor.editing && cursor.cell == cell) return;

    close();
    _leaveRow(cell.row);

    final text = valueOf(cell);
    _initial = text;

    final node = FocusNode(onKeyEvent: handleKey);
    node.addListener(() => _onFocus(node));

    editor = TextEditingController(text: text)
      ..selection = TextSelection.collapsed(offset: text.length);
    focus = node;

    cursor.move(cell, editing: true);
    reveal(cell);
  }

  /// Closes the editor saving in the draft what was written. It doesn't touch
  /// the cursor: the cell stays selected.
  ///
  /// **Leaving the cell is what sends the change**, and that's why none of
  /// this goes in [commit], which runs on every key: it's written whole and
  /// only travels on leaving. In the field row that's the creation of a free
  /// column with a title, the rename of a field, or its deletion if it was
  /// left without a title ([finishField]); in an already saved row, the
  /// correction of that cell ([finishRecord]).
  ///
  /// The blank rows below are the only ones that send nothing when leaving
  /// the **cell**: they're gathered as a draft and saved whole when leaving
  /// the **row** ([_leaveRow]), because until they're saved they aren't a
  /// record to write an individual cell to.
  void close({bool commit = true}) {
    final cell = cursor.cell;
    final editing = cursor.editing;

    if (commit) {
      _normalizeDate(cell);
      this.commit();
    }

    final closing = editor;
    final closingFocus = focus;
    editor = null;
    focus = null;
    cursor.stopEditing();

    if (commit && editing && cell != null) {
      if (cell.row == kFieldsRow) {
        finishField(cell.column, closing?.text ?? "");
      } else if (cell.row < service.records) {
        finishRecord(cell, closing?.text ?? "");
      }
    }

    if (closing == null && closingFocus == null) return;

    // The [TextField] is still mounted in this frame: releasing its controller
    // and its focus now would leave it using dead objects.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      closing?.dispose();
      closingFocus?.dispose();
    });
  }

  /// Leaves the cell's date written as the table saves it.
  ///
  /// It's what lets one write it however it comes out —`12 2 26`,
  /// `12/02/2026`, `2026.02.12`— and have only one form remain in the table
  /// (see [ProductDate.normalize]). It runs on leaving the cell and not in
  /// [commit], which runs on every key: normalizing while typing would
  /// rewrite for one what they're writing midway.
  ///
  /// What isn't a date stays as is. The cell doesn't throw it away either:
  /// what someone put remains visible (see [DateCell]).
  void _normalizeDate(SheetCell? cell) {
    final editor = this.editor;

    if (cell == null || editor == null || cell.row == kFieldsRow) return;
    if (!typeAt(cell.column).isDate) return;

    final text = ProductDate.normalize(editor.text);
    if (text != editor.text) editor.text = text;
  }

  /// Every key is dumped into the draft (or the column's title), not only when
  /// leaving the cell: that way the row offers to be saved —the check on its
  /// number, the bar's button— from the first letter, and writing the title
  /// of the last free column makes the next one appear while typing.
  ///
  /// Each notifier decides whether that repaints something, and none notifies
  /// for a letter that doesn't change anything on screen.
  void onChanged(String text) => commit();

  /// Dumps the editor's text where it belongs.
  void commit() {
    final cell = cursor.cell;
    final text = editor?.text;
    if (!cursor.editing || cell == null || text == null) return;

    // The title of a free column lives in the free columns until the field is
    // created.
    if (cell.row == kFieldsRow) {
      columns.writeFree(cell.column, text);
      return;
    }

    final index = draftIndex(cell.row);
    if (index < 0) return;

    // It's saved by the field's place in the structure and not by where it's
    // seen, which is the same thing read records do: that way dragging a
    // column out of place carries what was being written with it, without
    // touching a single draft.
    drafts.write(index, columns.slotAt(cell.column), text);
  }

  /// Undoes what was written in the cell and closes the editor: the cell goes
  /// back to what it had when it opened. A free column whose title was being
  /// written isn't created, and if it keeps the previous title it's because
  /// it already had it.
  void cancel() {
    final editor = this.editor;

    if (editor != null) {
      editor.text = _initial;
      commit();
    }

    close(commit: false);
  }

  /// Leaves the spreadsheet as if just opened: no cursor, without the extra
  /// rows that might have been gained going down with the keyboard, and at
  /// the top.
  ///
  /// The screen calls it when changing the search, which is when the rows
  /// become other ones: leaving the cursor where it was would leave it over
  /// the row that now occupies that place —which isn't the one being looked
  /// at— and leaving the scroll, in the middle of a result shorter than what
  /// had been scrolled.
  ///
  /// It doesn't close any editor: to write in the search box one had to leave
  /// the spreadsheet, and that already closed it and left the row saved
  /// ([_onFocus]).
  void reset() {
    cursor.clear();

    _extraRows = 0;
    _onRows();

    if (vBody.hasClients) vBody.jumpTo(0);
  }

  /// Losing focus (tapping outside the spreadsheet, opening a modal) confirms
  /// what was written and closes the editor, like leaving a cell. And since
  /// there it goes not to another row but to none, the row being written is
  /// also left: if it had something loaded, it's saved.
  void _onFocus(FocusNode node) {
    // Leaving the screen with a cell open releases its [FocusNode], and that
    // also notifies that it lost focus: without this guard a screen that's no
    // longer there would be touched.
    if (_disposed) return;
    if (!identical(node, focus) || node.hasFocus) return;

    close();
    _leaveRow(null);
  }

  /// Keys of the spreadsheet. The editor's [FocusNode] handles them, seeing
  /// them before the [TextField] itself (so Tab doesn't change widget and
  /// Enter doesn't trigger submit) and, when there's no editor open, the grid
  /// focus, which is its ancestor and receives what the editor lets through.
  KeyEventResult handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    // Without a chosen cell there's nothing to move: the keys continue their way
    // (Tab goes back to tabbing through the screen, Escape closes whatever is
    // open).
    final cell = cursor.cell;
    if (cell == null) return KeyEventResult.ignored;

    final intent = SheetKeyIntent.of(
      event.logicalKey,
      shift: HardwareKeyboard.instance.isShiftPressed,
      editing: cursor.editing
    );

    if (intent == null) return KeyEventResult.ignored;

    if (intent == SheetKeyIntent.cancel) {
      cancel();
      return KeyEventResult.handled;
    }

    final move = intent.move!;
    _move(cell, rows: move.rows, columns: move.columns, wrap: move.wrap);

    return KeyEventResult.handled;
  }

  /// Moves the cursor, dragging the editor along. Going past the last row adds
  /// another blank one: the spreadsheet doesn't end.
  ///
  /// Except when searching, which is the only thing that does end: what's
  /// seen are the matching rows and below there's nowhere to write (see
  /// [_onRows]), so going below the last one stays on the last one.
  void _move(
    SheetCell from, {
    required int rows,
    required int columns,
    required bool wrap
  }) {
    final last = this.columns.length - 1;
    if (last < 0) return;

    final target = sheetDestination(
      from: from,
      rows: rows,
      columns: columns,
      wrap: wrap,
      lastColumn: last
    );

    if (service.isSearching && target.row >= _rows) return;

    if (target.row >= _rows) {
      _extraRows += target.row - _rows + 1;
      _rows = target.row + 1;
      _onRows();
    }

    // What can't be written (a field the backend carries, a row that hasn't
    // arrived yet) gets selected anyway, and from there navigation continues.
    // A list doesn't open an editor either: it's gone through with the arrows
    // like any cell and unfolds by tapping it, which is where the dropdown's
    // anchor comes from.
    if (!canEdit(target.row, target.column) ||
        (target.row != kFieldsRow && isPicker(target.column))) {
      select(target);
      return;
    }

    open(target);
  }

  /// Brings cell [cell] into view. It's done after the frame because the row
  /// might be one just added that doesn't have an extent yet.
  void reveal(SheetCell cell) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;

      if (vBody.hasClients) {
        final to = metrics.revealRow(
          row: cell.row,
          offset: vBody.offset,
          viewport: vBody.position.viewportDimension,
          maxExtent: vBody.position.maxScrollExtent
        );

        if (to != null) vBody.jumpTo(to);
      }

      if (horizontal.hasClients && cell.column < columns.length) {
        final to = metrics.revealColumn(
          left: widths.offsetOf(cell.column),
          width: widths.widthAt(cell.column),
          offset: horizontal.offset,
          viewport: horizontal.position.viewportDimension,
          maxExtent: horizontal.position.maxScrollExtent
        );

        if (to != null) horizontal.jumpTo(to);
      }
    });
  }

  /// Whether the cell can be written.
  ///
  /// In the field row, [SheetColumns.canEditAt] decides it. In the body, both
  /// halves of the spreadsheet are written —the records and the blank rows
  /// below—, as long as the column is already a field with a type that's
  /// loaded by hand.
  ///
  /// The only thing that distinguishes a record is that it has to **have
  /// arrived**: a row whose batch hasn't entered yet exists and occupies its
  /// place, but neither what it has loaded nor which one it is is known, so
  /// it can be traversed and still not written.
  bool canEdit(int row, int column) {
    final sheet = columns.at(column);
    if (sheet == null) return false;

    if (row == kFieldsRow) return columns.canEditAt(column);

    // A free column has nowhere to store until it's created, and what the
    // backend carries (counter, stock) isn't written by hand.
    if (!sheet.isField || !TableFieldType.from(sheet.type).editable) {
      return false;
    }

    // Without the record's id there's no table row to send the change to.
    if (row < service.records) return service.rowAt(row)?.id.isNotEmpty ?? false;

    // A row being saved is about to stop being a draft: what's written over it
    // would be lost when the record arrives. It can be traversed, like any
    // row that isn't written yet.
    return !(drafts.at(draftIndex(row))?.saving ?? false);
  }

  /// What the cell already has written: the title of the field or the free
  /// column, if it's the field row; the saved value, if it's a record; or
  /// what's been loaded in the draft row.
  String valueOf(SheetCell cell) {
    if (cell.row == kFieldsRow) return columns.nameOf(cell.column);

    final slot = columns.slotAt(cell.column);
    final index = draftIndex(cell.row);

    // A record opens with what it has loaded: editing it is correcting that
    // value, not writing over a blank cell.
    if (index < 0) return service.rowAt(cell.row)?.at(slot)?.toString() ?? "";

    return drafts.textAt(index, slot);
  }

  /// The cell's value **without converting to text**.
  ///
  /// It's [valueOf] for the only type whose datum isn't a text: a multi-tag
  /// cell stores a list, and the `toString()` of a list (`[a, b]`) isn't any
  /// of its tags. A draft stores text the same —a line is written and the
  /// backend splits it—, so from there comes back the same as from [valueOf].
  dynamic rawOf(SheetCell cell) {
    if (cell.row == kFieldsRow) return columns.nameOf(cell.column);

    final slot = columns.slotAt(cell.column);
    final index = draftIndex(cell.row);

    if (index < 0) return service.rowAt(cell.row)?.at(slot);

    return drafts.textAt(index, slot);
  }

  /// Index of the draft that row of the body gets, or negative if that row is
  /// a record of the table.
  ///
  /// The rows that are written start behind the last record, and how many
  /// there are is told by the structure from the start: that's why a blank
  /// row doesn't move out of place when a new batch of records comes in, even
  /// if it's being read while writing in it.
  int draftIndex(int row) => row - service.records;

  // ---- Column widths -------------------------------------------------------

  /// Starts dragging a column's width: the one it had is noted, which is what
  /// it goes back to if the save doesn't go through.
  void startResize(int index) {
    _resizing = index;
    _resizedFrom = widths.valueOf(columns.keyOf(index));
  }

  /// Drags a column's width. Only that column finds out.
  void resize(int index, double delta) =>
    widths.resize(columns.keyOf(index), delta);

  /// Releases the edge: the width the column ended up with is saved.
  ///
  /// It's sent **on release** and not on every drag event, which are dozens
  /// per second. If nothing changed —a tap on the edge, or a column that was
  /// already at the minimum— nothing travels, and neither does the one of a
  /// free column at the end: it isn't a field yet, there's nowhere to save
  /// its width (it'll have it only when it's created and dragged again).
  void endResize(int index) {
    final from = _resizedFrom;
    final resizing = _resizing;

    _resizing = -1;
    if (resizing != index) return;

    final field = columns.fieldAt(index);
    if (field == null || field.id.isEmpty) return;

    final width = widths.valueOf(field.id);
    if (width == from) return;

    _columnQueue = _columnQueue.then((_) => _sendWidth(field, width, from));
  }

  /// Sends the new width. It goes through the same queue as the creations,
  /// renames, and deletions: each of those re-reads the structure, and sending
  /// the width while a re-read is in the air would write it against an old
  /// name (editing a field also sends its name, which the backend always asks
  /// for).
  ///
  /// If it doesn't go through, the column goes back to the width it had. The
  /// service already showed the error.
  Future<void> _sendWidth(
    TableFieldModel field,
    double width,
    double before
  ) async {
    if (_disposed) return;

    final saved = await service.resizeField(_context(), field, width: width);
    if (_disposed || saved) return;

    widths.restore(field.id, before);
  }

  // ---- Column dragging -----------------------------------------------------

  /// Starts dragging column [index] out of place, grabbing it by its field
  /// cell.
  ///
  /// Only the table's fields are dragged, and only while they don't have a
  /// change on the way: a free column at the end has no position to save, and
  /// one being created or deleted still doesn't have a known place to fall.
  ///
  /// Whatever was being written is closed first: the cell is about to change
  /// place and the editor can't follow it.
  void startColumnDrag(int index, DragStartDetails details) {
    close();

    final column = columns.at(index);
    if (column == null || !column.isField || columns.busyAt(index)) return;

    // The spreadsheet's geometry is solved **once**: from here on, each
    // pointer event is a subtraction and a search over this list.
    final edges = widths.edges();
    if (index + 1 >= edges.length) return;

    drag.start(
      source: index,
      label: columns.nameOf(index),
      grab: details.localPosition.dx,
      edges: edges,
      fields: columns.fieldCount
    );

    // Where the 0 of the content is: the pointer fell on `edges[index]` plus
    // how much it moved inside the cell.
    _dragOrigin =
      details.globalPosition.dx - edges[index] - details.localPosition.dx;
    _dragPointer = details.globalPosition.dx;
  }

  void updateColumnDrag(DragUpdateDetails details) {
    if (!drag.active.value) return;

    _dragPointer = details.globalPosition.dx;
    drag.moveTo(_dragPointer - _dragOrigin);

    _edgeScroll();
  }

  /// Releases the column where the line ended up.
  ///
  /// The new order is applied **now**, without waiting for the backend: the
  /// spreadsheet reorders itself (which costs no more than redoing the grid,
  /// because the records don't move from where they are) and the positions
  /// travel behind.
  void endColumnDrag() {
    _stopEdgeScroll();

    final (from, to) = drag.stop();
    if (from < 0) return;

    final before = columns.reorder(from, to);
    if (before == null) return;

    // The column moved to another place and took with it the meaning of the
    // chosen cell: the cursor points at a position that is now another column.
    cursor.clear();

    _columnQueue = _columnQueue.then((_) => _sendOrder(before));
  }

  /// The drag was cut without releasing (the pointer was lost, something
  /// opened on top): the column stays where it was.
  void cancelColumnDrag() {
    _stopEdgeScroll();
    drag.stop();
  }

  /// Sends the new order. It goes through the same queue as the creations,
  /// renames, and deletions: each of those re-reads the structure, and sending
  /// the positions while a re-read is in the air would write them against old
  /// names.
  ///
  /// If it doesn't go through, the spreadsheet goes back to the order it had.
  /// The service already showed the error.
  Future<void> _sendOrder(List<String> before) async {
    if (_disposed) return;

    final saved = await service.reorderFields(_context(), columns.ordered);
    if (_disposed || saved) return;

    columns.restoreOrder(before);
  }

  /// Scrolls the spreadsheet when the dragged column reaches an edge, so it
  /// can be taken further than what's seen.
  ///
  /// The pointer can stay still against the edge, so the scroll can't be
  /// triggered by the event: a tick is turned on for as long as it's needed
  /// and goes off as soon as the column comes back to the middle.
  void _edgeScroll() {
    if (_edgeOvershoot() == 0) {
      _stopEdgeScroll();
      return;
    }

    _dragScroll ??= Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _edgeStep()
    );
  }

  /// How much the pointer went into a side's margin, with sign: negative
  /// against the left, positive against the right, `0` in the middle.
  ///
  /// It's what decides whether to scroll the spreadsheet and at what speed:
  /// grazing the edge scrolls it slowly and leaning against it goes fast, like
  /// in any spreadsheet.
  double _edgeOvershoot() {
    if (!horizontal.hasClients) return 0;

    final left = _dragOrigin + horizontal.offset;
    final right = left + horizontal.position.viewportDimension;

    if (_dragPointer < left + _kEdgeMargin) {
      return _dragPointer - left - _kEdgeMargin;
    }

    if (_dragPointer > right - _kEdgeMargin) {
      return _dragPointer - right + _kEdgeMargin;
    }

    return 0;
  }

  /// A tick: scrolls the spreadsheet what's due and goes off when there's no
  /// direction left (the column came back to the middle, or the band reached
  /// the end).
  void _edgeStep() {
    final step = _disposed || !drag.active.value ? 0.0 : _edgeOvershoot();

    if (step == 0) {
      _stopEdgeScroll();
      return;
    }

    final to = (horizontal.offset + step.clamp(-_kEdgeStep, _kEdgeStep))
      .clamp(0.0, horizontal.position.maxScrollExtent);

    final moved = to - horizontal.offset;
    if (moved == 0) {
      _stopEdgeScroll();
      return;
    }

    horizontal.jumpTo(to);

    // The content moved under a pointer that didn't: the same place on the
    // screen is now another place of the content, so the ghost has to follow
    // the spreadsheet and not the pointer.
    _dragOrigin -= moved;
    drag.moveTo(_dragPointer - _dragOrigin);
  }

  void _stopEdgeScroll() {
    _dragScroll?.cancel();
    _dragScroll = null;
  }

  // ---- Actions -------------------------------------------------------------

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

    draft.values.forEach((index, text) {
      if (index < 0 || index >= fields.length) return;

      final field = fields[index];
      final value = text.trim();
      if (value.isEmpty || field.id.isEmpty) return;

      values[field.id] = value;
    });

    if (values.isEmpty) return;

    drafts.setSaving(draft, true);

    // The creation goes without a re-read and the re-read is asked here below,
    // with the row already noted as persisted: that way the draft can be
    // removed at the same instant the table starts counting the new record.
    final saved = await service.add(_context(), values, refresh: false);
    if (_disposed) return;

    if (!saved) {
      drafts.setSaving(draft, false);
      return;
    }

    // The row is already a record of the backend, but the spreadsheet still
    // counts the previous ones: it's left where it is —and in a spinner, so
    // nothing is written over it— until the re-read brings the new record.
    _persisted = draft;
    _persistedAt = service.records;

    await service.refresh();
    if (_disposed) return;

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
      options: TableFieldType.menu(anchor),
      selected: current.value,
      searchPlaceholder: S.of(anchor).table_field_type_placeholder,
      emptyText: S.of(anchor).table_field_type_empty,
      maxOptions: 4
    );

    if (_disposed || picked == null || picked.value == current.value) return;

    await service.editField(_context(), field, type: picked.value);
  }

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

  // ---- Images --------------------------------------------------------------

  /// Opens the dropdown of an image cell, anchored to the cell ([anchor] is
  /// its context).
  ///
  /// It's the equivalent of [pickOption] for photos, and that's why it's a
  /// dropdown and not an editor: an image isn't written. What's chosen isn't
  /// a value but **what to do with it** —see it, load one, remove it— because
  /// the cell's datum isn't something someone can type.
  ///
  /// The options depend on what the cell has: seeing and removing only appear
  /// if there's a photo, because offering them over an empty cell is offering
  /// two things that do nothing. Choosing one from a library isn't available
  /// yet —the backend already accepts it (`FILE_ID`), what's missing is from
  /// which list to choose it— so it's shown announced and does nothing when
  /// touched.
  ///
  /// A row that isn't a record yet can't have photos: the photo is uploaded
  /// **against a product**, and the product doesn't exist yet. It's said so
  /// instead of opening a dropdown where everything would be off.
  Future<void> pickImage(SheetCell cell, BuildContext? anchor) async {
    select(cell);

    if (anchor == null || !anchor.mounted) return;

    final field = columns.fieldAt(cell.column);
    if (field == null || field.id.isEmpty) return;

    if (draftIndex(cell.row) >= 0) {
      FloatFlag.of(anchor).error(
        message: S.of(anchor).product_table_view_image_unsaved
      );
      return;
    }

    final slot = columns.slotAt(cell.column);
    final images = ProductImage.from(service.rowAt(cell.row)?.at(slot));
    final cover = images.isEmpty ? null : images.first;

    final picked = await showSelectMenu(
      context: anchor,
      options: [
        if (cover != null) SelectOption(
          value: _kImageView,
          placeholder: S.of(anchor).product_table_view_image_view,
          icon: CI.eye
        ),
        SelectOption(
          value: _kImageUpload,
          placeholder: S.of(anchor).product_table_view_image_upload,
          icon: CI.add_image
        ),
        SelectOption(
          value: _kImageLibrary,
          placeholder: S.of(anchor).product_table_view_image_library,
          subtitle: S.of(anchor).coming_soon,
          icon: CI.image
        ),
        if (cover != null) SelectOption(
          value: _kImageRemove,
          placeholder: S.of(anchor).product_table_view_image_remove,
          icon: CI.trash
        )
      ],
      // Hangs from a cell, which measures one row: with the usual size —a form
      // field's— four options would cover half the spreadsheet.
      dense: true
    );

    if (_disposed || picked == null || !anchor.mounted) return;

    switch (picked.value) {
      case _kImageView:
        await showImageViewer(anchor, url: cover!.url);
      case _kImageUpload:
        await _uploadImage(cell, anchor, slot);
      case _kImageRemove:
        await _removeImage(cell, anchor, slot, cover!);
      // The library isn't available yet: the option is shown announced and does
      // nothing.
      default:
        break;
    }
  }

  /// Picks a photo from the disk and uploads it to the cell.
  ///
  /// The weight is measured **before** uploading anything: the limit is the
  /// backend's multipart one, so going over it is a rejection on the other
  /// side and saying it here saves the whole trip.
  ///
  /// It's not cropped, unlike a company's logo: a logo is always drawn square
  /// and one has to decide which half of a landscape photo is seen, but a
  /// product photo is saved as it is and the cell frames it on its own (see
  /// [ImageCell]). What's uploaded is what was chosen.
  Future<void> _uploadImage(
    SheetCell cell,
    BuildContext anchor,
    int slot
  ) async {
    final bytes = await pickImageBytes(
      label: S.of(anchor).product_table_view_image_files
    );

    if (bytes == null || _disposed) return;

    if (bytes.length > kImageMaxBytes) {
      if (anchor.mounted) {
        FloatFlag.of(anchor).error(
          message: S.of(anchor).product_table_view_image_large
        );
      }
      return;
    }

    // The upload travels as multipart and that asks for a file, not a block
    // of memory: it's left in the temp folder for as long as it lasts and
    // deleted no matter what happens.
    final file = await writeTempImage(bytes, name: "product");

    uploading.value = cell;

    try {
      await service.addImage(
        _context(),
        row: cell.row,
        slot: slot,
        file: file
      );
    } finally {
      await discardTempImage(file);
      if (!_disposed) uploading.value = null;
    }
  }

  /// Removes the cover from the cell.
  ///
  /// They're two different removals depending on whose the photo is, and it
  /// has to be told apart: the one this platform stores is removed against
  /// the backend, which also deletes the bytes when no other product shows
  /// them; an address that arrived in an import isn't a file of ours —there's
  /// nothing to delete— so the cell is emptied, which is what that column
  /// stores.
  Future<void> _removeImage(
    SheetCell cell,
    BuildContext anchor,
    int slot,
    ProductImage cover
  ) async {
    if (!cover.isStored) {
      _writeOption(cell, "");
      return;
    }

    await service.removeImage(
      _context(),
      row: cell.row,
      slot: slot,
      fileId: cover.id
    );
  }

  /// Saves the chosen option in the cell, through the same path as the text
  /// that's written: to the draft if the row is still being put together, and
  /// as a correction of the record if it's already a row of the table.
  void _writeOption(SheetCell cell, String value) {
    final index = draftIndex(cell.row);

    if (index >= 0) {
      drafts.choose(index, columns.slotAt(cell.column), value);
      return;
    }

    finishRecord(cell, value, before: valueOf(cell));
  }

  /// Builds a random SKU and saves it in [cell].
  ///
  /// In a record it's one more correction, like choosing an option from a
  /// list ([_writeOption]). In one of the blank rows below, besides, **it
  /// creates it on the spot**: it doesn't wait for the cursor to leave the
  /// row, which is what creates the record when the row is written by hand
  /// ([_leaveRow]).
  ///
  /// It's the exception to that rule and it has to be. Tapping the button is
  /// a complete gesture —nothing stays half-written after it, like it would
  /// stay after a letter— and on top of that it's tapped without entering the
  /// row: the button eats the cell's tap, so the cursor was never there and
  /// will never leave from there. Without this the row would stay with its
  /// code set and without a record until someone touches it for another
  /// reason, which is exactly what used to happen.
  void generateSku(SheetCell cell) {
    final index = draftIndex(cell.row);

    _writeOption(cell, nextSku());

    if (index < 0) return;

    // The editor can be open in another cell of this same row. It's closed
    // before the creation so what was typed goes into the draft —and travels
    // with it— and doesn't stay editing a row that in an instant is going to
    // be a record: on closing it would send again there, already as a
    // correction, what was just saved.
    if (cursor.editing && cursor.cell?.row == cell.row) close();

    _queueDraft(drafts.at(index));
  }

  void back(BuildContext context) => Navis.push(context, "/home/inventory");

  // ---- Reactions -----------------------------------------------------------

  /// Gained or lost a column: the widths have to know which is the current
  /// list to be able to add up the spreadsheet's total width, and the columns
  /// that appear open with the width they had saved.
  void _onColumns() {
    widths.setKeys(columns.keys);

    // The width comes with the field, so the table draws itself as the last
    // one who set it up left it from the first frame. Only the first time it
    // sees each column adopts it: whatever is dragged afterwards rules over
    // what a re-read structure brings (see [SheetWidths.adopt]).
    for (final field in columns.ordered) {
      if (field.id.isEmpty) continue;
      widths.adopt(field.id, field.width);
    }
  }

  /// The number of occupied rows changed. It's the only thing the service
  /// sends the spreadsheet's body: the batches of records that keep entering
  /// are heard by each row on its own.
  ///
  /// It's also where the row that was just saved says goodbye: the notice that
  /// brings one more record is the same one that has to take its draft away
  /// (see [_dropPersisted]).
  /// Searching, the spreadsheet measures **exactly** the matching rows: neither
  /// drafts nor extra rows.
  ///
  /// A filtered spreadsheet isn't where one loads: the row written below
  /// wouldn't belong to the search —it's born empty, it doesn't mention what
  /// was searched— so on saving it would leave the screen it was written on.
  /// And the place where it was written isn't a place of the table either: the
  /// rows of a search are skipped, the one at the very bottom isn't the last
  /// of the table. To load, the search box is emptied, which brings back the
  /// whole spreadsheet with its blank rows at the end.
  void _onRows() {
    _dropPersisted();

    usedRows.value = service.isSearching
      ? service.records
      : service.records + drafts.length + _extraRows;

    _schedulePrefetch();
  }

  /// Asks for the batches of the rows that are about to be looked at.
  ///
  /// Before, the `build` of each row triggered this, meaning building the
  /// screen asked for data. Now the scroll triggers it, which is what really
  /// changes what's seen: with `itemExtent` the first and last visible rows
  /// come out of a division, without building anything.
  void _prefetch() {
    if (_disposed || !vBody.hasClients) return;

    final (first, last) = metrics.rangeAt(
      offset: vBody.offset,
      viewport: vBody.position.viewportDimension,
      rows: _rows
    );

    if (last < first) return;

    service.ensureRange(first, last + metrics.prefetch);
  }

  /// The first batch (and the one after each reload) is asked for when the
  /// band already has measurements, not before.
  void _schedulePrefetch() {
    if (_prefetchScheduled) return;

    _prefetchScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefetchScheduled = false;
      _prefetch();
    });
  }

  void dispose() {
    _disposed = true;

    _stopEdgeScroll();
    vBody.removeListener(_prefetch);
    columns.removeListener(_onColumns);
    drafts.removeListener(_onRows);
    service.removeListener(_onRows);

    editor?.dispose();
    focus?.dispose();
    grid.dispose();
    vGutter.dispose();
    vBody.dispose();
    horizontal.dispose();

    usedRows.dispose();
    uploading.dispose();
    widths.dispose();
    drag.dispose();

    columns.dispose();
    drafts.dispose();
    cursor.dispose();
    hover.dispose();
    dates.dispose();
  }
}
