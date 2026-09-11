# Module: tests

**Path** `test` (flat, ~76 files, `<subject>_test.dart`)
**Run** `flutter test` · `flutter test test/<file>_test.dart`
**Baseline** 817 tests, **3 known failures** (listed at the bottom). `flutter analyze`
must be clean — see the quality gate in `CLAUDE.md`.

## What is tested

Pure logic and small widgets, not whole screens. The three heavy areas:

- **Spreadsheet state** (`sheet_*`, `field_edit`, `field_options`, `field_type`,
  `free_columns`, `column_drag`, `column_order`, `row_cache`, `table_paging`,
  `*_cell`, `gutter_cell`) — the rules the inventory sheet runs on.
- **Backend contracts** (`*_request`, `table_structure`, `table_detail`,
  `table_normalize`, `table_normalizing`, `table_ready`, `stock_summary`, `stock_movement`,
  `pos_catalog`, `pos_invoice`, `business_profile`, `business_email`, `cdn`,
  `country_catalog`, `currency_catalog`, `finance_tabs`) —
  that a payload is built and parsed exactly as the backend expects.
- **Counter rules** (`pos_ticket`, `pos_ticket_sync`, `pos_amount_modal`) — how the
  invoice the backend answers becomes what the panel draws, how a total is built from a
  rate that is not in the data, and that the two ticket forms mount at all (their
  controllers read `S.of(context)`) and keep the separator in a price. What a tap *does*
  is not pinned here: it opens a document and holds units, and no test may hit the
  network — the seam is `PosInvoiceService.seed`. `pos_ticket_sync` pins what the counter
  is told from outside (its ticket charged, cancelled or un-held elsewhere) through
  `PosInvoiceService.receive`, the socket's seam.
- **Channels** (`channel_card_sources`, `channel_form_dirty`, `channel_payment_methods`,
  `channel_edit_bar`, `channel_detail_panel`, `channel_form_select_label`) — that a card names the table it
  answers from instead of counting it and still fits its fixed grid row; that the detail
  panel's confirm/cancel pair is a *comparison* against the channel as read
  (`ChannelFormController.dirty`), so it is absent on an untouched form and goes away
  again when a change is undone by hand; that the data-source select is handed its label
  and not only its id, which is what stops core's select writing into a shared controller
  mid-build; and that unlinking is offered for WhatsApp Personal only, next to the
  disconnect that every channel has. The panel itself is not mounted — it opens by
  reading the channel. `channel_payment_methods` pins the accounts a channel offers: they
  come from the read, ticking one back off is nothing to confirm, and `PAYMENT_METHODS`
  always travels — it replaces the whole selection, so an empty list is "offer none" and
  not a key to omit.
- **Sales** (`sales_board_test`, `sales_detail_test`, `sales_detail_panel_test`,
  `sales_proof_test`, `sales_approve_test`, `sales_money_layout_test`,
  `sales_items_panel_test`, `sales_filters_test`, `sales_search_test`) — the live board, pinned where the screen
  cannot show it:
  both tabs are URLs whose segment **is** the backend's `SECTION`, a row keeps its
  nulls (a conversation has no total, a cash ticket owes nothing — a zero there is a
  figure somebody acts on), only a charged sale the customer does not have can be handed
  over, the handover body sends `MODE`/`STATE` only when they were said, and what a
  `sale/progress` notice does to the list: relabel and float a row it holds, drop one that
  crossed to the other section or out of the stage filter or out of both lists (a null
  `section`), ignore a movement in the list that is not open, and announce rather than
  rebuild past the first page. The seams are `SalesService.seed` / `.receive`, like the
  counter's — **no test may hit the network.**
  `sales_detail_test` pins the other half, which is a parse and not a screen: one payload
  shape for a charged ticket, a cart a till still has open and a purchase being arranged,
  and every distinction in it that is a null a careless parse turns into something else — a
  total of zero on a sale nobody priced, an empty hold list on a ticket that has no list at
  all, a handover on a cart that was never charged, and a cart line that says the units are
  reserved while the ledger holds none of them.
  `sales_detail_panel_test` mounts the blocks at the panel's width with those same three
  payloads — the panel itself is not mounted, since it reads on its first frame — and asks
  for the sentences a missing figure is said with; it is what caught `SettingsTag`
  overflowing on a label longer than a word.
  `sales_filters_test` pins the bar: the count and the controls are **one row** that a
  narrow window may not push off its right edge, the state dropdown says which state is on
  rather than which ones exist, and a tab offers only its own section's states — asking for
  the other one's would be asking the backend for a contradiction it resolves in favour of
  the stage, quietly reopening the tab that was just left, and the bar says when the header's search
  is narrowing the board. The catalog is a stand-in class and the list is
  `SalesService.seed`.
  `sales_proof_test` pins el comprobante: that `payment.proofs` and `payment.proof` are
  the same rows (a parse that took both draws the newest twice, on the one sale where a
  second comprobante means a second transfer), that what is drawn is read off the file and
  not off `kind` (an `image` entry with no file is a picture that could not be stored, and
  the line that came with it is all a person has), and that the block is drawn only for a
  sale with a conversation behind it.
  `sales_approve_test` pins the other new action: only a sale at `verifying` is offered it
  — a stage earlier would be a payment approved before anybody claimed to have made one —
  it is addressed by the **conversation** and never by the row (a row at `verifying` is
  usually the invoice the register opened for that conversation, and its id is not a chat),
  a row carrying no conversation is offered nothing, the body says the sale closed and
  nothing about the money, and the identity card draws the action it is handed and keeps no
  slot when there is none.
  `sales_money_layout_test` pins the one block of the panel that is laid out and not just
  written: the money is read two figures to a line, the method keeps a line of its own, and
  a narrow panel comes back to one column — the panel is only as wide as the window allows,
  and an ellipsis over an amount is a figure nobody can act on.
  `sales_items_panel_test` pins the panel the lines moved to, and the two things that make
  the move worth anything: three hundred lines build the dozen on screen (a `Column` in a
  scroll builds all of them, every time a sale is opened), and the search finds a line by
  either of the two things somebody holding the box has — its name or its code — while a
  three-line ticket is given no search box at all.
  `sales_search_test` mounts the board over a seeded list and searches it from
  `HomeService`: a ticket code finds the sale it names, a name finds both the customer and
  the seller, and a query that matches nothing draws its own news instead of the section's
  empty state — the sale may be on a page nobody has read yet.
- **Routing & shell** (`navis_links`, `navis_shell`, `home_sections_routing`,
  `home_business_scope`, `business_listener`, `home_service_persistence`, `pos_page`,
  `table_import_lock` — a table still being imported does not open).
- **Money** (`finance_tabs`, `payment_method_form`, `account_mask`, `money_bot_spend`,
  `finance_bot_block`, `finance_overview_layout`) — that each tab of the
  money section is its own URL and carries no id (every money endpoint answers for the
  active company),
  that the option sits in the transactions group beside the sales board, and that the
  payment and account
  bodies say what the backend expects: no `DIRECTION` on a payment, blanks stripped on a
  create and sent as `null` on an edit, and never the rail on an edit.
  `payment_method_form` pins the other half of an account: the panel draws the fields the
  **rail** asks for and no others (a Pago Movil has no holder), splits a stored id into
  its type and its number and joins it back on save, spaces a number the rail gives a shape
  to, marks what can be left empty, and says so instead of drawing a hole for a rail that
  asks for nothing. `account_mask` pins the shape itself: it spaces what it understands and
  never mangles what it does not — an email, an alias, a `+` number — nor drops a digit.
  The three bot ones pin what Lyra costs, as the overview shows it: that the four areas of
  `POST /money/ai` are read apart and add up to the total (the searches a reply ran
  counted under the vectors and not twice), that an answer that could not be read stays a
  failure instead of becoming zeros while a measured zero is drawn as a sentence, that a
  spend under a cent is written as a figure, that only the totals are written as money at
  all (bold, one per area plus the card's own — the splits are named and not priced), and
  that the card is drawn whatever the money half did: a company can run its bot for a
  month without recording one payment.

- **Tables** (`table_frozen_band`) — that a frozen band is drawn as wide as the columns
  it measured **plus** its divider. It is the one test in here that pins a rule of `core`,
  because the pixel is lost inside the band where no column width could compensate for
  it: a border is painted inside the box, so a band sized to its columns alone lays out
  its header and every row one pixel short and the table overflows by 1.00 px — in three
  screens at once (the sales board, the payment history, the receivables) and only in
  debug, where nobody is looking.

`_scratch_create_table_smoke_test.dart` is a scratch smoke test, not a contract.

## Harness

Pure logic tests need nothing: import the unit and `expect`.

Widget tests must initialize `AppSize` inside the tree and provide the services the
widget reads:

```dart
tester.pumpWidget(MaterialApp(
  home: Builder(builder: (context) {
    AppSize.instance(context);
    return MultiProvider(providers: [...], child: const WidgetUnderTest());
  })
));
```

Service tests use the singletons directly and reset them in `tearDown`
(e.g. `tearDown(() => useBusiness(null))`). Services expose seeding helpers
(`BusinessService().seed(table)`) so no HTTP is needed — **never hit the network in a test.**

## Conventions

- One file per behaviour, named after the unit, not the screen.
- A `///` header on the file (or on a helper) states what rule is being pinned and why.
- English only: test names, `///` headers and inline comments. Some existing files still
  carry Spanish text from before this rule — translate it whenever you touch that file.
- When a rule changes, update its test in the same change — these tests exist to pin
  backend contracts and editing rules that are otherwise invisible.
- A test whose premise the code has outgrown gets **rewritten to pin what is true now**,
  never deleted and never weakened to green. Confirm which side is stale by reading the
  production `///` docs first: they state the intent the test was written against.

## Known failures (pre-existing, unrelated to the analyzer cleanup)

Assertions on layout geometry and colours that the design has since moved past. Each
needs deciding whether the test or the widget is stale:

- `image_cell_test.dart` — "la celda es un cuadrado aunque la columna sea ancha":
  expects a side of `17.5`, gets `225.5`.
- `stock_summary_test.dart` — "las filas alternan las dos bandas de la cebra": expects
  two zebra colours, gets `[null, null, null, null]`.
- `sheet_zebra_test.dart` — "la fila bajo el mouse y la del cursor tienen su propio fondo":
  expects the hovered row to be painted apart from the plain one, gets the same white.
