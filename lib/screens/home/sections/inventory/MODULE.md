# Module: inventory section

**Path** `lib/screens/home/sections/inventory`
**Role** Product tables, one open at a time (`/home/inventory`; a table's link
`/home/inventory/:id`, `parents: ["inventory"]`, opens the same section on it). The bar's title is the
table selector; the cells switch shows the open table as its stock summary or as the spreadsheet.
No table → templates by the company's activity, a blank table, the import.
**Services** `TablesService`, `TableViewService`, `TableDetailService`, `StockSummaryService`
(`lib/services/stock`), `StockTransfersService` (transfers page) + `lib/services/inventory` (field types, imports, SKUs, dates, images,
`TableTemplatesService`). `PreferencesService`: the open table per company
(`RememberedSelection.table`) and the view per account (`inventoryView`).
**Modals** `lib/screens/modals/inventory` (`create_table create_field import_table rename_table
edit_table_details table_settings stock_movement`) + `modals/shared` (`image_viewer crop_image`).

## table_list/ — the section

- `_table_list.dart` — `InventorySection`: `catalog` tables only (supplies are the production line's; none of its own → `InventoryStart`); resolves the open table (link → remembered → primary → first), builds the
  bar's parts, mounts `StockSummarySection` or `TableViewSection` keyed by table (a table with no rows: the sheet, no switch); an importing table shows its stage
  instead (`TablesService.importStage`); no table → `InventoryStart`. The bar's right end: table options (⋯), import, create (modal);
  their flows live here.
- `inventory_bar.dart` — `InventoryBar`, `InventoryBarParts`: the section's bar, drawn by each view: selector and controls left, the view's status centred, the view's then the section's actions against the right edge. Every control in it is `AppSize.button` tall (core's `Button` is).
- `table_selector.dart` — `TableSelector` (`showSelectMenu` over the tables); `table_dot.dart` — `TableDot`.
- `view_toggle.dart` — `InventoryViewToggle`: the cells switch (`PreferencesService.inventoryView`; or the opener's `sheet`/`onSwitch`, the supplies tab's).
- `inventory_start.dart` — `InventoryStart`: no table yet; owns `TableTemplatesService` (read only here, where `inventory.templates` is), template cards, blank card, import.
- `widgets/inventory_template_card.dart` — `InventoryTemplateCard`; `widgets/inventory_blank_card.dart` — `InventoryBlankCard`; `widgets/inventory_start_card.dart` — `InventoryStartCard` (their shared frame).
- `table_options.dart` — `TableOptionsButton`: rename / settings / delete of the open table, and the transfers page (with `BadgePlace.inventoryTransfers` on the button) only with several branches and `inventory.transfers`.
- `import_button.dart` — `ImportButton`: opens the import modal; shown where `inventory.import` is (`CapabilityService`).
- `pictures_button.dart` — `PicturesButton`: the imported pictures' state (downloading / without their file / failed), opens `showImportPictures`; in the bar only while something is pending or failed (`PicturesButton.shown`). The section's first frame runs `PictureImportService.check`.
- `stock_summary/_stock_summary.dart` — `StockSummarySection({tableId, parts, supplies})`: owns that table's `StockSummaryService` (a supplies table's moves with decimals), fixed column header over a `ListView`; header search → `MATCH`.
- `stock_summary/summary_bar.dart` — `SummaryBar`; `stock_summary/summary_body.dart` — `SummaryBody` (states, header, list); `stock_summary/summary_footer.dart` — `SummaryFooter`.
- `stock_summary/summary_layout.dart` — `SummaryLayout`: the single source of column geometry (header and rows): short types at their own width (`widthOf`), texts share the rest; measured on the list's width, it leaves out what doesn't fit.
- `stock_summary/summary_product_row.dart` — a price cell opens `showBranchPrices` with several branches and `inventory.prices` (the row itself stays untouched); with `supply_chain.recipes` the photo opens the product's `showRecipePanel`, and a dish made to order's stock is what its supplies allow, no stepper.
- `stock_summary/summary_header.dart` — `SummaryHeader` (a title click orders by its column: `summary_sort_title.dart` — `SummarySortTitle`); `stock_summary/summary_product_row.dart` — `SummaryProductRow`; `stock_summary/summary_line.dart` — `SummaryLine`.
- `stock_summary/summary_stepper.dart` — `SummaryStepper`: take/add; opens `showStockMovement`; the stock figure opens `showStockHistory` (`inventory.history`).
- `stock_summary/summary_value.dart` — `SummaryValue`; `summary_number.dart` — `SummaryNumber`; `summary_picture.dart` — `SummaryPicture`.

## transfers/ — stock between branches (`/home/inventory/transfers`, cloud only)

- `_transfers.dart` — `StockTransfersSection` (`routeKey = "inventory_transfers"`, `path`; a fixed segment before a table's `:id`): owns `StockTransfersService`; back to inventory, "New transfer" (`inventory.transfer` and another branch), `BadgeNotes`, side chips (coming here / sent from here) and a status menu, the list (`SectionMoreButton`); the writes and their confirmations (drop a draft, call a sent one back).
- `transfer_row.dart` — `TransferRow`: the other branch, status tag, first products (names from `nameOf`, else SKU), units (received of sent), date, note; only this branch's step: send/drop a draft, call back a sent one (sender), receive (receiver).

## table_view/ — the spreadsheet

`TableViewSection({tableId, parts})` owns a `SheetController`, which owns all state below. Rendering is split so a
cell rebuild never rebuilds the sheet. Row 1 is the *fields* row (cursor index `-1`); body rows
from 0. The last column is a *free column*: typing a title creates a field.

- `_table_view.dart` — `TableViewSection` (`routeKey`: a table's link, which the shell maps to `InventorySection`); also the supply chain's supplies sheet.
- `table_view_body.dart` — `TableViewBody`: loading / error / the sheet, by the structure's status only.
- `table_header.dart` — `TableHeader`: the section's `InventoryBar` with the import stage, read/save state, normalize.
- `header_actions.dart` — `HeaderActions`: record-load state, search.
- `normalize_button.dart` — `NormalizeButton`: `TableViewService.normalize`; shown where `inventory.import` is.
- `sheet.dart` — `Sheet`: frozen gutter band + data band.
- `sheet_style.dart` — `SheetStyle`: paint data resolved once per sheet; `sheet_theme.dart` — `SheetTheme` (`InheritedWidget`); `sheet_row_fill.dart` — `SheetRowFill`.
- `gutter.dart` — `SheetGutter`: row numbers; `gutter_cell.dart` — `GutterCell`.
- `body.dart` — `SheetBody`: records + blank rows being written.
- `fields_row.dart` / `field_cell.dart` — row 1 and its cells.
- `type_arrow.dart` — `TypeArrow`: field-type menu, changes a column's type.
- `record_row.dart` — `RecordRow`; `cell.dart` — `SheetCellView`.
- `cell_editor.dart` — `CellEditor`: active cell editor (raw `TextField` on purpose: inline grid editor, not a form field).
- `column_drag.dart` — `ColumnDrag`: carried column, drop line; `column_drag_ghost.dart` — `ColumnDragGhost`.
- `cells/_cells.dart` — dispatch by `TableFieldType`; `date_cell` `image_cell` `listed_cell`
  (`OPTIONS`; `CATEGORIES`/`SIZES` are ticked in core's `showCheckMenu`) `price_cell` `sku_cell` `unit_cell` (number + unit/percent).
- `state/sheet_controller.dart` — `SheetController`: hub — `cursor drafts hover dates drag columns`,
  three `ScrollController`s (`vGutter`/`vBody` linked, `horizontal`), grid `FocusNode`, `usedRows`,
  `uploading`, editor, serialized write queues (columns, rows). Its writes are `part`s in `state/controller/`, extensions on it
  (`SheetWidthEdits` `SheetColumnDrag` `SheetRowWrites` `SheetFieldWrites` `SheetOptionPicks` `SheetImagePicks`): import the controller alone.
- `state/sheet_columns.dart` — `SheetColumns`; `state/sheet_column.dart` — `SheetColumn`; `state/sheet_shape.dart` — `SheetShape`.
- `state/sheet_cursor.dart` — `SheetCursor`; `state/sheet_cell.dart` — `SheetCell`, `SheetCellState`, `kFieldsRow`.
- `state/sheet_drafts.dart` — `SheetDrafts`: unsaved rows; `state/sheet_draft.dart` — `SheetDraft`.
- `state/sheet_widths.dart` — `SheetWidths`; `state/sheet_metrics.dart` — `SheetMetrics` (row height, visible range, scroll-to-cell).
- `state/sheet_order.dart` — `fieldsInOrder`, `slotsOf`, `movedOrder`, `dropEdgeAt`.
- `state/sheet_drag.dart` — `SheetDrag`; `state/sheet_hover.dart` — `SheetHover`; `state/sheet_dates.dart` — `SheetDates`.
- `state/sheet_keys.dart` — `SheetKeyIntent`.
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

## Conventions

- Never paint a sheet cell from `ThemeColor` — use `SheetTheme.of(context)`.
- Writes go through `SheetController`'s queues, never from a widget, so edits stay ordered.
- New field type: `TableFieldType` → cell in `cells/` → register in `_cells.dart` → extend
  `table_field_request.dart` if its payload differs.
