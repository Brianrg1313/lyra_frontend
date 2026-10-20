# Module: inventory section

**Path** `lib/screens/home/sections/inventory`
**Role** `catalog` and `supplies` tables (`cocina-frontend.md` §2: the kind asked when one is created, never
changed), one open at a time (`/home/inventory`; a table's link `/home/inventory/:id`, `parents: ["inventory"]`,
opens the same section on it), and the company's modifier groups (`/home/inventory/modifiers`, cloud only). The
bar's title is the table selector; the cells switch shows the open table as its stock summary (a supplies table's
own list) or as the spreadsheet. `made` tables are the menu's (`sections/menu`). Neither catalog nor supplies →
templates by the company's activity, a blank table, the import.
**Services** `TablesService`, `TableViewService`, `TableDetailService`, `StockSummaryService`
(`lib/services/stock`), `StockTransfersService` (transfers page) + `lib/services/inventory` (field types, imports, SKUs, dates, images,
`TableTemplatesService`). `PreferencesService`: the open table per company
(`RememberedSelection.table`) and the view per account (`inventoryView`).
**Modals** `lib/screens/modals/inventory` (`create_table create_field import_table rename_table
edit_table_details table_settings stock_movement`) + `modals/kitchen` (a supply's panel, a modifier group) +
`modals/shared` (`image_viewer crop_image`).

## The section

- `_inventory.dart` — `InventorySection`: owns `ModifiersService`; `SectionTabs` over `InventoryTab.shown` (none drawn
  with one tab: a master) and the open tab from `Navis.currentKey`: the tables (`InventoryTables`) or, in a `Surface`,
  `ModifiersTab` (`UnavailableSection` / `NoPermissionSection` otherwise).
- `inventory_tab.dart` — `enum InventoryTab { tables, modifiers }`: `routeKey` (tables = the section's, `inventory_<key>`
  else), `path`, `area` (`inventory`, `inventory.<key>`), `shown`, `of(currentKey)` (a table's link is the tables),
  `granted`, `title`. Routes for every tab but the tables in `routes.dart`, before a table's `:id`.
- `kitchen_format.dart` — `kitchenQty` (≤ 6 decimals, unit), `kitchenMoney` (company currency), `kitchenPercent`,
  `kitchenDay`, `kitchenParse`, `kitchenField`, `kitchenFew` (the traffic light's «few», shared with the menu cards).
  **Every kitchen figure (supplies list, menu cards, kitchen panels) goes through it.**

## modifiers/ — the modifiers tab (`inventory.modifiers`, cloud only)

- `_modifiers.dart` — `ModifiersTab`: groups in order, create (`inventory.modifiers.edit`), a row opens `showModifierGroupForm` and writes its draft.
- `modifier_row.dart` — `ModifierRow` (options as chips, «+N more»; products offering it at the right), `modifierRule` («Choose one», «Up to 3»).

## table_list/ — the section

- `_table_list.dart` — `InventoryTables`: `catalog` then `supplies` tables (neither → `InventoryStart`); create asks the kind (`CreateTableModal()`); a supplies table's summary is `SuppliesSection`, its sheet `TableViewSection(supplies: true)`; resolves the open table (link → remembered → primary → first), builds the
  bar's parts, mounts `StockSummarySection` or `TableViewSection` keyed by table (a table with no rows: the sheet, no switch); an importing table shows its stage
  instead (`TablesService.importStage`); no table → `InventoryStart`. The bar's right end: table options (⋯), import, create (modal);
  their flows live here.
- `inventory_bar.dart` — `InventoryBar`, `InventoryBarParts`: the section's bar, drawn by each view: selector and controls left, the view's status centred, the view's then the section's actions against the right edge. Every control in it is `AppSize.button` tall (core's `Button` is).
- `table_selector.dart` — `TableSelector` (`showSelectMenu` over the tables it is given; also the menu's): where kinds mix, each row's subtitle starts with its kind; `table_dot.dart` — `TableDot`.
- `view_toggle.dart` — `InventoryViewToggle`: the cells switch (`PreferencesService.inventoryView`), the same for catalogs and supplies.
- `supplies/_supplies.dart` — `SuppliesSection({table, parts, service?})`: owns that table's `KitchenProductsService` (measured only with
  `inventory.recipes`), the bar with its count, header search → `MATCH`, `RecipeRow`s (a row opens `showRecipePanel` with
  `inventory.recipes`, then remeasures it), `SectionMoreButton`; nothing listed → «Open the sheet» (the cells switch's preference).
- `supplies/recipe_row.dart` — `RecipeRow` (traffic-light strip, name, mode tag, 86 tag, what it makes now; a bought supply's stock at the right, between the summary's − and + — `SummaryStepper` through `KitchenProductsService`), `recipeAvailabilityLine` («3 left — because of the bacon»), `recipeLevelColor`, `RecipeTag`.
- `inventory_start.dart` — `InventoryStart`: no table yet; owns `TableTemplatesService` (read only here, where `inventory.templates` is), template cards, blank card, import.
- `widgets/inventory_template_card.dart` — `InventoryTemplateCard`; `widgets/inventory_blank_card.dart` — `InventoryBlankCard`; `widgets/inventory_start_card.dart` — `InventoryStartCard` (their shared frame).
- `table_options.dart` — `TableOptionsButton`: rename / settings / delete of the open table, and the transfers page (with `BadgePlace.inventoryTransfers` on the button) only with several branches, `inventory.transfers` and `transfers` (the menu passes `false`).
- `import_button.dart` — `ImportButton`: opens the import modal; shown where `inventory.import` is (`CapabilityService`).
- `pictures_button.dart` — `PicturesButton`: the imported pictures' state (downloading / without their file / failed), opens `showImportPictures`; in the bar only while something is pending or failed (`PicturesButton.shown`). The section's first frame runs `PictureImportService.check`.
- `stock_summary/_stock_summary.dart` — `StockSummarySection({tableId, parts, supplies, made})`: owns that table's `StockSummaryService` (a supplies table's moves with decimals; a made one's rows measured), fixed column header over the rows (`SliverFixedExtentList` at `SummaryLayout.rowHeight`, the footer after them); header search → `MATCH`.
- `stock_summary/summary_bar.dart` — `SummaryBar`; `stock_summary/summary_body.dart` — `SummaryBody` (states, header, list); `stock_summary/summary_footer.dart` — `SummaryFooter`.
- `stock_summary/summary_layout.dart` — `SummaryLayout`: the single source of column geometry (header and rows): short types at their own width (`widthOf`), texts share the rest; measured on the list's width, it leaves out what doesn't fit.
- `stock_summary/summary_product_row.dart` — a price cell opens `showBranchPrices` with several branches and `inventory.prices` (the row itself stays untouched); on a made table (with `inventory.recipes`) the photo opens what the record consumes (`showRecipePanel`), and one made to order's stock is what its supplies allow, no stepper; a catalog row opens no recipe.
- `stock_summary/summary_header.dart` — `SummaryHeader` (the stock titled with its column's unit, «Stock (kg)»; a title click orders by its column: `summary_sort_title.dart` — `SummarySortTitle`); `stock_summary/summary_product_row.dart` — `SummaryProductRow`; `stock_summary/summary_line.dart` — `SummaryLine`.
- `stock_summary/summary_stepper.dart` — `SummaryStepper`: take/add; opens `showStockMovement` (through `mover`, else the `StockSummaryService`; the supplies list's rows too); the stock figure opens `showStockHistory` (`inventory.history`), with the product's own `unit` attached.
- `stock_summary/summary_value.dart` — `SummaryValue`; `summary_number.dart` — `SummaryNumber`; `summary_picture.dart` — `SummaryPicture`.

## transfers/ — stock between branches (`/home/inventory/transfers`, cloud only)

- `_transfers.dart` — `StockTransfersSection` (`routeKey = "inventory_transfers"`, `path`; a fixed segment before a table's `:id`): owns `StockTransfersService`; back to inventory, "New transfer" (`inventory.transfer` and another branch), `BadgeNotes`, side chips (coming here / sent from here) and a status menu, the list (`SectionMoreButton`); the writes and their confirmations (drop a draft, call a sent one back).
- `transfer_row.dart` — `TransferRow`: the other branch, status tag, first products (names from `nameOf`, else SKU), units (received of sent), date, note; only this branch's step: send/drop a draft, call back a sent one (sender), receive (receiver).

## table_view/ — the spreadsheet

`TableViewSection({tableId, parts})` owns a `SheetController`, which owns all state below. Rendering is split so a
cell rebuild never rebuilds the sheet. Built in both directions only where seen: rows by the body's `itemExtent`,
columns by `SheetWindow` (each row builds the band's columns plus one each side, a blank for the ones to their left). Row 1 is the *fields* row (cursor index `-1`); body rows
from 0. The last column is a *free column*: typing a title creates a field.

- `_table_view.dart` — `TableViewSection({supplies})` (`routeKey`: a table's link, which the shell maps to `InventorySection`); `supplies`: a supplies table's sheet (stock with decimals).
- `table_view_body.dart` — `TableViewBody`: loading / error / the sheet, by the structure's status only.
- `table_header.dart` — `TableHeader`: the section's `InventoryBar` with the import stage, read/save state, normalize.
- `header_actions.dart` — `HeaderActions`: record-load state, search.
- `normalize_button.dart` — `NormalizeButton`: `TableViewService.normalize`; shown where `inventory.import` is.
- `sheet.dart` — `Sheet`: frozen gutter band + data band.
- `sheet_style.dart` — `SheetStyle`: paint data resolved once per sheet; `sheet_theme.dart` — `SheetTheme` (`InheritedWidget`); `sheet_row_fill.dart` — `SheetRowFill`.
- `gutter.dart` — `SheetGutter`: row numbers, as wide as the last one needs (`SheetStyle.gutterFor`, `SheetController.digits`); `gutter_cell.dart` — `GutterCell`.
- `body.dart` — `SheetBody`: records + blank rows being written.
- `fields_row.dart` / `field_cell.dart` — row 1 and its cells.
- `type_arrow.dart` — `TypeArrow`: field-type menu, changes a column's type.
- `date_menu.dart` — `showDateMenu`, `DateMenuPick`: a date cell's calendar anchored to its button (the cell itself is written) (Flutter's `CalendarDatePicker`, core has none), the column's written/full switch and clear in its head.
- `record_row.dart` — `RecordRow` (the window's cells, kept while its record and draft are the same), `RowBand` (the row's background: zebra, hover, cursor row); `cell.dart` — `SheetCellView` (its border and the range's fill over the band).
- `cell_editor.dart` — `CellEditor`: active cell editor (raw `TextField` on purpose: inline grid editor, not a form field).
- `column_drag.dart` — `ColumnDrag`: carried column, drop line; `column_drag_ghost.dart` — `ColumnDragGhost`.
- `cells/_cells.dart` — dispatch by `TableFieldType`; `boolean_cell` (switch, a tap flips it) `date_cell` `image_cell` `listed_cell`
  (`OPTIONS`; `CATEGORIES`/`SIZES` are ticked in core's `showCheckMenu`) `price_cell` `sku_cell` `unit_cell` (number + its unit/percent attached, `30l`; a measure or stock without one counts units, `5u`; its ruler button changes a measure's column unit, a record's stock its product's own (`inventory.units`, else the column's) and the field row's stock the column's default, asking `askUnitChange` (convert or keep) when the figures can follow and a stock asking first otherwise while it has figures; a record's stock has the summary's − and + at its edges, the ruler after the +, its figure centered).
- `state/sheet_controller.dart` — `SheetController`: hub — `cursor drafts hover dates drag columns selection history window`,
  three `ScrollController`s (`vGutter`/`vBody` linked, `horizontal`; a leap of several screens reads rows only once the band settles), grid `FocusNode`, `usedRows`, `digits`,
  `uploading`, editor, serialized write queues (columns, rows), the table's `kind`. Its writes are `part`s in `state/controller/`, extensions on it
  (`SheetWidthEdits` `SheetColumnDrag` `SheetRowWrites` `SheetFieldWrites` `SheetOptionPicks` `SheetImagePicks` `SheetStockMoves`
  `SheetCellPicks`: a yes/no flipped, a date's calendar from its button, a measure column's unit, picked or typed after a number on leaving the cell;
  `SheetUndo`: Ctrl+Z / Ctrl+Y over a record's corrections; `SheetRanges`: the range stretched by Shift+click / Shift+arrows and the cells' menu on right click): import the controller alone. A record's `STOCK` cell is typed like any cell and leaving it sends a stock correction (`correctStock` → `TableStockMover.correct`); its − and + open `showStockMovement` (`stock`: `TableStockMover`).
- `state/sheet_columns.dart` — `SheetColumns`; `state/sheet_column.dart` — `SheetColumn`; `state/sheet_shape.dart` — `SheetShape`.
- `state/sheet_cursor.dart` — `SheetCursor`; `state/sheet_cell.dart` — `SheetCell`, `SheetCellState`, `kFieldsRow`.
- `state/sheet_drafts.dart` — `SheetDrafts`: unsaved rows; `state/sheet_draft.dart` — `SheetDraft`.
- `state/sheet_widths.dart` — `SheetWidths` (a never-sized yes / no opens at `compactWidth`); `state/sheet_metrics.dart` — `SheetMetrics` (row height, visible range, scroll-to-cell).
- `state/sheet_order.dart` — `fieldsInOrder`, `slotsOf`, `movedOrder`, `dropEdgeAt`.
- `state/sheet_drag.dart` — `SheetDrag`; `state/sheet_hover.dart` — `SheetHover`; `state/sheet_dates.dart` — `SheetDates`.
- `state/sheet_keys.dart` — `SheetKeyIntent` (cursor moves), `SheetCommand` (undo, redo, stretch the range).
- `state/sheet_history.dart` — `SheetHistory`, `SheetChange`: undo/redo steps as closures; `group` makes one step of several writes.
- `state/sheet_selection.dart` — `SheetSelection`, `SheetRange`: the cells selected together beyond the cursor's (body rows only).
- `state/sheet_window.dart` — `SheetWindow`, `SheetSpan`: the columns the rows build (the horizontal band's, the dragged one's and the typed one's kept).
- `state/sheet_actions.dart` — `SheetAction`, `SheetTarget`, `sheetActions`: **the cells' menu**, general actions (no `types`) then a type's (offered when every column of the target is one of its `types`); a new action is one entry here.
- `state/free_column.dart` — `FreeColumn`: trailing column being named.
- `state/field_edit.dart` — `FieldEdit.of({isField, current, text})` → `create | rename | delete | none`: **the whole column-editing rule**.

## Import

`POST /import/structure/<format>/` returns the id at once (all columns `text`, no rows); the
backend prepares it between `table/normalizing` and `table/ready` (~30 s), which
`TablesService` listens to (imports from any device show up). Rows upload after `table/ready`
(`POST /import/records/<format>/`). **A table with an `importStage` does not open** (it would
look like a failed import and get re-imported).

The pictures an image column names become files behind the import (backend `Ingest`); this device's
part is `PictureImportService` (`lib/services/MODULE.md`): it downloads what the cloud was refused with
nobody asking, and the panel (`modals/inventory/import_pictures`) hands over the named files from a folder or a zip.
A name still waiting draws as a plain picture glyph in its cell (`ProductImage.isPending`).

## Kitchen invariants

- A table is listed in one section only (`cocina-frontend.md` §2): `catalog` and `supplies` here, `made` in the menu.
  What a made product consumes is written in its form in the menu; here a supply's recipe is a preparation (by the batch).
- The backend lists no recipes: a supplies list asks `POST /recipes/availability` over each page's ids, and an answer is
  what marks a product as having one (absent = no recipe).
- `stock/changed` with `composite: true` moves only a dish's `available`, never a shelf (`StockChangedModel.composite`).

## Conventions

- Never paint a sheet cell from `ThemeColor` — use `SheetTheme.of(context)`.
- A row's background is `RowBand`'s, never a cell's: a cell paints `SheetStyle.line` over it. A new per-row look goes in the band, so hovering never rebuilds cells.
- Writes go through `SheetController`'s queues, never from a widget, so edits stay ordered.
- A record's cell correction goes through `finishRecord`, which remembers it for Ctrl+Z; an action writing several cells calls it inside `history.group`, with each cell's `before`.
- New field type: `TableFieldType` → cell in `cells/` → register in `_cells.dart` → extend
  `table_field_request.dart` if its payload differs.
