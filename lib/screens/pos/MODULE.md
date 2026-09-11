# Module: pos

**Path** `lib/screens/pos`
**Role** Point-of-sale mode: the counter where in-person sales happen.
**Services** `PosService` (`lib/services/pos`, `/pos/`), `PosCatalogService`
(`POST /pos/catalog/`), `PosInvoiceService` (the ticket, `/pos/invoices/…`) and
`PosMethodsService` (`GET /pos/methods`), all four provided by `PosBody` and all four
discarded with the page.

## Routing

`Pos.routeKey` / `Pos.path` → `/pos`. **Standalone**: no `shell`, no `parents`. It is not
a home section — a counter has no side bar, no global search and no business selector, so
reusing the home shell would mount all of that just to cover it. Being standalone it
stacks a page over home, so leaving POS (window-bar back on desktop, browser back on web)
finds the previous section exactly as it was left. There is no in-page back button.

## Files

- `_pos.dart` — `Pos extends PageBuilder`, with `routeKey` and `path` declared on the class
  so callers do not depend on how the path is written.
- `desktop/_body.dart` — `PosBody`: three panels in a row, same `gap` as the home. Sides
  are fixed width, the centre takes the rest. Creates and provides the four POS services,
  opens the socket (idempotent — this is a standalone page) and fires every read in the
  first post-frame, including the recovery of the invoice this till left open. Also
  **takes the window to full screen** while POS is mounted (Windows only, `window_manager`;
  undone on `dispose`, and only if this page was the one that turned it on). No
  `DeviceSelector`: a three-panel counter is desktop-only; a phone POS will be a different
  screen, not a narrower one.
- `desktop/left_panel.dart` — two stacked surfaces (what is being charged).
- `desktop/center_panel.dart` — `PosCenterPanel`: the product picker, split into the
  category strip (`PosCategoryBar.height`) and the catalog (keeps the rest). Stateless: the
  strip is only mounted when `PosService.categories` is not empty, and which chip is marked
  is read from `PosCatalogService.category` and written with `filter()`.
- `desktop/category_bar.dart` — `PosCategoryBar`: the strip, a two-row `GridView` that
  scrolls horizontally, one fixed-width chip per category plus "all". Stateless; it neither
  stores what is selected nor knows what it filters.
- `desktop/catalog.dart` — `PosCatalog`: search box over the product grid, with the load /
  error / missing / empty / ready states and the infinite scroll (`_lookahead` tiles before
  the end it asks for the next page). Ends in a footer that shows the page coming down or
  offers to retry the one that did not.
- `desktop/product_tile.dart` — `PosProductTile`: one product (cover, name, price, units
  left). **It is the button**: tapping it puts the product on the ticket — which holds its
  units in the ledger — and tapping it again adds a unit. A product with no price refuses
  here; everything else (no stock, no catalog) is refused by the backend and shown as it
  came worded.
- `desktop/pos_currency.dart` — `posCurrency(context)` (the company's currency, two
  `select`s) and `posAmount(currency, value)` (an amount written whole). Used by the grid
  and by the ticket; every figure on this screen goes through it.
- `desktop/right_panel.dart` — `PosRightPanel`: **the ticket**. One surface, head and foot
  measuring their own and the lines keeping the rest, so the total does not move down the
  panel as products are added. It is also what **announces** what the company did to this
  ticket: it listens to the service and turns `PosTicketNotice` into a `FloatFlag`, once.
- `desktop/ticket_header.dart` — `PosTicketHeader`: the ticket's code, units on it, and
  the button that discards it (top right, `showAlertModal` first, then **cancels the
  invoice** so its holds go back). The code (`K7M4-2QX9`) exists from the moment the
  invoice opens; before the first product there is none, so what is drawn is the day's
  running count (`PosService.mineSales + 1`).
- `desktop/ticket_line.dart` — `PosTicketLine`: one line in two rows (name + line total /
  the −,+ buttons + unit price). Every step travels (`ADD` ±1) and moves the hold; the −
  at one unit takes the line off the ticket. A typed-in charge is inert until the backend
  has given it a line id (`PosCartLine.isPending`). A line whose units are no longer held
  (`!isHeld`) says so between the two rows, in the danger colour.
- `desktop/ticket_footer.dart` — `PosTicketFooter`: the button that charges an amount with
  no product, the VAT row (tappable — it is the only place the rate is set), subtotal,
  total, and **completing the sale**. Opens `PosAmountModal`, `PosTaxModal` and
  `PosCheckoutModal`; the checkout is dimmed while the ticket is still settling.
- `desktop/admin_card.dart` — who is at the counter: picture, name, email, today's sales,
  and the button to leave POS mode.

## The catalog read

The table is not chosen: the backend answers for the company's main table and says which
one it was. Pagination is by **cursor** and there is no total, so what ends the scroll is
the response's `more`. The search box (`SEARCH`) and the strip (`CATEGORY`) AND together on
the backend and both restart at the first page; neither filters in memory, because the grid
holds one page of a catalog that can run to tens of thousands of rows. The endpoint's third
filter, `CODE` (the scanner gun's exact lookup), is not wired: it belongs to a scanner
input the counter does not have.

## The ticket is an invoice

`PosInvoiceService` is a document on the backend and not a list in memory, which is what
makes the counter safe to share. The invoice **opens on the first line**
(`POST /pos/invoices/`, no `TABLE_ID` — the backend sells the company's main table), and
every line goes through `PUT /pos/invoices/items/`, which **holds that product's units in
the ledger right then**: from that instant no other till, no stock screen and no bot is
offered them. Charging (`close`) turns the holds into a sale; discarding (`cancel`) gives
every unit back.

- **A step is `ADD` ±1 and never a computed total.** Two taps arrive within one round trip
  and only a relative move cannot lose a unit between them (the endpoint's own reason for
  having both `ADD` and `QUANTITY`).
- **What is drawn is one tap ahead of what is true.** A change is applied locally, and the
  answer is adopted only when nothing else is in flight — otherwise an older response
  would walk a quantity backwards under the finger pressing "+". A failed write rereads
  the invoice, so the screen never keeps a unit nobody holds.
- **Leaving POS does not throw the ticket away.** The page discards the service, not the
  document: the units stay held and `recover()` (`GET /pos/invoices?MINE=1`) finds it the
  next time this till opens. Only the bin button cancels.
- **The typed-in amount is a line with no product.** The backend takes it as `CONCEPT` +
  `PRICE`, it holds nothing (there is no shelf to take a delivery off), and it is charged
  with the rest. It is addressed by `LINE_ID`, which is why it cannot be stepped until the
  answer to its own creation lands.

**The VAT rate is not in the data.** Neither the business profile nor `/pos/` carries one,
so it starts at zero and is set on the ticket (`PosTaxModal`). It is a percentage the way
the endpoint takes it (`16`, never `0.16`). The backend freezes a line's rate when the
line is created, so changing it **rewrites every line already on the invoice**, one write
each. It is read back off the first line, because the response carries no field for the
ticket's own rate.

## Two terminals on one shelf

The counter is told what it cannot see. `PosCatalogService` listens to `stock/changed`
(`StockChangedModel`) — the notice the **ledger** emits for every way stock moves, whoever
caused it — and writes the new balance onto the product in the grid. So a unit another
till just put on its ticket stops being offered here as it happens, instead of at the next
reload. The tile is still tappable when nothing is left (a sold-out product can still be
ordered); what refuses is the hold, with the shelf's own answer.

**The ticket listens too**, because a document can be touched from screens this counter
cannot see:

| Notice | What this counter does |
|---|---|
| `invoice/updated` on its invoice | reads it back (skipped while a write of its own is travelling, and when the figures already agree — that is the echo of that write) |
| `invoice/closed` / `invoice/cancelled` on its invoice | starts clean and says who ended it (suppressed while it is the one ending it) |
| `stock/changed` | checks its own holds |

The last one is the only way a **released hold** can be noticed: releasing units does not
touch the invoice, so the document goes on saying it holds them and re-reading it answers
nothing. What proves it is one comparison — the notice carries the *whole company's*
`reserved`, so a `reserved` below what *this ticket alone* claims to hold is arithmetic:
those units cannot be held by anybody. The lines are cut down to what is left, the
customer's quantities are not touched (the close takes the units again, or refuses saying
they are gone), and the line says it is no longer set aside. A release masked by another
till's hold is not detectable and is deliberately not guessed at.

## Status

The left panel's top half (section 1) is still an empty surface on purpose, so it can be
built without revisiting how the screen is divided. `GET /pos/invoices` (without `MINE`)
is the read for it: the company's open tabs, which is what would let this till pick up a
ticket another one started.

Everything else is wired: the strip filters the grid, the grid loads the catalog as it is
scrolled and updates itself over the socket, tapping a tile rings the product up and holds
it, and "Complete purchase" charges the invoice through `PosCheckoutModal` and announces
the ticket code. `GET /pos/sales/ticket/:TICKET` (reading a past ticket back) and
`POST /pos/sales/search` (the day's register) are not used by this screen yet.
