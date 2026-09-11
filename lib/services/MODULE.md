# Module: services

**Path** `lib/services`
**Role** All state and backend access. No widgets, no `BuildContext` in business logic
(except explicit `context.read` helpers). Screens read services through `provider`.

## Shape of the module

- `*_service.dart` — a `ChangeNotifier` (or plain singleton). Owns a cache, a load
  status enum, and the calls that fill them.
- `*_model.dart` — an immutable class with a `fromJson`-style factory, mirroring one
  backend payload. Enums that mirror backend values live next to their model.
- `*_request.dart` — the **write** bodies (create/update/delete payload builders), kept
  apart from the read models so backend contracts are in one readable place.
- Load status is always `enum XStatus { idle, loading, ready, [empty,] error }`.

App-wide services are registered in `lib/toolkit/settings/initial_builder.dart`.
Flow-scoped ones (`SignInService`, `SignUpService`) are provided by their screen.

## business/ — the client's companies

- `business_service.dart` — `BusinessService` (+ `BusinessProfileStatus`,
  `BusinessEmployeesStatus`). The collection from `/init/`, the **active** business
  (every change must go through `useBusiness`), creation, profile (`/business/profile/`),
  employees (`/business/employees/`), logo upload (`/business/logo/`, multipart field
  `FILE`), emails (`/business/emails/`, `/business/emails/verify/`). Exposes `currency` /
  `currencyCode` resolved against `CurrencyCatalogService`.
- `business_model.dart` — `BusinessModel`: the light business from `/init/`.
- `business_profile_model.dart` — `BusinessProfileModel` + `BusinessActivity`,
  `BusinessVerification`: the full profile.
- `business_email_model.dart` — `BusinessEmailModel` + `BusinessEmailPurpose`.
- `business_language.dart` — `BusinessLanguage`.

## catalog/ — platform configuration from `/init/`

- `catalog_table.dart` — format-agnostic decoder for an `/init` catalog.
- `country_catalog_service.dart` / `country_model.dart` — operated countries.
- `currency_catalog_service.dart` / `currency_model.dart` — currencies (`CurrencyKind`)
  with symbol/side/decimals; `resolve(code)` falls back to the app currency.

## client/ — the session

- `client_service.dart` — `ClientService`. `resolve()` reads `/init/` before the tree
  exists (used by `initialValidator`) and populates `businessService` and the catalogs.
  Returns the route to land on, or `null`.
- `client_model.dart` — `ClientModel`.

## connection/ — the realtime link (singular)

- `connection_service.dart` — `ConnectionService`: owns the `sockets` lifecycle, exposes
  the status, and `refresh()` forces a reconnect (needed after a business change).

## connections/ — third-party accounts (plural)

- `connections_service.dart` — `ConnectionsService` (+ `ConnectionsStatus`).
  `GET /connections/`, `GET /connections/detail/$id`, writes.
- `connection_catalog_service.dart` — `ConnectionCatalogService` (+ status).
  `GET /connections/providers/`: which services can be connected and what each asks for.
- `connection_provider_model.dart` — `ConnectionProviderModel`, `ConnectionProviderField`,
  `ConnectionFieldType`, `ConnectionScope`.
- `connection_lite_model.dart` — list row payload.
- `connection_detail_model.dart` — everything needed to reopen the form.
- `connection_request.dart` — create/update bodies.

## channels/ — AI channels

- `channels_service.dart` — `ChannelsService` (+ `ChannelsStatus`).
  `GET /channels/`, `GET /channels/detail/$id`, writes.
- `channel_catalog_service.dart` — `ChannelCatalogService` (+ status).
  `GET /channels/providers/`: networks and their credential fields. `byCode` also answers
  `ChannelProviderModel.whatsappPersonalCode`, synthesized locally — see that model.
- `channel_provider_model.dart` — `ChannelProviderModel`, `ChannelProviderField`,
  `ChannelFieldType`. `ChannelProviderModel.whatsappPersonal()` is the one provider **not**
  in the backend catalog: linking a personal number through the local `baileys_server`
  sidecar (see `baileys/`) instead of a Meta business account. No fields — pairing is a QR
  scan, not typed credentials.
- `channel_lite_model.dart` / `channel_detail_model.dart` — list row / full form payload.
  Both carry `tables` as `ChannelTableModel`: the list too, so a card can name the table it
  answers from instead of counting it (`sources` is that list's length). The detail also
  carries `paymentMethods` as `ChannelPaymentModel`.
- `channel_table_model.dart` — `ChannelTableModel`: one linked table, `{id, name}`. The
  name is re-joined by the backend on every read, so a table deleted since it was linked
  simply does not come back.
- `channel_payment_model.dart` — `ChannelPaymentModel`: one payment account the channel may
  offer, `{id, code, label, method}`. Same re-join rule as the tables: an account turned off
  in `/money` stops coming back.
- `channel_agent_role.dart` — `ChannelAgentRole` (sell / support / general).
- `channel_data_source.dart` — `ChannelDataSource` (where the model gets its knowledge).
- `channel_tools.dart` — `ChannelTool` (extra modalities the model can handle).
- `channel_request.dart` — create/update bodies. `TABLES`, `TOOLS` and `PAYMENT_METHODS`
  are pickers, not patches: each always travels and replaces the whole selection.

## baileys/ — WhatsApp Personal sidecar link

- `baileys_service.dart` — `BaileysService`: app-wide, does nothing until a WhatsApp
  Personal channel asks for it. `activate(channelId)` gets `baileys_server` running
  (launching it if needed) and starts the session; `deactivate(channelId)` soft-stops it;
  `refresh(ids)` is a silent best-effort read used when the channel grid loads;
  `watch(channelId, until:)` is the polling stream the pairing modal uses;
  `unlink(channelId)` is the hard stop — WhatsApp drops the device and the auth folder is
  wiped, so a new QR is needed (it starts the sidecar first, and falls back to `remove`
  when the server holds no session for that id, because the folder is the link). Also holds the
  subscription to the server's live event feed, which pushes status changes into
  `statusOf` and prints every inbound WhatsApp message to the Flutter console in debug
  builds (`[baileys] ← <number> (<name>): <text>`). Owns the
  control API key's lifecycle (see `_apiKeyStorageKey`): generated once, kept in
  `DatabaseService`'s secure storage, passed to the process as `CONTROL_API_KEY` every
  time this app spawns it. And `_identify(client)`, called before every activation and on
  every refresh: hands the sidecar this app's own session (`apiOrigin`, `api.token`,
  `AppController().deviceID`, `api.business`), which is the only credential the backend
  accepts from it — see `baileys_server/MODULE.md`, "Identifying itself".
- `baileys_client.dart` — `BaileysClient` (+ `BaileysClientException`): raw `HttpClient`
  calls to the control API (`baileys_server/src/control`) — deliberately not `RestAPI`,
  which is shaped around the app's own backend, not a fixed-key localhost sidecar. Also
  `events()` (the `/events` WebSocket feed), `shutdown()`, and `setBackend`/`clearBackend`
  — the session the sidecar relays under.
- `baileys_event.dart` — `BaileysEvent`, `BaileysEventType`, `BaileysMessage`: one frame
  off that feed; `BaileysMessage` mirrors `baileys_server/src/whatsapp/message-mapper.js`
  (a subset of it — the mapper's fields this app has no use for, such as the raw chat JID,
  are simply not read) and carries `summary`, the one-line console form.
- `baileys_launcher.dart` — `BaileysLauncher`: spawns `baileys_server` detached when its
  health check fails, and in debug builds replaces a running server whose sources are
  newer than its `startedAt` (a detached process otherwise keeps running stale code
  through every app restart). **Dev-time only** — resolves the server by walking up from
  `Directory.current` for a `baileys_server/package.json`; a real install needs the server
  packaged and this resolution replaced with a path next to the app's own executable.
- `baileys_session_status.dart` — `BaileysSessionStatus`, `BaileysSessionState`: mirrors
  `baileys_server/src/whatsapp/status.js`'s wire shape verbatim.

## database/ — local storage

- `database_service.dart` — `DatabaseService` singleton. All Hive access plus
  `flutter_secure_storage` (`fromSecure` / `toSecure`). `initialize()` is called in `preCall`.

## files/ — media

- `cdn_service.dart` — `CdnService`: image base URLs, delivered by `/init/`
  (the backend sends ids, not addresses).
- `file_model.dart` — `FileModel`, `FileScope`.
- `image_file.dart` — `pickImageBytes()`, `writeTempImage(bytes)`, `discardTempImage(file)`:
  pick from disk and leave a temp `File` ready to upload.

## home/

- `home_service.dart` — `HomeService`: side bar state (persisted in Hive).
  `HomeService.preload()` runs in `preCall` so the first build is synchronous.

## inventory/ — table authoring (fields, records, imports)

- `table_request.dart` / `table_field_request.dart` / `table_record_request.dart` —
  write bodies for a table, a column, a row.
- `table_field_type.dart` — `TableFieldType`: the kinds a column can be.
- `table_field_options.dart` — rules for `OPTIONS`/`CATEGORIES` lists
  (`sameFieldOption`, `fieldLabelsOf`, `fieldLabelsText`, `fieldLabelsValue`).
- `table_template.dart` — `TableTemplate`: starting categories for a new table.
- `import_file.dart` — `ImportFormat`, `pickImportFile()`, `importTableName(path)`.
- `import_source.dart` — `ImportSource`, `ImportSourceGroup`: where content can come from.
- `product_date.dart` — `ProductDate` + `DateSeparatorFormatter`: reading/writing dates
  as stored in spreadsheet cells.
- `product_image.dart` — `ProductImage`: thumbnail sizing/URLs.
- `sku_generator.dart` — `nextSku(...)`.

## stock/ — reading and moving inventory

- `tables/tables_service.dart` — `TablesService` (+ `TablesStatus`, `TableImportResult`,
  `TableImportStage`). The table list (`GET /inventory/products/builder/list/`), create,
  rename, delete, and the import flow (`/inventory/products/import/...`).
- `tables/table_detail_service.dart` — `TableDetailService` (+ `TableDetailStatus`):
  a table's settings (`/inventory/products/builder/details/$id`).
- `tables/table_view_service.dart` — `TableViewService` (+ `TableStructureStatus`,
  `TableViewStatus`, `TablePaging`, `fieldsGrewAtEnd`): the spreadsheet's structure
  (`/inventory/products/builder/structure/`) and paged records
  (`/inventory/products/records/list/`), writes via `/records/manage/` and
  `/records/images/`.
- `tables/table_lite_model.dart` — list row.
- `tables/table_detail_model.dart` — `TableDetailModel`, `TableDetailFieldModel`,
  `TableColumnsSummary`, `TableAgentSummary`, `TableChannelsSummary`, `TableChannelReader`,
  `TableFieldVisibility`.
- `tables/table_structure_model.dart` — `TableStructureModel`, `TableFieldModel`.
- `tables/table_view_model.dart` — `TableViewModel`, `TableColumnModel`, `TableRowModel`.
- `tables/table_normalize_model.dart` — result of `POST /inventory/products/builder/normalize/`.
- `tables/table_normalizing_model.dart` — the `table/normalizing` socket notice: the backend
  started preparing an imported table.
- `tables/table_ready_model.dart` — the `table/ready` socket notice: it finished.
- `summary/stock_summary_service.dart` — `StockSummaryService` (+ status),
  `POST /inventory/stock/summary/`.
- `summary/stock_summary_model.dart` — `StockSummaryPage`, `StockSummaryRow`,
  `StockSummaryColumn`.
- `movements/stock_movement_model.dart` — `StockMovement`, `StockBalance`,
  `StockOperation`, `StockReason`: the five inventory write endpoints.
- `movements/stock_changed_model.dart` — `StockChangedModel`: the `stock/changed` socket
  notice, emitted by the ledger for **every** way stock moves (a sale, a restock, a hold
  placed by another till's open ticket). Carries the balance after the movement.

## money/ — the company's money

The six services are **owned by the finance section**, not app-wide: what they hold
belongs to the company being looked at, and leaving the section is exactly when it should
be dropped. Nothing here adds figures up — every total is the backend's answer.

- `money_service.dart` — `MoneyService` (+ `MoneySummaryStatus`, `MoneyRange`): the money
  screen over a window. `GET /money` for today, `POST /money/summary` for any other
  range. Today is left to the backend on purpose (server day), so this screen and the POS
  never disagree about when the day started. `MoneyRange.code` is the same window as the
  backend's own shorthand (`today`, `7d`, `30d`, `12m`), for the endpoints that take one.
- `money_bot_service.dart` — `MoneyBotService` (+ `MoneyBotStatus`): what the company is
  charged for Lyra, the bot that answers its customers (`POST /money/ai`, the backend's
  name for it), over **its own window** (`RANGE`, opens on 30 days).
  Apart from `MoneyService` because the card has its own selector. A refusal is an error
  and never a zero: the backend declines (503) rather than claiming nothing was spent.
- `money_bot_model.dart` — `MoneyBotSpend`, `MoneyBotAnswers`, `MoneyBotVectors`,
  `MoneyBotLine`. Four disjoint areas —answering, tables, vectors, unattributed— that add
  up to `total`, in **USD** and never in the company's currency. The endpoint's per-task
  cut (`tasks`) is deliberately not read: it is the same money sliced another way.
- `money_summary_model.dart` — `MoneySummary`, `MoneyAmount`, `MoneyMethodTotals`,
  `MoneyConceptTotals`, plus `moneyDouble`/`moneyInt`/`moneyDate` (a DECIMAL arrives as
  text often enough to read both). `credit` is **not** income: the goods left and the
  money did not arrive.
- `money_payments_service.dart` — `MoneyPaymentsService` (+ `MoneyPaymentsStatus`): the
  history (`POST /money/payments/search`, paged, filters travel to the backend),
  `record()` (`POST /money/payments`) and `annul()` (`POST /money/payments/void`). Every
  write rereads the list: the totals are the whole filter's.
- `money_payment_model.dart` — `MoneyPayment`, `MoneyPaymentStatus`, `MoneyPaymentTotals`,
  `MoneyPaymentsPage`. A sale's own payment is not here — the ticket is that record.
- `money_payment_request.dart` — `recordPaymentRequest(...)`, `voidPaymentRequest(...)`.
  **No `DIRECTION`**: the concept decides it.
- `money_receivables_service.dart` — `MoneyReceivablesService` (+ status):
  `POST /money/receivables`, the credit tickets still owing.
- `money_receivable_model.dart` — `MoneyReceivable`, `MoneyReceivableTotals`,
  `MoneyReceivablesPage`.
- `money_methods_service.dart` — `MoneyMethodsService` (+ status): the company's accounts
  (`GET/POST/PUT/DELETE /money/methods`) and the rails it may turn on
  (`GET /business/payments`, read whenever the form opens). Also holds `fields(code)` —
  what each rail asks to be filled in, merged from both reads — and `options`, the lists
  those fields are filled from (`banks`, `documents`, `networks`). A removal is a soft
  delete on the other side.
- `money_method_model.dart` — `MoneyMethod` (an account the company turned on),
  `MoneyRail` (one it may), `MoneyMethodField` (one thing a rail asks for: column, type,
  label, `format`, whether it is required) and `MoneyPaymentOption` (a bank with its code,
  a document type, a network). Three things are called method around here and they are not
  the same: the rail, the account, and the settlement kind.
- `account_mask.dart` — `AccountMask` (the shape a number is written in, `0000 000 00 00`)
  and `AccountMaskFormatter`, which writes the separators while it is typed. Applied again
  by the backend on the write (`Requirements.format`), so the same account is spaced the
  same whatever created it. Never touches a value it cannot describe (an email, an alias,
  anything starting with `+`) and never drops a digit.
- `money_method_request.dart` — create/update/remove bodies. The account travels as a map
  keyed by column (`fields:`), because which columns exist is the rail's own sheet. On a
  create the blanks are stripped; on an update they travel as `null`, which is how a field
  is cleared.
- `money_catalog_service.dart` — `MoneyCatalogService` (+ status): `GET /money/catalog`,
  the two closed vocabularies the payment form is built from. The settlement kinds are read
  as `PosPaymentMethod` because both endpoints answer from the same backend catalog.
- `money_concept_model.dart` — `MoneyConcept`, `MoneyDirection` (`in` is a reserved word,
  so the values are `incoming`/`outgoing` and `value` is what travels).

## pos/

- `pos_service.dart` — `PosService` (+ `PosSummaryStatus`): what POS shows on open
  (`/pos/`): today's sales (`mineSales`) and the catalog's `categories`.
- `pos_catalog_service.dart` — `PosCatalogService` (+ `PosCatalogStatus`): the products
  the register sells (`POST /pos/catalog/`), paged by **cursor** (no total). Owns the two
  filters, `search()` (`SEARCH`) and `filter()` (`CATEGORY`); `more()` / `retryMore()`
  are the infinite scroll. `CODE` (the scanner) is not wired. **Listens to
  `stock/changed`** and writes the new balance onto the loaded product, so a second till's
  hold shows here as it happens.
- `pos_product_model.dart` — `PosProduct` (one product as the grid draws it) and
  `PosCatalogPage` (decodes `{ table, size, cursor, more, data }`).
- `pos_invoice_service.dart` — `PosInvoiceService` (+ `PosInvoiceStatus`): **the ticket,
  which is an invoice on the backend.** Opens it on the first line
  (`POST /pos/invoices/`), writes every line through `PUT /pos/invoices/items/` — which
  **holds the units in the ledger** — charges with `POST /pos/invoices/close/`, cancels
  with `POST /pos/invoices/cancel/`, and `recover()`s the one this till left open
  (`GET /pos/invoices?MINE=1`). Owns the tax rate (starts at 0; nothing in the data
  carries one) and the totals. Changes are drawn first and reconciled with the answer when
  nothing else is in flight; a failed write rereads the invoice and leaves the reason in
  `error`. **Listens to `invoice/updated|closed|cancelled` and `stock/changed`**: its own
  invoice touched elsewhere is reread, ended elsewhere starts the counter clean, and a
  `reserved` below what this ticket alone claims to hold cuts the lines' `held` down —
  the only way a released hold can be noticed, since releasing one does not touch the
  document. What it found is left in `notice` / `noticeLabel` for the panel to announce
  (`clearNotice()`); `isShort` is whether anything on the ticket is no longer set aside.
  `seed(invoice)` and `receive(event, data)` are `@visibleForTesting`.
- `pos_invoice_event.dart` — `PosInvoiceEvent`: the four `invoice/*` socket names and the
  thin payload they carry (`id`, `ticket`, `units`, `total`). `PosTicketNotice` is what
  the company did to this ticket (`charged`, `cancelled`, `released`), as an enum because
  the copy belongs in the tree.
- `pos_invoice_model.dart` — `PosInvoice`, `PosInvoiceLine`: the open invoice and the
  charged ticket, which are one document at two moments. `productId` is null on a line
  that is a charge and not a product; `qty` and `held` are two numbers.
- `pos_payment_method.dart` — `PosPaymentMethod`: one accepted way to pay, with the two
  flags that drive the checkout form (`reference`, `change`).
- `pos_methods_service.dart` — `PosMethodsService` (+ status): `GET /pos/methods`, the
  closed vocabulary the payment picker is drawn from. The channels it also answers are not
  read: this screen is the counter.
- `pos_cart_line.dart` — `PosCartLine`: one line **as it is drawn**, with the label and
  price frozen when it was added. `productId` is null on an amount typed in by hand; `key`
  is the backend's `lineId`, or a `draft:`-prefixed one until it answers (`isPending`).
  `held` is what the shelf is actually holding for it, which is not `quantity` once a hold
  is released from elsewhere (`isHeld`).

## sales/ — every sale the company has going

The services are **owned by the sales section**, not app-wide, on the same criteria as
the money ones. Nothing here is a stored list: every row is measured on read from the
collection that owns it (an invoice, a conversation, a ticket) and merged on the backend,
so a row changes because the thing behind it changed.

- `sales_service.dart` — `SalesService` (+ `SalesStatus`). `GET /sales` for one section at
  a time (`open(section)`; both tabs share the instance), the `STAGE`/`CHANNEL`/`MINE`
  filters — all of which travel to the backend — paging, and the two writes:
  `fulfil()` (`PUT /sales/fulfillment`, how the customer gets it) and `approve()`
  (`PUT /chats/stage`, `STAGE: sold` — a person saying the payment arrived, which also
  settles the conversation's money marker). `approve()` takes the **row** and writes
  against `SaleModel.conversation`, never against `id`: a sale at `verifying` is usually
  the ticket the register opened for that conversation, and its id is not a chat
  (`404 chat_not_found`). `approve()` **drops the row** rather than
  rewriting it: the answer is a stage code and not a sale, and approving opens the
  register's own ticket for a purchase that never had one, so the notice that follows may
  not name the id this list holds. **Listens to `sale/progress`**: a row it holds
  is relabelled in place and moved to the top, one that left the section or the stage
  filter is dropped, and a sale it does not hold triggers a debounced reread of page 1 —
  only while the list *is* on page 1, since past it rebuilding would take away somebody's
  scroll, so the movements are counted in `pending` instead. `hasMore` counts against
  `total` and not against rows read: `STAGE` narrows the page, not the query, so a short
  page is not the end of the list. `seed(...)` and `receive(data)` are
  `@visibleForTesting`.
- `sales_catalog_service.dart` — `SalesCatalogService` (+ status): the two closed
  vocabularies the screen is built from. `GET /sales/stages` (the stages, in precedence
  order, plus the handover modes and their states) and `GET /pos/methods` read for its
  `channels` alone — the backend answers the checkout's channel picker and this list's
  channel filter from one catalog on purpose. The endpoint's `sections` are deliberately
  not read: the two lists are tabs of this app, so their titles are `S` keys. `of(section)`
  is the stages of one tab; `stageName`/`channelName` fall back to the code.
- `sale_model.dart` — `SaleModel` (one row), `SalesPage`, `SaleSource`
  (`invoice`/`ticket`/`chat`), `SaleSection` (`process`/`done`), `SaleLevel`, and
  `saleAmount`/`saleCount`/`saleDate`. **`saleAmount` answers `null`, not `0`** — a
  conversation has no total and a cash ticket owes nothing, and a zero there is a figure
  somebody would act on. `SaleModel.section` is null on a list row (the whole page is one
  section) and present on a handover answer, which is the moment a row can change sides.
  The two action rules live here: `canFulfil` (a charged sale the customer does not have)
  and `canApprove` (a sale standing at `verifying` **that carries a conversation**, the one
  point where a person is the missing step). Both stage codes they compare against are
  spelled out as constants — `delivered`, `verifying` — because they are values this app
  *decides* by and not ones it draws. `conversation` is what the approval is addressed by:
  it is `chat` and never `id`, since a row at `verifying` is usually an invoice drawn at
  the stage of the conversation it was opened for.
- `sale_detail_service.dart` — `SaleDetailService` (+ `SaleDetailStatus`). One sale in
  full, `GET /sales/detail/$reference`. **Created per opened panel and discarded with it**:
  a sale is a measurement of collections that keep moving, so a detail kept between two
  openings draws a sale as it was. The reference is whatever names it to a person — the
  ticket code, the row's id, the chat — and the backend resolves all three to the same
  sale, so no caller works out which kind of row it is holding. `missing` is the one
  decline it reads instead of reporting (`sale_not_found`): the conversation stopped being
  a sale, which is news and not a failure, and there is nothing to retry. `seed(...)` is
  `@visibleForTesting`.
- `sale_detail_model.dart` — `SaleDetailModel` and its parts: `SalePaymentModel`,
  `SaleProofModel`, `SaleHandoverModel`, `SaleOriginModel`, `SaleItemModel`, `SaleTaxModel`,
  `SaleHoldModel`, plus `saleFields(map)`. `SalePaymentModel.proofs` is **el comprobante**,
  oldest first, and `proof` is its last entry — the backend sends both and they are the
  same rows, so only the list is parsed. A `SaleProofModel` decides what it is off its
  **file** and not off `kind`: `isImage`, `isFile` (a stored document), `isLostImage` (an
  `image` entry whose bytes could not be stored, where the text that came with it is all
  there is). **One shape for all three sources**, with what a source genuinely
  does not have left null — a conversation has no code, no seller, no tax and no handover.
  Two nulls that are not emptiness: `reservations` is null on a ticket (which holds its
  units on its own lines) against `[]` for a customer nothing is held for, and
  `handover` is null where there is nothing to hand over yet. `SaleItemModel.isUnheld` is
  the gap worth seeing: the cart says reserved and the ledger holds nothing.
- `sale_stage_model.dart` — `SaleStage`, `SaleHandoverMode`, `SaleHandoverState`,
  `SaleStagesCatalog`.
- `sale_channel_model.dart` — `SaleChannel`: where a sale came in through, off
  `GET /pos/methods`.
- `sale_progress_model.dart` — `SaleProgressModel`: the `sale/progress` socket notice.
  Every field always travels, `null` included — **a null `section` is the row leaving both
  lists** (a cancelled invoice, a failed checkout), which is what `isGone` reads. The
  label arrives as `name`, not `label`.
- `sale_fulfillment_request.dart` — `fulfilSaleRequest(...)`: the handover body. It sets a
  **fact** (`MODE`, `STATE`) and never a stage. Neither word is defaulted, and the caller
  sends only what **changed**: naming a mode moves the sale to that mode's opening state,
  so re-sending the mode a delivery already has walks a dispatched order back.

## sign_in/ and sign_up/

- `sign_in/sign_in_service.dart` — `SignInService`: resolves the account's method and
  runs the login. Provided by the login screen only.
- `sign_in/login_method.dart` — `LoginMethod` (password vs. emailed code).
- `sign_up/sign_up_service.dart` — `SignUpService`:
  `/authentication/sign_up/email/` then `/authentication/sign_up/create/`.

## Backend endpoint index

`/init/` · `/authentication/sign_up/{email,create}/` · `/business/{create,profile,employees,logo,emails,emails/verify}/`
`/channels/{,providers/,detail/$id}` · `/connections/{,providers/,detail/$id}`
`/inventory/products/builder/{list,structure,details,fields,normalize}/` ·
`/inventory/products/records/{list,manage,images}/` · `/inventory/products/import/{structure,records}/$format/`
`/inventory/stock/summary/` · `/sales/` · `/sales/stages/` · `/sales/detail/$id` · `/sales/fulfillment/` ·
`/chats/stage/` ·
`/pos/` · `/pos/catalog/` · `/pos/methods/` ·
`/pos/invoices/{,items,close,cancel}` · `/money/` · `/money/summary/` ·
`/money/ai/` · `/money/catalog/` · `/money/methods/` · `/money/payments/{,search,void}/` ·
`/money/receivables/` · `/business/payments/`
