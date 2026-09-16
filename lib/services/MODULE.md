# Module: services

**Path** `lib/services`
**Role** All state and backend access. No widgets, no `BuildContext` in business logic (except
explicit `context.read` helpers). Screens read services through `provider`.

## Shape

- `*_service.dart` — `ChangeNotifier` (or plain singleton): a cache, an `XStatus` enum
  (`idle, loading, ready, [empty,] error`) and the calls that fill them.
- `*_model.dart` — immutable class with a `fromJson`-style factory, one backend payload.
  Enums mirroring backend values live next to their model.
- `*_request.dart` — write bodies (create/update/delete), apart from read models so each
  backend contract is one readable file.
- App-wide services: `lib/toolkit/settings/initial_builder.dart`. Scoped ones are created by
  their screen: `SignInService`/`SignUpService` (auth pages), `money/` (finance section),
  `sales/` (sales section), `pos/` (POS page). Their state belongs to the active company and
  is dropped on leaving.
- Socket seams for tests: `seed(...)` / `receive(...)`, `@visibleForTesting`.

## business/

- `business_service.dart` — `BusinessService` (+ `BusinessProfileStatus`,
  `BusinessEmployeesStatus`): companies from `/init/`, the **active** one (every change goes
  through `useBusiness`, then `ConnectionService().rebind()`), create, profile, employees,
  logo (`/business/logo/`, multipart `FILE`), emails. `currency`/`currencyCode` via
  `CurrencyCatalogService`.
- `business_model.dart` — `BusinessModel`: the light business from `/init/`.
- `business_profile_model.dart` — `BusinessProfileModel`, `BusinessActivity`, `BusinessVerification`.
- `business_email_model.dart` — `BusinessEmailModel`, `BusinessEmailPurpose`.
- `business_language.dart` — `BusinessLanguage`.
- `business_location_model.dart` — `BusinessLocationModel`: written address **and** map point, two facts
  neither derived from the other; `point` is how it is written and pasted. Half a point is no point.
- `business_location_request.dart` — `updateLocationRequest` (**only what changed**; empty travels as `null`
  = erase), `parseLocationPoint` (the pair, a decimal comma, or a map link), `LocationPoint`. `COUNTRY` travels
  in this body: the backend hands that one key to the company's own write (clock, payment rails, carriers).
- `business_location_service.dart` — `BusinessLocationService` (+ status): `GET`/`PUT /business/location/`.
  Provided by the business page, not app-wide.
- `business_places_model.dart` — `PlaceSuggestion`, `PlaceModel`: the address search's answers, a picked place
  already in the shape of the form. A suggestion with no id is dropped; half a point is no point.
- `business_places_service.dart` — `BusinessPlacesService` (+ status): `/business/location/search/` and
  `/business/location/place/`. **Owned by the panel that searches**, not provided: it holds one editing session
  (the Places token). `unavailable` is a server with no key, not a failure — the form's fields are the answer
  on their own.
- `business_delivery_model.dart` — `BusinessDeliveryModel`, `DeliveryOption`, `DeliveryZone`, `DeliveryMode`,
  `DeliveryCoverage`, `DeliveryProvider`, `DeliveryCatalog`, `DeliveryEtaUnit`. `delivers`/`pickup` three-state.
- `business_delivery_request.dart` — `DeliveryFlag`, `deliveryFlagRequest`, `deliveryNotesRequest`,
  create/update/remove option bodies, `readDeliveryAmount` (refuses `1,500`, like the backend).
- `business_delivery_service.dart` — `BusinessDeliveryService` (+ status): the answer, its options and the
  carrier catalog (`/delivery/providers/`, read by the form only). Provided by the business page.

## catalog/ — platform configuration from `/init/`

- `catalog_table.dart` — format-agnostic decoder for an `/init` catalog.
- `country_catalog_service.dart` / `country_model.dart` — operated countries.
- `currency_catalog_service.dart` / `currency_model.dart` — currencies (`CurrencyKind`, symbol,
  side, decimals); `resolve(code)` falls back to the app currency; `CurrencyModel.parse`.

## client/

- `client_service.dart` — `ClientService.resolve()`: reads `/init/` before the tree exists
  (for `initialValidator`), fills `businessService` and the catalogs, returns the landing route or `null`.
- `client_model.dart` — `ClientModel`.

## connection/ — the realtime link (singular)

- `connection_service.dart` — `ConnectionService`: owns the `sockets` lifecycle and status.
  `refresh()` forces a reconnect. `rebind()` is that reconnect after a business change (called by
  `BusinessService` on every switch/creation; the server joins rooms only in the handshake) —
  no-op while no connection was opened or after `close()`. `onRestored` fires when a dropped
  connection comes back, never on the first one.

## connections/ — third-party accounts (plural)

- `connections_service.dart` — `ConnectionsService` (+ status): `GET /connections/`, `/connections/detail/$id`, writes.
- `connection_catalog_service.dart` — `ConnectionCatalogService`: `GET /connections/providers/`.
- `connection_provider_model.dart` — `ConnectionProviderModel`, `ConnectionProviderField`,
  `ConnectionFieldType`, `ConnectionScope`.
- `connection_lite_model.dart` — list row. `connection_detail_model.dart` — full form payload.
- `connection_request.dart` — create/update bodies.

## channels/ — AI channels

- `channels_service.dart` — `ChannelsService` (+ status): `GET /channels/`, `/channels/detail/$id`, writes.
- `channel_catalog_service.dart` — `ChannelCatalogService`: `GET /channels/providers/`; `byCode`
  also answers the locally synthesized WhatsApp Personal code.
- `channel_provider_model.dart` — `ChannelProviderModel`, `ChannelProviderField`, `ChannelFieldType`.
  `ChannelProviderModel.whatsappPersonal()` is **not** in the backend catalog: a personal number
  linked by QR through `baileys_server`; no fields.
- `channel_lite_model.dart` / `channel_detail_model.dart` — list row / form payload. Both carry
  `tables` (`ChannelTableModel`); the detail also `paymentMethods` (`ChannelPaymentModel`).
- `channel_table_model.dart` — `{id, name}`; re-joined by the backend on read, a deleted table does not come back.
- `channel_payment_model.dart` — `{id, code, label, method}`; same re-join rule (an account turned off stops coming back).
- `channel_agent_role.dart` — `ChannelAgentRole`. `channel_data_source.dart` — `ChannelDataSource`.
  `channel_tools.dart` — `ChannelTool`.
- `channel_request.dart` — create/update bodies. `TABLES`, `TOOLS`, `PAYMENT_METHODS` always travel
  and replace the whole selection (empty = none).

## baileys/ — WhatsApp Personal sidecar link

See `baileys_server/MODULE.md` for the server side.

- `baileys_service.dart` — `BaileysService` (app-wide, idle until a WhatsApp Personal channel asks):
  `activate(id)` (launch if needed + start), `deactivate(id)` (soft stop), `refresh(ids)` (silent
  read on grid load), `watch(id, until:)` (pairing poll), `unlink(id)` (hard stop, auth wiped,
  new QR needed; falls back to `remove`). Subscribes to `/events` → `statusOf`, logs inbound
  messages in debug. Owns the control API key (generated once, secure storage, passed as
  `CONTROL_API_KEY` on spawn). `_identify(client)` pushes this app's session to the sidecar before
  every activation/refresh — the only credential the backend accepts from it.
- `baileys_client.dart` — `BaileysClient` (+ exception): raw `HttpClient` to the control API
  (not `RestAPI`, which is shaped for the app's backend). `events()`, `shutdown()`, `setBackend`/`clearBackend`.
- `baileys_event.dart` — `BaileysEvent`, `BaileysEventType`, `BaileysMessage` (subset of
  `baileys_server/src/whatsapp/message-mapper.js`).
- `baileys_launcher.dart` — `BaileysLauncher`: spawns the server detached when `/health` fails; in
  debug replaces a server older than its sources. **Dev-time only**: finds `baileys_server/package.json`
  walking up from `Directory.current`; a release build needs a packaged server.
- `baileys_session_status.dart` — `BaileysSessionStatus`, `BaileysSessionState` (mirrors `status.js`).

## database/

- `database_service.dart` — `DatabaseService` singleton: Hive + `flutter_secure_storage`
  (`fromSecure`/`toSecure`). `initialize()` runs in `preCall`.

## files/

- `cdn_service.dart` — `CdnService`: image base URLs from `/init/` (backend sends ids, not addresses).
- `file_model.dart` — `FileModel`, `FileScope`.
- `image_file.dart` — `pickImageBytes()`, `writeTempImage(bytes)`, `discardTempImage(file)`.

## home/

- `home_service.dart` — `HomeService`: side bar state (Hive) and `searchQuery`; `preload()` in `preCall`.

## inventory/ — table authoring

- `table_request.dart` / `table_field_request.dart` / `table_record_request.dart` — table / column / row bodies.
- `table_field_type.dart` — `TableFieldType`.
- `table_field_options.dart` — `OPTIONS`/`CATEGORIES` rules (`sameFieldOption`, `fieldLabelsOf`, `fieldLabelsText`, `fieldLabelsValue`).
- `table_template.dart` — `TableTemplate`: starting categories.
- `import_file.dart` — `ImportFormat`, `pickImportFile()`, `importTableName(path)`.
- `import_source.dart` — `ImportSource`, `ImportSourceGroup`.
- `product_date.dart` — `ProductDate`, `DateSeparatorFormatter`.
- `product_image.dart` — `ProductImage`: thumbnail sizing/URLs.
- `sku_generator.dart` — `nextSku(...)`.

## stock/ — reading and moving inventory

- `tables/tables_service.dart` — `TablesService` (+ `TablesStatus`, `TableImportResult`,
  `TableImportStage`): list, create, rename, delete, import; listens to `table/normalizing|ready`.
- `tables/table_detail_service.dart` — `TableDetailService`: `/inventory/products/builder/details/$id`.
- `tables/table_view_service.dart` — `TableViewService` (+ `TableStructureStatus`, `TableViewStatus`,
  `TablePaging`, `fieldsGrewAtEnd`): structure, paged records, `/records/manage/`, `/records/images/`.
- `tables/table_lite_model.dart` — list row.
- `tables/table_detail_model.dart` — `TableDetailModel` and its summaries (`TableColumnsSummary`,
  `TableAgentSummary`, `TableChannelsSummary`, `TableChannelReader`, `TableFieldVisibility`, …).
- `tables/table_structure_model.dart` — `TableStructureModel`, `TableFieldModel`.
- `tables/table_view_model.dart` — `TableViewModel`, `TableColumnModel`, `TableRowModel`.
- `tables/table_normalize_model.dart` — `POST .../builder/normalize/` result.
- `tables/table_normalizing_model.dart` / `table_ready_model.dart` — `table/normalizing` / `table/ready` notices.
- `summary/stock_summary_service.dart` — `StockSummaryService`: `POST /inventory/stock/summary/`.
- `summary/stock_summary_model.dart` — `StockSummaryPage`, `StockSummaryRow`, `StockSummaryColumn`.
- `movements/stock_movement_model.dart` — `StockMovement`, `StockBalance`, `StockOperation`, `StockReason`.
- `movements/stock_changed_model.dart` — `stock/changed` notice: emitted for **every** stock move
  (sale, restock, another till's hold), carries the balance after it.

## money/ — owned by the finance section

Nothing here adds figures up: every total is the backend's answer.

- `money_service.dart` — `MoneyService` (+ `MoneySummaryStatus`, `MoneyRange`): `GET /money`
  (today = server day, so this and POS agree), `POST /money/summary` for other ranges.
  `MoneyRange.code` = backend shorthand (`today 7d 30d 12m`).
- `money_bot_service.dart` — `MoneyBotService`: `POST /money/ai`, its own window (30 days). A 503 is an error, never zero.
- `money_bot_model.dart` — `MoneyBotSpend`, `MoneyBotAnswers`, `MoneyBotVectors`, `MoneyBotLine`:
  four disjoint areas summing to `total`, in **USD**. `tasks` deliberately not read.
- `money_summary_model.dart` — `MoneySummary`, `MoneyAmount`, `MoneyMethodTotals`,
  `MoneyConceptTotals`, `moneyDouble`/`moneyInt`/`moneyDate`. `credit` is **not** income.
- `money_payments_service.dart` — `MoneyPaymentsService`: `POST /money/payments/search` (paged,
  filters server-side), `record()`, `annul()` (`/void`); every write rereads.
- `money_payment_model.dart` — `MoneyPayment`, `MoneyPaymentStatus`, `MoneyPaymentTotals`, `MoneyPaymentsPage`.
- `money_payment_request.dart` — `recordPaymentRequest`, `voidPaymentRequest`. **No `DIRECTION`**: the concept decides.
- `money_receivables_service.dart` — `MoneyReceivablesService`: `POST /money/receivables`.
- `money_receivable_model.dart` — `MoneyReceivable`, `MoneyReceivableTotals`, `MoneyReceivablesPage`.
- `money_methods_service.dart` — `MoneyMethodsService`: accounts (`GET/POST/PUT/DELETE /money/methods`,
  delete is soft) and rails (`GET /business/payments`). `fields(code)` = a rail's requirement sheet;
  `options` = `banks`, `documents`, `networks`.
- `money_method_model.dart` — `MoneyMethod` (account), `MoneyRail` (available rail),
  `MoneyMethodField` (one requirement), `MoneyPaymentOption`. Rail ≠ account ≠ settlement kind.
- `account_mask.dart` — `AccountMask`, `AccountMaskFormatter`: spaces a number as typed; never
  touches what it cannot describe (email, alias, `+…`), never drops a digit. Backend re-applies it.
- `money_method_request.dart` — create/update/remove. Account travels as `fields:` keyed by column;
  blanks stripped on create, sent as `null` on update (= clear).
- `money_catalog_service.dart` — `MoneyCatalogService`: `GET /money/catalog`; settlement kinds read as `PosPaymentMethod`.
- `money_concept_model.dart` — `MoneyConcept`, `MoneyDirection` (`incoming`/`outgoing`; `value` travels).

## pos/ — owned by the POS page

- `pos_service.dart` — `PosService`: `/pos/` — `mineSales`, `categories`.
- `pos_catalog_service.dart` — `PosCatalogService`: `POST /pos/catalog/`, cursor-paged (no total);
  `search()` (`SEARCH`), `filter()` (`CATEGORY`), `more()`/`retryMore()`. `CODE` not wired.
  Listens to `stock/changed` and patches loaded products.
- `pos_product_model.dart` — `PosProduct`, `PosCatalogPage`.
- `pos_invoice_service.dart` — `PosInvoiceService`: **the ticket is a backend invoice**. Opens on
  first line, lines via `PUT /pos/invoices/items/` (holds units), `close`, `cancel`, `recover()`
  (`?MINE=1`). Owns tax rate and totals; optimistic, reconciles when idle; failed write rereads.
  Listens to `invoice/*` and `stock/changed` → `notice`/`noticeLabel`, `isShort`. Seams `seed`/`receive`.
- `pos_invoice_event.dart` — `PosInvoiceEvent` (the `invoice/*` names + thin payload), `PosTicketNotice`.
- `pos_invoice_model.dart` — `PosInvoice`, `PosInvoiceLine` (`productId` null on a charge line; `qty` ≠ `held`).
- `pos_payment_method.dart` — `PosPaymentMethod` (`reference`, `change` flags).
- `pos_methods_service.dart` — `PosMethodsService`: `GET /pos/methods` (channels ignored).
- `pos_cart_line.dart` — `PosCartLine`: a line as drawn; `key` = backend `lineId` or `draft:…`
  (`isPending`); `held` vs `quantity` (`isHeld`).

## sales/ — owned by the sales section

Rows are measured on read from their owning collection (invoice, conversation, ticket); nothing is a stored list.

- `sales_service.dart` — `SalesService`: `GET /sales` per section (`open(section)`),
  `STAGE`/`CHANNEL`/`MINE` filters (server-side), paging (`hasMore` vs `total`, not rows read),
  `fulfil()` and `approve()`. `approve(row)` writes against `SaleModel.conversation`, never `id`,
  and drops the row. Listens to `sale/progress` and `ConnectionService.onRestored` (see sales
  section). Seams `seed`/`receive`.
- `sales_catalog_service.dart` — `SalesCatalogService`: `GET /sales/stages` (stages in precedence,
  handover modes/states) + `GET /pos/methods` for `channels`. `sections` not read (tab titles are `S`).
  `of(section)`, `stageName`/`channelName` fall back to the code.
- `sale_model.dart` — `SaleModel`, `SalesPage`, `SaleSource`, `SaleSection`, `SaleLevel`,
  `saleAmount`/`saleCount`/`saleDate`. **`saleAmount` returns `null`, not `0`.** Action rules:
  `canFulfil`, `canApprove` (at `verifying` **and** has a `conversation`).
- `sale_detail_service.dart` — `SaleDetailService`: `GET /sales/detail/$reference` (ticket code,
  row id or chat all resolve). **Created per opened panel**, never cached. `missing` =
  `sale_not_found` (news, not an error).
- `sale_detail_model.dart` — `SaleDetailModel` + `SalePaymentModel`, `SaleProofModel`,
  `SaleHandoverModel`, `SaleOriginModel`, `SaleItemModel`, `SaleTaxModel`, `SaleHoldModel`,
  `saleFields(map)`. `payment.proofs` (oldest first) is parsed; `proof` is its last entry.
  `SaleProofModel` kind comes from the **file** (`isImage`/`isFile`/`isLostImage`), not `kind`.
  Meaningful nulls: `reservations` null on a ticket vs `[]`; `handover` null = nothing to hand
  over. `SaleItemModel.isUnheld`.
- `sale_stage_model.dart` — `SaleStage`, `SaleHandoverMode`, `SaleHandoverState`, `SaleStagesCatalog`.
- `sale_channel_model.dart` — `SaleChannel` (from `GET /pos/methods`).
- `sale_progress_model.dart` — `sale/progress` notice; every field always travels; null `section` =
  left both lists (`isGone`); label arrives as `name`.
- `sale_fulfillment_request.dart` — `fulfilSaleRequest(...)`: sets `MODE`/`STATE`, never a stage;
  send only what **changed** (re-sending the mode resets its state).
- `sale_approval_request.dart` — `approveSaleRequest(id:)`, `kSaleClosedStage = "sold"`:
  `PUT /chats/stage` body; `id` is the conversation.

## sign_in/ and sign_up/

- `sign_in/sign_in_service.dart` — `SignInService`: resolves the login method and signs in.
- `sign_in/login_method.dart` — `LoginMethod` (password vs emailed code).
- `sign_up/sign_up_service.dart` — `SignUpService`: `/authentication/sign_up/email/` then `/create/`.

## Backend endpoint index

`/init/` · `/authentication/sign_up/{email,create}/` · `/business/{create,profile,employees,logo,emails,emails/verify,payments}/`
`/business/location/{,search,place}/` · `/business/delivery/{,options,providers}/`
`/channels/{,providers/,detail/$id}` · `/connections/{,providers/,detail/$id}`
`/inventory/products/builder/{list,structure,details,fields,normalize}/` ·
`/inventory/products/records/{list,manage,images}/` · `/inventory/products/import/{structure,records}/$format/` ·
`/inventory/stock/summary/`
`/sales/` · `/sales/stages/` · `/sales/detail/$id` · `/sales/fulfillment/` · `/chats/stage/`
`/pos/` · `/pos/catalog/` · `/pos/methods/` · `/pos/invoices/{,items,close,cancel}`
`/money/` · `/money/summary/` · `/money/ai/` · `/money/catalog/` · `/money/methods/` ·
`/money/payments/{,search,void}/` · `/money/receivables/`
