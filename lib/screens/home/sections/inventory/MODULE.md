# Module: inventory section

**Path** `lib/screens/home/sections/inventory`
**Role** Product tables. Two screens: the section (`/home/inventory` — table list + stock
summary) and the spreadsheet view of one table (`/home/inventory/:id`, sub-page with
`parents: ["inventory"]`).
**Services** `TablesService`, `TableViewService`, `TableDetailService`,
`StockSummaryService` (`lib/services/stock`), plus `lib/services/inventory` for field
types, imports, SKUs, dates and images.

---

## table_list/ — the section

- `_table_list.dart` — `InventorySection`: the list of tables on top, the stock summary
  below. Uses `BusinessListener`.
- `table_row.dart` — `TableListRow`: phone/narrow form of a table entry. Refuses to open a
  table that is still being imported (`TablesService.importStage`).
- `table_card.dart` — `TableCard`: desktop form, same rule.
- `table_options.dart` — `TableOptionsButton`: per-table menu (rename, settings, delete),
  shared by both forms.
- `primary_mark.dart` — `PrimaryTableMark`: marks the business's primary table.
- `import_button.dart` — `ImportButton`: opens the import modal.
- `sticky_bar.dart` — `StickyBar`: a bar that scrolls differently from the rest.

### table_list/stock_summary/ — bottom half of the section

- `_stock_summary.dart` — `StockSummarySection`.
- `summary_layout.dart` — `SummaryLayout`: how a row's width is split. Single source of
  the column geometry; header and rows both read it.
- `summary_row.dart` — `SummaryHeader`, `SummaryProductRow`, `SummaryLine`.
- `summary_stepper.dart` — `SummaryStepper`: a number with take/add on each side; opens
  `showStockMovement`.
- `summary_value.dart` — `SummaryValue`, `SummaryNumber`, `SummaryPicture`: the cells.

---

## table_view/ — the spreadsheet

`TableViewSection` (`_table_view.dart`) owns a `SheetController`, which owns every piece
of state below. Rendering is split so a cell rebuild never rebuilds the sheet.

**Sheet model**: row 1 is the *fields* row (index `-1` in the cursor); the body is
numbered from 0. The last column is a *free column*: typing a title there creates a
field. Editing is driven by `FieldEdit.of(...)` — the only rule for add/rename/delete.

### Frame
- `_table_view.dart` — `TableViewSection` (`routeKey`, resolves `:id`), `BusinessListener`.
  Turns around on entry when the table is still being imported.
- `table_header.dart` — `TableHeader`: back, table color, name, read/save state.
- `header_actions.dart` — `HeaderActions`: record-load state and search.
- `normalize_button.dart` — `NormalizeButton`: `POST .../builder/normalize/`.
- `sheet.dart` — `Sheet`: frozen gutter band + data band.
- `sheet_style.dart` — `SheetStyle`, `SheetTheme` (`InheritedWidget`), `SheetRowFill`:
  everything cells need to paint, resolved **once** per sheet. Cells read this, never
  `ThemeColor` directly.
- `gutter.dart` — `SheetGutter`, `GutterCell`: frozen left column of row numbers.
- `body.dart` — `SheetBody`: records plus the blank rows being written.
- `fields_row.dart` / `field_cell.dart` — row 1 and its cells.
- `type_arrow.dart` — `TypeArrow`: unfolds the field types and changes a column's type.
- `record_row.dart` — `RecordRow`; `cell.dart` — `SheetCellView`.
- `cell_editor.dart` — `CellEditor`: the active cell's editor (raw `TextField` on purpose,
  it is an inline grid editor, not a form field).
- `column_drag.dart` — `ColumnDrag`: the carried column, its ghost and the drop line.

### cells/ — read-only renderings by field type
- `_cells.dart` — dispatch by `TableFieldType`.
- `date_cell.dart` `image_cell.dart` `listed_cell.dart` (`OPTIONS`/`CATEGORIES`)
  `price_cell.dart` `sku_cell.dart` `unit_cell.dart` (number + unit/percent).

### state/ — all `ChangeNotifier`s or plain value holders
- `sheet_controller.dart` — `SheetController`: the hub. Holds `cursor drafts hover dates
  drag columns`, the three `ScrollController`s (`vGutter`/`vBody` linked, `horizontal`),
  the grid `FocusNode`, `usedRows`, `uploading`, the editor, and the serialized write
  queues for columns and rows.
- `sheet_columns.dart` — `SheetColumns`, `SheetColumn`, `SheetShape`: how many columns,
  which one is where, where its content comes from.
- `sheet_cursor.dart` — `SheetCursor`, `SheetCell`, `SheetCellState`: the active cell.
- `sheet_drafts.dart` — `SheetDrafts`, `SheetDraft`: written but unsaved rows.
- `sheet_widths.dart` — `SheetWidths`; `sheet_metrics.dart` — `SheetMetrics` (row height,
  visible range, scroll-to-cell).
- `sheet_order.dart` — column order arithmetic: `fieldsInOrder`, `slotsOf`, `movedOrder`,
  `dropEdgeAt`.
- `sheet_drag.dart` — `SheetDrag`; `sheet_hover.dart` — `SheetHover`;
  `sheet_dates.dart` — `SheetDates` (which date columns are expanded).
- `sheet_keys.dart` — `SheetKeyIntent`: what a keystroke asks of the sheet.
- `free_column.dart` — `FreeColumn`: the trailing empty column being named.
- `field_edit.dart` — `FieldEdit.of({isField, current, text})` → `create | rename |
  delete | none`. **The whole column-editing rule.** Covered by `test/field_edit_test.dart`.

---

## Related modals (`lib/screens/modals/inventory`)

`create_table`, `create_field`, `import_table`, `rename_table`, `edit_table_details`,
`table_settings`, `stock_movement`, plus `modals/shared`: `image_viewer`, `crop_image`.

## Import

An imported table exists long before it is finished. `POST /import/structure/<format>/`
returns its id at once (every column `text`, no rows) and the backend prepares it behind
the response, bracketed by two socket events — `table/normalizing` then `table/ready`
(~30 s). `TablesService` listens to both, so a table imported from **any** device is in
the list, marked, from the moment it exists. Only after `table/ready` are the rows
uploaded (`POST /import/records/<format>/`).

**A table with an `importStage` does not open.** Its columns are untyped and its rows are
not in, and a sheet in that state reads as a failed import — which people answer by
importing the file again. The list says what is missing instead; the sub-page turns
around on entry for the links that skip the list.

## Conventions

- Never paint a sheet cell from `ThemeColor` — go through `SheetTheme.of(context)`.
- Writes go through `SheetController`'s queues, never straight from a widget, so
  concurrent edits stay ordered.
- New field type: add to `TableFieldType`, add a cell in `cells/`, register it in
  `_cells.dart`, and extend `table_field_request.dart` if it needs a distinct payload.
