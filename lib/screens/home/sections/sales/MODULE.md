# Module: sales section

**Path** `lib/screens/home/sections/sales`
**Role** **What the company is selling right now.** One list of every sale in flight —
a ticket a till has open, a purchase the assistant is negotiating over a channel, a
charged sale that has not reached the customer — split in two by the one rule that
decides it: a sale is finished when the money arrived **and** the goods left. Content of
the `sales` home section.
**Services** `lib/services/sales` — `SalesService`, `SalesCatalogService`. Both are
created by `_sales.dart` and provided from there; neither is app-wide.
**Backend** `GET /sales` · `GET /sales/stages` · `GET /sales/detail/:ID` · `PUT /sales/fulfillment` ·
`PUT /chats/stage` (approving a payment) · `GET /pos/methods` (channels only) ·
socket `sale/progress`.

## Routing

- The section is `/home/sales`, which opens `SalesTab.initial` (`process`).
- One route per tab, generated from `SalesTab.values`: `/home/sales/<key>`,
  `routeKey = "sales_<key>"`. Both declare `parents: ["sales"]` and `shell: Home.shell`.
- Separate routes per tab (not a `:tab` arg) because the shell learns of a screen change
  through `Navis.currentKey`.
- `SalesTab.key` **is** the backend's `SECTION` value (`process` / `done`). The two are
  the same word on purpose; translating one into the other is how they drift apart.
- `_sales.dart` reads the open tab **inside a `ValueListenableBuilder` on
  `Navis.currentKey`**, not from its own `build` — the shell mounts the section as a
  `const` widget and a canonicalized `const` is skipped by `Element.updateChild` on
  identity. Same trap the money page was written around.
- **No `:id`**: every sales endpoint answers for the `business_id` header. Changing
  business remounts the whole section (the shell keys its content by business).

## Key invariants

- **Nothing here is a stored list.** Every row is measured on read from the collection
  that owns it — the invoice's status, the conversation's cart, the ticket's `collected`
  counter — so a row changes because the thing behind it changed. The one exception is
  the handover, because no collection can see a van leaving.
- **Null is not zero.** A conversation has no total; a non-credit ticket owes nothing.
  Both are `null` on the model and a dash in the table (`SalesTable._none`).
- **The stage words come from the backend** (`model:/sales/progress.js`) and are shown as
  received, like a provider's name. What this module owns is the map from a `stage` to a
  colour of this theme (`saleStageColor`), off `ChartScheme` and never off the flag
  colours — `snackBar.alert` and `snackBar.notification` are both black. A hue is a
  *phase* (forming · money ours · money theirs · goods here · goods moving · debt · done),
  so two stages of one phase share it; an unknown stage falls back to its `level`.
- **Every filter travels to the backend.** A stage is measured, so `STAGE` narrows the
  *page* and not the query: a short page is not the end of the list, which is why
  `SalesService.hasMore` counts against `total` and not against rows read.
- **The search is the exception, and the bar says so.** The home's one search box
  (`HomeService.searchQuery`) narrows the board by ticket code, customer and seller —
  `GET /sales` takes no `SEARCH`, so it filters the rows already read and never the query.
  A caption is drawn while it is on, and a query that matches nothing says the sale may be
  further down: a board that filtered silently would answer "no such sale" for a sale that
  is only on the next page.
- `CHANNEL` and `MINE` are questions about tickets, so a request carrying either answers
  with tickets alone. `SalesService.isTicketsOnly` is that fact and the bar says it.
- **`sale/progress` is what makes this a board.** A row already held is relabelled in
  place and moved to the top; one that left the section (or the stage filter, or both
  lists) is dropped; a sale not held cannot be drawn from a notice, so the first page is
  reread — debounced, and only while the list is *on* page 1. Past it the list is
  somebody's scroll and the movements are announced (`pending`) instead.
- **A connection that comes back is a reread.** Events are fire and forget on the other
  side: what moved while this app was not in the room was emitted to nobody and is not
  queued anywhere, so a phone that slept, a wifi that changed or a server that restarted
  all end with a board drawing what was true before the drop and nothing on it saying so.
  `ConnectionService.onRestored` is the notice for that —fired on a reconnection and never
  on the first connection of the run, which has missed nothing— and the board answers it
  the same two ways it answers a movement it does not hold: a silent reread on page 1,
  `pending` past it.
- **The notice is shaped like the row**, column for column and `label` included — it is
  merged into a row already on screen, so a key the list does not use relabels nothing and
  leaves the state saying what the sale used to be. It carried `name` once, which is the
  *customer's* name one list over.
- **A row is not the sale.** The list carries the ten facts a board is scanned by and
  deliberately not the products, the tax breakdown, the handover or the holds — fifty sales
  with every line of every one of them is a payload nobody reads. Those are one read per
  opened sale (`GET /sales/detail/:ID`, `SaleDetailService`), never cached: a sale is
  measured on every read, so a detail kept between two openings is a sale as it was.
- **One reference opens all three sources.** The detail endpoint resolves a ticket code, a
  row id and a chat id to the same sale — and a conversation since rung up to its ticket —
  so the panel asks with `SaleModel.id` whatever kind of row it holds. A screen that had to
  work out which of the three it was before it could open it is a screen that reimplements
  `model:/sales/pipeline.js`.
- **A row that cannot be opened is news, not a failure.** The endpoint answers 404 both for
  a reference that names nothing and for a conversation that stopped being a sale (the units
  went back, the customer only asked a question). The panel says so and offers no retry;
  everything else is an error that does.
- **The handover write sends the difference.** Naming a mode moves the sale to that mode's
  *opening* state, so re-sending the mode a delivery already has walks a dispatched order
  back to "sin despachar".
- **A payment is approved by a person, and `verifying` is the only place they can be.**
  Nothing in this platform sees a bank: the transfer happened elsewhere and el comprobante
  is a photo in a conversation, which is why the detail panel draws it directly under the
  card that carries the button. Approving is a mark on the conversation (`sold`) and it
  settles the money marker with it — one statement about the sale and about the queue it
  was sitting in.
- **The approval is addressed by the conversation and the row is not it.** Every sale gets
  a ticket now, so a purchase arranged over a channel is a row whose id names the
  register's invoice while the stage it is drawn at is the conversation's — `verifying` is
  therefore an `invoice` row as often as a `chat` one. `PUT /chats/stage` reads a chat, so
  the write goes to `SaleModel.conversation` (`chat`) and the row's id is only what the
  board takes it off the list by. A row at `verifying` with no conversation on it —a deal
  whose chat session expired, whose id fell back to the contact— is offered no button:
  there is nothing to address the write with.

## Files

- `_sales.dart` — `SalesSection`: creates and provides the two services, hosts the tab bar
  and the active tab's board. Reads the open tab from `Navis.currentKey`; the board is
  keyed by tab so switching lists gives it a fresh `State`.
- `sales_tab.dart` — `enum SalesTab { process, done }` with `key`, `icon`, `section`,
  `routeKey`, `path`, `initial = process`. The route table reads this list.
- `sales_board.dart` — `SalesBoard({section})`: the body of a tab — bar, table,
  "load more". Asks `SalesService.open(section)` and `SalesCatalogService.load()` on the
  first frame, filters the rows by the header's search (ticket · customer · seller), owns
  the opening of one sale (`showSaleDetail`) and the two flows that panel asks for — the
  handover form and the approval (confirmed with `showAlertModal`, then
  `SalesService.approve`) — and **keeps a one-minute clock** so the "waiting" column does
  not go stale by being looked at. It has no head of its own: the count lives in the bar.
- `sales_filters.dart` — `SalesFilters`: **the bar above the board, one row** — the
  section's count on the left, every control on the right, and the tickets-only caption
  under it. The controls are the state (a dropdown over `showSelectMenu`, options
  `catalog.of(section)`, each with its stage dot and the chosen one's dot on the closed
  chip), the channel, "sold by me", clear, the pending-movements button and a retry chip
  when the catalog failed. The states **were** a strip of chips, one per stage: a dozen
  words cost the board a line and a half plus a horizontal scroll to reach the last one.
  The two halves both flex and the controls take four fifths — the count is one short
  sentence and the labels are the backend's — and the strip is anchored at its right edge
  (`reverse`), so a narrow window scrolls it leftwards instead of overflowing the row.
  Under the row it also carries `_SearchCaption`, drawn only while the header's search has
  something in it: that search narrows the rows already read and not the query, and the bar
  is where this screen says what it is showing.
- `sales_table.dart` — `SalesTable`: `DataTableView`, columns in reading order (ticket ·
  customer · state · channel · wait · units · total · outstanding · seller), the ticket
  frozen left. Not sortable (one page of a filter, ordered by last movement). **Every row
  opens** (`onRowTap` → `onOpen`) and says so with the pointer — core draws the click
  cursor on any table that takes an `onRowTap`. **There is no action column**: it carried
  the handover icon behind a frozen divider of its own and was empty on every row with
  nothing to hand over, which is most of them. The handover is asked for from the panel
  the row opens.
- `stage_tag.dart` — `SaleStageTag` (tinted pill: dot + label, both in the stage's colour)
  and `SaleStageDot`, plus `saleStageColor(context, stage, level)` and its
  `saleLevelColor(context, level)` fallback: the one place a backend stage becomes a
  theme colour.
- `sale_format.dart` — `saleAmountLabel(value, currency)` (empty for null, never `0`),
  `saleCountLabel`, `saleDateLabel`, `saleWaitLabel(context, since)` — **how long this
  sale has been standing where it is**, which is the figure the board is read by.

The tab bar is `SectionTabs` (`lib/screens/home/sections/section_tabs.dart`), shared with
the business and money pages. The side panels live in `lib/screens/modals/sales`:
`sale_fulfillment` (the handover), `sale_detail` (the sale opened in full) and `sale_items`
(its lines, opened **on top of** the detail — a ticket of three hundred of them is not a
block of a panel that is read top to bottom). The detail
panel writes nothing: it answers `true` when the handover was asked for on it, and the
board is what opens the form and makes the write.

## Conventions

- **Two writes, and both say a thing no collection can measure.**
  - The handover (`PUT /sales/fulfillment`) sets a *fact* (`MODE`, `STATE`) and never a
    stage: the stage that follows is computed on the other side and handed back.
  - The approval (`PUT /chats/stage`, `STAGE: sold`) is a person saying the money arrived
    on a sale standing at `verifying`. Nothing here can see a bank — the transfer happened
    somewhere else and the comprobante is a photo in a conversation — so it is a statement
    and it is confirmed before it travels. It is a mark on the **conversation** and not a
    sales endpoint because that is where the payment marker it also settles lives; closing
    the sale and clearing the money queue is one statement, and splitting it in two leaves
    a sale closed with the payment still waiting for somebody to verify. It travels with
    the **conversation's** id (`SaleModel.conversation`) and never the row's, which is a
    document id on every row that is not a deal.

  Everything else on this screen is read-only: charging a ticket is still the counter.
- **Nothing is added up here.** Every figure is the backend's answer; `total` counts the
  *section* and is not adjusted for a stage filter, because the backend does not adjust it
  either.
- New sales endpoint: model + service in `lib/services/sales`, and the board reads it. The
  vocabularies (`SalesCatalogService`) are never hard-coded here — a stage or a handover
  mode added on the backend must show up without a new version of the app.
