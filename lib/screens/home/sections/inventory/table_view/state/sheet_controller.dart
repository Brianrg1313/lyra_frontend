import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/files/image_file.dart';
import 'package:app/services/inventory/field_boolean.dart';
import 'package:app/services/inventory/measure_units.dart';
import 'package:app/services/inventory/product_date.dart';
import 'package:app/services/inventory/product_image.dart';
import 'package:app/services/inventory/sku_generator.dart';
import 'package:app/services/inventory/table_field_options.dart';
import 'package:app/services/inventory/table_field_type.dart';
import 'package:app/services/stock/movements/stock_mover.dart';
import 'package:app/services/stock/tables/table_lite_model.dart';
import 'package:app/services/stock/tables/table_structure_model.dart';
import 'package:app/services/stock/tables/table_view_service.dart';

// WIDGETS
import 'package:core/form/select_input.dart' show SelectOption;
import 'package:core/form/select_menu.dart';
import 'package:core/widgets/tables/linked_scroll.dart';
import 'package:app/screens/modals/inventory/stock_movement/_stock_movement.dart';
import 'package:app/screens/modals/shared/image_viewer/_image_viewer.dart';
import 'package:app/screens/home/sections/inventory/table_view/date_menu.dart';

import './field_edit.dart';
import './free_column.dart';
import './sheet_cell.dart';
import './sheet_columns.dart';
import './sheet_cursor.dart';
import './sheet_dates.dart';
import './sheet_draft.dart';
import './sheet_drafts.dart';
import './sheet_drag.dart';
import './sheet_hover.dart';
import './sheet_keys.dart';
import './sheet_metrics.dart';
import './sheet_widths.dart';

part 'controller/sheet_width_edits.dart';
part 'controller/sheet_column_drag.dart';
part 'controller/sheet_row_writes.dart';
part 'controller/sheet_field_writes.dart';
part 'controller/sheet_option_picks.dart';
part 'controller/sheet_image_picks.dart';
part 'controller/sheet_stock_moves.dart';
part 'controller/sheet_cell_picks.dart';

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
///
/// The class keeps the state, the cursor and the reactions; its writes live in
/// `controller/`, one part per kind (widths, column drag, rows, fields, options,
/// images). They are extensions declared in this library, so they reach its
/// private state without exposing it, and callers import this file alone.
class SheetController {
  SheetController({
    required this.service,
    required this.metrics,
    required this.widths,
    required BuildContext Function() context,
    this.stock,
    this.kind = TableKind.catalog
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

  /// What a record's stock cell moves its product through ([SheetStockMoves]); without one
  /// the stock is only read.
  final StockMover? stock;

  /// What the table holds: it decides whether a column can be made a `STOCK` ([pickType]).
  final TableKind kind;

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

    if (movesStock(cell)) {
      moveStock(cell, anchor);
      return;
    }

    if (!canEdit(row, column)) {
      select(cell);
      return;
    }

    // The field row is always written: what's there is the column's title, not
    // a datum of its type.
    if (row != kFieldsRow && isPicker(column)) {
      switch (typeAt(column)) {
        case TableFieldType.image:
          pickImage(cell, anchor);
        case TableFieldType.boolean:
          toggleBoolean(cell);
        default:
          pickOption(cell, anchor);
      }
      return;
    }

    // A date is typed when the keyboard arrives at it, and picked in a
    // calendar when it is tapped.
    if (row != kFieldsRow && typeAt(column).isDate) {
      pickDate(cell, anchor);
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

    // The editor's `autofocus` only takes when its scope holds no focus. Coming
    // from a selected cell —one that isn't written, or a list whose dropdown just
    // gave the focus back— the grid holds it, so the editor opened without the
    // caret and only a second click (on the text field itself) wrote. The focus
    // is asked for once the editor is mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed || !identical(focus, node) || node.hasFocus) return;
      node.requestFocus();
    });
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
