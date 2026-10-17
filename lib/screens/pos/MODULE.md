# Module: pos

**Path** `lib/screens/pos`
**Role** Point-of-sale mode: the counter for in-person sales.
**Services** `PosService` (`/pos/`), `PosCatalogService` (`POST /pos/catalog/`),
`PosInvoiceService` (`/pos/invoices/…`), `PosMethodsService` (`GET /pos/methods`) —
`lib/services/pos`; `TillKitchenService` (`lib/services/kitchen`, cloud only) — all created by `PosBody` and discarded with the page.

## Routing

`Pos.routeKey` / `Pos.path` → `/pos`. **Standalone** (no `shell`, no `parents`): a counter has
no side bar/search/business selector. It stacks over home, so leaving (window/browser back)
returns to the section as it was. No in-page back button.

## Files

- `_pos.dart` — `Pos extends PageBuilder`; `routeKey` and `path` on the class.
- `desktop/_body.dart` — `PosBody`: three panels (fixed sides, flexible centre). Provides the
  five services, opens the socket (idempotent), fires every read on the first frame incl.
  `recover()`. Goes full screen on Windows while mounted (`window_manager`, undone on dispose).
  Desktop only — a phone POS will be a separate screen.
- `desktop/left_panel.dart` — two stacked surfaces; top half intentionally empty (see Status).
- `desktop/center_panel.dart` — `PosCenterPanel`: category strip (only if `PosService.categories`
  not empty; selection read from `PosCatalogService.category`, written with `filter()`) + catalog.
- `desktop/category_bar.dart` — `PosCategoryBar`: stateless two-row horizontal `GridView` of chips plus "all".
- `desktop/catalog.dart` — `PosCatalog`: search + product grid, load/error/missing/empty/ready,
  infinite scroll (`_lookahead`), footer loading/retry.
- `desktop/product_tile.dart` — `PosProductTile`: **the tile is the button** — tap adds (and
  holds) a unit through `posRingUp`. No price → refused here; everything else refused by the backend as worded. No stock line for
  a product nobody counts (`stock` null).
- `desktop/pos_kitchen.dart` — `posRingUp` (a product that offers modifiers and isn't on the ticket asks them first; closed = nothing rung up), `posAnswerRefusal` (`negotiable_short` → «Today there is no fries» → `confirmWithout`/`dropShort`; `invalid_modifiers` → ask and ring up again; else the backend's words).
- `desktop/pos_currency.dart` — `posCurrency(context)`, `posAmount(currency, value)`: every figure goes through it.
- `desktop/right_panel.dart` — `PosRightPanel`: the ticket (fixed head/foot, lines scroll).
  Turns `PosTicketNotice` into a `FloatFlag`, once.
- `desktop/ticket_header.dart` — `PosTicketHeader`: ticket code (or day count `mineSales + 1`
  before the first line), units, discard (confirm → **cancel invoice**, holds released).
- `desktop/ticket_line.dart` — `PosTicketLine`: name/total, a dish's modifiers and what it goes without («+ Cheese $1.00 · without fries»), over −,+/unit price; a refused step goes through `posAnswerRefusal`. Steps are `ADD ±1`;
  − at 1 removes. Inert while `isPending`. `!isHeld` shows a danger note.
- `desktop/ticket_footer.dart` — `PosTicketFooter`: typed-in amount (`PosAmountModal`), VAT row
  (`PosTaxModal`, only place to set it), subtotal, total, checkout (`PosCheckoutModal`, dimmed while settling; done names the sale's `number` when it has one).
- `desktop/admin_card.dart` — who is at the counter, today's sales, exit POS.

## Invariants

- **Catalog**: backend picks the company's main table. Cursor paging, no total (`more` ends it).
  `SEARCH` and `CATEGORY` AND together server-side and restart at page 1 — never filter in memory.
  `CODE` (scanner) not wired.
- **The ticket is a backend invoice**, which makes the counter shareable. Opens on the first line
  (`POST /pos/invoices/`, no `TABLE_ID`); each line via `PUT /pos/invoices/items/` **holds units
  in the ledger** immediately. `close` charges, `cancel` releases.
  - A step is `ADD ±1`, never a computed total (two taps in one round trip must not lose a unit).
  - Drawn state runs one tap ahead; answers adopted only when nothing else is in flight; a failed write rereads.
  - Leaving POS keeps the invoice (units stay held); `recover()` (`GET /pos/invoices?MINE=1`) finds it. Only the bin cancels.
  - A typed-in amount is a line with no product (`CONCEPT` + `PRICE`), holds nothing, addressed by `LINE_ID`.
- **VAT is not in the data**: starts at 0, percentage (`16`); the backend freezes a line's rate,
  so changing it rewrites every line; read back from the first line.
- **Sockets**: `PosCatalogService` applies `stock/changed` to grid products (a sold-out tile stays
  tappable; the hold refuses). `PosInvoiceService`:

  | Notice | Reaction |
  |---|---|
  | `invoice/updated` on its invoice | reread (skipped during own write, or if figures agree) |
  | `invoice/closed` / `cancelled` on its invoice | start clean, announce who ended it (not if self) |
  | `stock/changed` | company `reserved` below what this ticket holds → cut lines' `held`, flag the line |

  A released hold never touches the invoice, so `stock/changed` is the only signal; a release
  masked by another till's hold is undetectable and not guessed at.

## Status

Left panel top half is empty on purpose — `GET /pos/invoices` (no `MINE`, the company's open tabs)
is its intended read. Unused so far: `GET /pos/sales/ticket/:TICKET`, `POST /pos/sales/search`.
