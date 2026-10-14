# Module: sales section

**Path** `lib/screens/home/sections/sales`
**Role** Live board of every sale in flight (open till ticket, purchase negotiated over a
channel, charged sale not yet delivered) and every finished one. Finished = money arrived
**and** goods left. Content of the `sales` home section.
**Services** `SalesService`, `SalesCatalogService` (`lib/services/sales`) — created and provided
by `_sales.dart`, not app-wide. Contracts and model rules: `lib/services/MODULE.md` → `sales/`.
**Backend** `GET /sales` · `GET /sales/stages` · `GET /sales/detail/:ID` · `PUT /sales/fulfillment` ·
`PUT /chats/stage` · `GET /pos/methods` (channels only) · socket `sale/progress`.

## Routing

- `/home/sales` opens `SalesTab.initial` (`process`). One route per tab from `SalesTab.values`:
  `/home/sales/<key>`, `routeKey = "sales_<key>"`, `parents: ["sales"]`, `shell: Home.shell`.
- `SalesTab.key` **is** the backend's `SECTION` (`process`/`done`) — do not translate between them.
- `_sales.dart` reads the tab inside a `ListenableBuilder` on `Navis.currentKey` + `PermissionsService` (the const-section trap, see home module).
- No `:id`: endpoints answer for the `business_id` header; a business switch remounts the section.

## Invariants

- **Null is not zero**: a conversation has no total, a non-credit ticket owes nothing → dash in the table.
- **Stage words come from the backend**; this module owns only stage → colour (`saleStageColor`,
  off `ChartScheme`, never flag colours). Hue = phase; unknown stage falls back to `level`.
- **Filters travel to the backend.** `STAGE` narrows the page, not the query: a short page is not the end.
- **Search is the exception**: the header's `HomeService.searchQuery` filters rows already read
  (`GET /sales` has no `SEARCH`); the bar says so and a no-match says the sale may be further down.
- `CHANNEL`/`MINE` return tickets only (`SalesService.isTicketsOnly`), and the bar says so.
- **Live updates**: `sale/progress` relabels + floats a held row, drops one that left the
  section/filter; an unknown sale triggers a debounced page-1 reread only while on page 1,
  otherwise it counts in `pending`. `ConnectionService.onRestored` is handled the same way
  (events missed while disconnected are not replayed).
- **Row ≠ sale**: the list carries the scan facts only; products, tax, handover and holds are one
  uncached `GET /sales/detail` per opened panel. Any reference (`SaleModel.id`) opens it; 404 is
  "no longer a sale", shown without retry.
- **Two writes, both confirmed facts nothing can measure**:
  - handover (`PUT /sales/fulfillment`): `MODE`/`STATE`, never a stage; only what changed.
  - approval (`PUT /chats/stage`, `STAGE: sold`): a person confirming payment on a sale at
    `verifying`; addressed by `SaleModel.conversation`, never the row id (a `verifying` row is
    often the till's invoice). No conversation → no button. Also settles the payment marker.
  Everything else is read-only; charging is the POS.
- **Nothing is added up here.** `total` counts the section, unadjusted by stage filter.
- Vocabularies (`SalesCatalogService`) are never hard-coded: new stages/modes must appear without an app release.

## Files

- `_sales.dart` — `SalesSection`: creates/provides both services, `SectionTabs` + the active
  board, keyed by tab (fresh `State` per tab), or `NoPermissionSection` when not granted (see home module).
- `sales_tab.dart` — `enum SalesTab { process, done }`: `key icon section routeKey path area badge`, `initial = process`, `opening`. Route table reads it.
  `badge`: `process` draws `BadgePlace.salesProcess` (backend `sales.new`: the channel sales this person has not opened —
  the rows the table marks); `done` none.
- `sales_board.dart` — `SalesBoard({section})`: bar, table, "load more" (`SectionMoreButton`, no count). Loads on first frame,
  applies header search (code · number · customer · seller), opens `showSaleDetail` and acts on its
  `SaleDetailRequest` (handover form, or approval via `showApprovePayment` + `SalesService.approve`).
  One-minute clock keeps "waiting" fresh.
- `sales_filters/_sales_filters.dart` — `SalesFilters`: one row — count left, controls right; caption
  row for tickets-only and `SalesSearchCaption`.
- `sales_filters/sales_filter_controls.dart` — `SalesFilterControls`: pending movements, state, channel, "sold by
  me", clear, catalog retry (`SectionFilterChip`); right-anchored scroll so narrow windows do not overflow.
- `sales_filters/sales_stage_filter.dart` — `SalesStageFilter`: state dropdown (`SectionMenuChip`) over
  `catalog.of(section)`, each with its dot. `sales_filters/sales_channel_filter.dart` — `SalesChannelFilter`.
- `sales_filters/sales_count.dart` — `SalesCount`; `sales_filters/sales_pending.dart` — `SalesPending` (reload
  for movements the list could not follow); `sales_filters/sales_search_caption.dart` — `SalesSearchCaption`.
- `sales_table.dart` — `SalesTable`: `DataTableView`, ticket · number (the branch's `A-000123`) · customer · state · channel · wait ·
  units · total · outstanding · seller, ticket frozen. Not sortable. Every row opens
  (`onRowTap`); no action column. An `unseen` row: `UnseenMark` before the ticket, ticket and customer bold.
  Opening a row (`SalesBoard._open`) is reviewing it: `SalesService.review`.
- `stage/sale_stage_color.dart` — `saleStageColor`, `saleLevelColor`: the only place a stage becomes a colour.
- `stage/sale_stage_tag.dart` — `SaleStageTag`; `stage/sale_stage_dot.dart` — `SaleStageDot`.
- `sale_format.dart` — `saleAmountLabel` (empty for null), `saleCountLabel`, `saleDateLabel`, `saleWaitLabel` (time at current stage).

Panels (`lib/screens/modals/sales`): `sale_detail`, `sale_items` (stacked on the detail),
`sale_fulfillment`.
