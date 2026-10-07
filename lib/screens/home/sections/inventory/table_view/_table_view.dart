import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/home/home_service.dart';
import 'package:app/services/stock/tables/table_view_service.dart';
import 'package:app/services/stock/tables/tables_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/inventory/table_list/inventory_bar.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_columns.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_controller.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_cursor.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_dates.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_drafts.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_hover.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_metrics.dart';
import 'package:app/screens/home/sections/inventory/table_view/state/sheet_widths.dart';

import './table_header.dart';
import './table_view_body.dart';

/// View of a table and its data as a spreadsheet: the inventory section's view of
/// the open table while its cells switch is on (`InventorySection`), keyed by the table.
///
/// The grid imitates Excel, not a data table: **the cells already exist**.
/// There is no need to request a new row to load something; below the records
/// there are always extra blank rows (as many as fit on screen, and never fewer
/// than a handful), so loading is just tapping a cell and typing.
///
/// The first row is **always the fields**: it is row 1 of the sheet, with the
/// name and type icon of each column. It is not a decorative header but the real
/// row 1, which is why the first record is row 2, just like a sheet where the
/// first row holds the titles. It stays frozen on top, and the column of row
/// numbers stays frozen on the left.
///
/// The rest of the rows are the records:
/// - The top ones are the data that already came from the backend, and they are
///   **edited where you see them**: you tap the cell, type, and on exit the
///   change travels (`PUT /inventory/products/records/manage/`) without re-reading the table or moving from
///   where you were. Only the tapped cell travels, not the whole row. The only
///   thing not written is what has not arrived yet: a row whose chunk did not
///   load is passed over, but you do not know what it holds or which one it is.
///   There are as many as the table has records, read or not: the sheet is born
///   at its final length and each chunk is requested as it is about to enter the
///   screen, so scrolling down keeps going without paging buttons or breaks.
/// - The bottom ones are empty and editable. As soon as you type in one, that
///   row becomes a draft, and **on leaving the row it saves itself**
///   (`POST /inventory/products/records/manage/`): there is no check mark, button, or anything to confirm.
///   It saves when leaving the row and not each cell because a row is written
///   across several columns: tabbing through it sends nothing and on exit it
///   travels whole, as one create and not one per column. While the create
///   travels, that row's number gives way to a spinner and the row cannot be
///   written; if it does not go through, it stays written as-is and is retried
///   just by leaving it again.
///
/// Navigation is also that of a sheet: Tab / Shift+Tab move between cells, Enter
/// and the up/down arrows move down and up, Escape cancels what was being
/// written. Reaching the end with Tab jumps to the start of the next row, and
/// going past the last row adds another blank one.
///
/// The table grows on its own on both axes, without "add" buttons:
/// - **Horizontal**: there are always free columns left over at the end. Putting
///   a title in one creates it (`POST /inventory/products/builder/fields/`) and another free one
///   appears behind it.
/// - **Vertical**: by typing in the blank rows at the end.
///
/// The **width of each column** is dragged from the right edge of its field
/// cell, and on release it saves with the field (`PUT /inventory/products/builder/fields/`, without
/// re-requesting the table). It is not the preference of whoever dragged it: it
/// is how the table stays, so the next time it is opened —by whoever opens
/// it— the columns measure that. The structure brings it with the fields, so
/// the sheet is drawn already laid out in the first frame instead of jumping
/// later.
///
/// Columns are also **dragged into place** from their field cell, like in a
/// sheet: you grab the title, a line marks where it will land, and on release
/// the column moves there with its width set. The new order is seen
/// instantly and the positions travel behind (`PUT /inventory/products/builder/fields/`), without re-
/// requesting the table: the read records **do not move from where they are**
/// —the only thing that changes is which place of the row each column reads—, so
/// dragging a column costs the same in a ten-record table as in one with
/// hundreds of thousands.
///
/// A field's cell keeps behaving like a cell after it is created, so **the field
/// is edited where you see it** and not in a separate form:
/// typing another title renames it on leaving the cell, the arrow changes its
/// type, and **emptying its title deletes it**, which is the only thing not done
/// on its own: confirmation is requested first, because it takes the column and
/// everything loaded in it.
///
/// The table opens in two phases (see [TableViewService]) and the sheet shows
/// them for what they are:
/// - **The structure** (`GET /inventory/products/builder/structure/<id>`) is what is awaited with a
///   blank screen: without columns there is no sheet to draw, so if it fails
///   what you see is the full-screen error.
/// - **The data** (`POST /inventory/products/records/list/`) arrives later and over an already drawn
///   sheet: it is requested in chunks as you scroll down, without covering
///   anything, and both its wait and its error are announced in the top bar.
///
/// **The header search searches the table.** It is a single one for the whole
/// home and searches the section being viewed ([HomeService.searchQuery]); in
/// this one, the sheet switches to showing the rows that mention what was typed,
/// in any of their columns ([_onSearch]).
///
/// The backend filters, not the sheet (`MATCH`, see [TableViewService.search]):
/// from a table with hundreds of thousands of rows in memory there are only some
/// chunks, so hiding the ones that do not match would search what was viewed and
/// not the table. What is requested already comes filtered, counted, and paged,
/// which is why searching is scrolled like any table: scrolling down loads the
/// following chunks of the result.
///
/// A filtered sheet **has no blank rows at the end**: it is not where you load.
/// What would be written there is born without what was searched, so it would
/// leave the screen where it was written, and the place where it was written is
/// not a table location either —the rows of a search are spread out—. To load,
/// the search box is cleared, which returns the whole table. What you can do
/// instead is **fix what was found**: a cell in a result is written like any
/// other, which is half a reason to search.
///
/// A freshly imported table keeps being built up **with the screen open**, and
/// you learn of it through two different paths, because they are two different
/// things: that its columns already have a type is announced by the backend over
/// a socket and listened to by [TableViewService], which re-reads the table
/// wherever it is; that its rows have already arrived is known by [TablesService],
/// which is the one uploading them, which is why this screen listens to it
/// ([_onImport]). Until both things happen, the top bar says what is going on.
///
/// What does **not** happen anymore is getting here in the middle of that. A
/// table that is still being imported is not mounted: the section shows its import
/// instead, because a sheet with untyped columns and no rows is read as an import that
/// failed and answered by importing the file again.
///
/// ---
///
/// **How repainting is distributed.** The screen is designed for tables with
/// hundreds of thousands of records, so no change may cost the whole grid. This
/// widget does not listen to anything: it creates the service and the
/// [SheetController], publishes them, and is never rebuilt. From there down,
/// each part subscribes to its own thing and nothing more:
///
/// | What happens | What rebuilds |
/// |---|---|
/// | The cursor moves | 2 rows (the one left and the one taken) |
/// | The mouse moves to another row | 2 rows |
/// | The format of a date column changes | the cells of that column |
/// | A width is dragged | the cells of that column |
/// | A column is dragged into place | nothing, until released |
/// | A chunk of records arrives | the rows of that chunk |
/// | A cell is typed in | that cell and, if the row changed state, its row |
/// | A row saves itself | that row and its number |
/// | A cell of a record is fixed | that row |
/// | A column is renamed | that field's cell |
/// | A column's type changes | that field's cell and the ones in its column |
/// | A column is added, deleted, or released | the grid |
/// | Something is searched in the header | the grid (they are other rows) |
///
/// The last three re-read the whole table structure, and even so only the last
/// one costs the grid: what the sheet listens to is **the shape** of the columns
/// ([SheetColumns.shape]), which does not change from a title or a type.
///
/// And none of the three unmounts the screen. A structure re-read over an
/// already drawn table does not go back to [TableStructureStatus.loading]: it is
/// announced in the top bar and the sheet stays where it is, with its scroll
/// position and whatever was being written. Without that, adding a column on row
/// fifty thousand would force scrolling all the way back down.
///
/// The service ([TableViewService]) is owned by this screen and not by the app
/// scope: it is ephemeral state of an open table (its structure and the chunks
/// being viewed), which must restart every time you enter and be discarded on
/// exit.
class TableViewSection extends StatefulWidget {
  const TableViewSection({
    super.key,
    required this.tableId,
    required this.parts,
    this.status = const []
  });

  /// Route key of a table's link (`/home/inventory/:id`): the section opening on that
  /// table. Both the route table and the shell use it.
  static const String routeKey = "inventory_table_view";

  final String tableId;
  final InventoryBarParts parts;

  /// What the section adds to the bar's status (an upload in flight).
  final List<Widget> status;

  @override
  State<TableViewSection> createState() => _TableViewSectionState();
}

class _TableViewSectionState extends State<TableViewSection> {
  // Owned by the screen: it is created on entry and released on exit, without
  // going through an app provider, because its state (the open chunks) must not
  // survive navigation.
  final _service = TableViewService();

  late final SheetController _controller;
  late final String _tableId;

  /// The table listing, which is the one tracking in-progress imports. The
  /// instance is kept because it must be unsubscribed from in [dispose], and by
  /// then the context is no longer useful for looking it up.
  late final TablesService _tables;

  /// What this table's import was doing the last time it was looked at. It is
  /// to react to it **changing**, not to every notice from the listing.
  TableImportStage? _stage;

  /// What was typed in the header search box. It is the same search box for
  /// the whole home and searches the section being viewed: in this one, over
  /// the rows of the open table.
  ///
  /// The reference is kept for the same reason as the table listing: it must be
  /// unsubscribed from in [dispose], and by then the context is no longer useful
  /// for looking up the service.
  late final ValueListenable<String> _query;

  @override
  void initState() {
    super.initState();

    _tableId = widget.tableId;

    _tables = context.read<TablesService>();
    _stage = _tables.importStage(_tableId);
    _tables.addListener(_onImport);

    _query = context.read<HomeService>().searchQuery;
    _query.addListener(_onSearch);

    _controller = SheetController(
      service: _service,
      metrics: SheetMetrics(
        rowHeight: AppSize.action,
        gutterWidth: AppSize.action
      ),
      widths: SheetWidths(
        defaultWidth: AppSize.action * 3.5,
        minWidth: AppSize.action * 1.5,
        maxWidth: AppSize.action * 16
      ),
      // The controller outlives any `build`, so the context is passed to it as
      // a function and not as a value.
      context: () => context
    );

    // The load is deferred to the first frame so as not to notify while the
    // tree mounts, like the rest of the sections.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _service.open(_tableId, query: _query.value);
    });
  }

  /// This table's import finished uploading its rows: it must be re-read in
  /// full.
  ///
  /// It is the only thing the table service cannot listen to on its own. The
  /// backend notice (`table/ready`) arrives **before** the rows —it says the
  /// columns already have a type, which is exactly what must be known to start
  /// uploading them— so the re-read it triggers finds the table still empty. Who
  /// knows when the rows arrived is the listing, which is the one uploading
  /// them.
  ///
  /// The previous step is checked and not just the current one because `null`
  /// is also what is there when this table was never imported from here, which
  /// is the normal case and has nothing to re-read.
  void _onImport() {
    final stage = _tables.importStage(_tableId);
    if (stage == _stage) return;

    final before = _stage;
    _stage = stage;

    if (before == TableImportStage.loading && stage == null) _service.refresh();
  }

  /// Something was typed (or cleared) in the header search box: the sheet
  /// switches to showing the rows that mention it, or the whole table when
  /// cleared.
  ///
  /// The header already waits until typing stops before announcing, so this runs
  /// per search and not per key, and the service also ignores text equal to what
  /// it already had: returning to the screen or switching business does not
  /// re-request the table for a search that did not change.
  ///
  /// The cursor is taken to the first cell because the rows below are others:
  /// leaving it where it was would leave it over the row that now occupies that
  /// place, which is not the one being viewed.
  void _onSearch() {
    // Leaving the screen clears the search box (the header does it, see
    // [HomeHeader]), and that notice arrives while this is still mounted:
    // without the guard, leaving a table while searching would re-request it in
    // full only to unmount it right after.
    if (!const {"inventory", TableViewSection.routeKey}.contains(Navis.currentKey.value)) return;

    _controller.reset();
    _service.search(_query.value);
  }

  @override
  void dispose() {
    _query.removeListener(_onSearch);
    _tables.removeListener(_onImport);
    _controller.dispose();
    _service.dispose();
    super.dispose();
  }

  // `.value` is used on all of them: the notifiers belong not to the providers
  // but to the controller, which creates and releases them. A provider that
  // released them on its own would kill them on the first rebuild of the screen.
  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider<SheetController>.value(value: _controller),
      Provider<SheetWidths>.value(value: _controller.widths),
      ChangeNotifierProvider<TableViewService>.value(value: _service),
      ChangeNotifierProvider<SheetCursor>.value(value: _controller.cursor),
      ChangeNotifierProvider<SheetColumns>.value(value: _controller.columns),
      ChangeNotifierProvider<SheetDrafts>.value(value: _controller.drafts),
      ChangeNotifierProvider<SheetHover>.value(value: _controller.hover),
      ChangeNotifierProvider<SheetDates>.value(value: _controller.dates)
    ],
    child: Surface(child: Column(children: [
      TableHeader(tableId: _tableId, parts: widget.parts, status: widget.status),
      Separator.horizontal(),
      const Expanded(child: TableViewBody())
    ]))
  );
}
