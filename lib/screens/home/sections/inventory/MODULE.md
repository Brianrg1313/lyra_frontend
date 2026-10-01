# Module: inventory section

**Path** `lib/screens/home/sections/inventory`
**Role** Product tables. Two screens: the section (`/home/inventory` — table list + stock
summary) and one table's spreadsheet (`/home/inventory/:id`, `parents: ["inventory"]`).
**Services** `TablesService`, `TableViewService`, `TableDetailService`, `StockSummaryService`
(`lib/services/stock`) + `lib/services/inventory` (field types, imports, SKUs, dates, images).
**Modals** `lib/screens/modals/inventory` (`create_table create_field import_table rename_table
edit_table_details table_settings stock_movement`) + `modals/shared` (`image_viewer crop_image`).

## table_list/ — the section

- `_table_list.dart` — `InventorySection`: tables on top, stock summary below. `BusinessListener`.
- `table_row.dart` — `TableListRow`: narrow form. Refuses to open an importing table (`TablesService.importStage`).
- `table_card.dart` — `TableCard`: desktop form, same rule.
- `table_options.dart` — `TableOptionsButton`: rename / settings / delete, both forms.
- `primary_mark.dart` — `PrimaryTableMark`: the business's primary table.
- `import_button.dart` — `ImportButton`: opens the import modal; shown where `inventory.import` is (`CapabilityService`).
- `sticky_bar.dart` — `StickyBar`: bar with its own scroll behaviour.
- `stock_summary/_stock_summary.dart` — `StockSummarySection`.
- `stock_summary/summary_layout.dart` — `SummaryLayout`: the single source of column geometry (header and rows).
- `stock_summary/summary_row.dart` — `SummaryHeader`, `SummaryProductRow`, `SummaryLine`.
- `stock_summary/summary_stepper.dart` — `SummaryStepper`: take/add; opens `showStockMovement`.
- `stock_summary/summary_value.dart` — `SummaryValue`, `SummaryNumber`, `SummaryPicture`.

## table_view/ — the spreadsheet

`TableViewSection` owns a `SheetController`, which owns all state below. Rendering is split so a
cell rebuild never rebuilds the sheet. Row 1 is the *fields* row (cursor index `-1`); body rows
from 0. The last column is a *free column*: typing a title creates a field.

- `_table_view.dart` — `TableViewSection` (`routeKey`, resolves `:id`), `BusinessListener`; turns back if the table is still importing.
- `table_header.dart` — `TableHeader`: back, colour, name, read/save state.
- `header_actions.dart` — `HeaderActions`: record-load state, search.
- `normalize_button.dart` — `NormalizeButton`: `TableViewService.normalize`; shown where `inventory.import` is.
- `sheet.dart` — `Sheet`: frozen gutter band + data band.
- `sheet_style.dart` — `SheetStyle`, `SheetTheme` (`InheritedWidget`), `SheetRowFill`: paint data resolved once per sheet.
- `gutter.dart` — `SheetGutter`, `GutterCell`: row numbers.
- `body.dart` — `SheetBody`: records + blank rows being written.
- `fields_row.dart` / `field_cell.dart` — row 1 and its cells.
- `type_arrow.dart` — `TypeArrow`: field-type menu, changes a column's type.
- `record_row.dart` — `RecordRow`; `cell.dart` — `SheetCellView`.
- `cell_editor.dart` — `CellEditor`: active cell editor (raw `TextField` on purpose: inline grid editor, not a form field).
- `column_drag.dart` — `ColumnDrag`: carried column, ghost, drop line.
- `cells/_cells.dart` — dispatch by `TableFieldType`; `date_cell` `image_cell` `listed_cell`
  (`OPTIONS`/`CATEGORIES`) `price_cell` `sku_cell` `unit_cell` (number + unit/percent).
- `state/sheet_controller.dart` — `SheetController`: hub — `cursor drafts hover dates drag columns`,
  three `ScrollController`s (`vGutter`/`vBody` linked, `horizontal`), grid `FocusNode`, `usedRows`,
  `uploading`, editor, serialized write queues (columns, rows).
- `state/sheet_columns.dart` — `SheetColumns`, `SheetColumn`, `SheetShape`.
- `state/sheet_cursor.dart` — `SheetCursor`, `SheetCell`, `SheetCellState`.
- `state/sheet_drafts.dart` — `SheetDrafts`, `SheetDraft`: unsaved rows.
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

## Conventions

- Never paint a sheet cell from `ThemeColor` — use `SheetTheme.of(context)`.
- Writes go through `SheetController`'s queues, never from a widget, so edits stay ordered.
- New field type: `TableFieldType` → cell in `cells/` → register in `_cells.dart` → extend
  `table_field_request.dart` if its payload differs.
