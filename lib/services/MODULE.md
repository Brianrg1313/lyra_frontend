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
  is dropped on leaving. `chats/` (messages section) and `maps/` (deliveries section) too.
- Socket seams for tests: `seed(...)` / `receive(...)`, `@visibleForTesting`.
- `<domain>/sources/` — the data-source seam (`docs/plan-offline-lan.md` §7.1):
  `<x>_source.dart` (`abstract interface class XSource`, returns models, throws the normalised
  error or `UnreadableAnswer`) and `<x>_cloud_source.dart` (the REST calls, `const`, stateless).
  A service takes `{XSource? source}` for tests and otherwise reads `Sources.<x>`
  (`lib/toolkit/deployment.dart`). **A service never calls `api.*` itself**; cloud-only
  domains (chats, channels, connections, maps, baileys, places, money AI, sign up, business
  e-mails) are not split.

## local_server/ — the master's engine (`lyra_node`), desktop only

Reached through `LanService.server` (the `lan/` services own it).

- `local_server_service.dart` — `LocalServerService` (+ `LocalServerStatus`): `refresh` (also records the LAN port on the
  stored device), `setUp` (the owner only, no company; answers the 24 recovery words once; enrols this app as the master device and keeps its
  `LanDevice`), `enroll` (a new certificate for this app, engine stopped), `start` (attaches to a running engine that
  proved it is ours, else spawns it detached and waits), `stop`, `recover` (enrols too); `error` keeps the engine's
  refusal code. `unavailable` on web/mobile or with no executable. `usernameOf(email)`: a valid S-1 username from an
  e-mail (the setup started from the sign in).
- `node_commands.dart` — `NodeCommands` (seam), `ProcessNodeCommands`: runs `lyra_node <command>` (one JSON line out,
  secrets on stdin), `spawn` detached; finds it in `lyra_node/bin/` next to the app's executable, or `LYRA_NODE`.

## lan/ — this install's side of LAN mode (`docs/plan-offline-lan.md` §5, §7.4)

- `lan_device.dart` — `LanDevice`: role, instance, device id and code, pinned CA, certificate, private key (PEM), master
  addresses (last that answered first) and port. A browser's has no certificate and no PEM (its key is in IndexedDB).
- `lan_identity_store.dart` — `LanIdentityStore` (seam): the device and the session's refresh token.
  `SecureLanIdentityStore` (OS key store via `DatabaseService`), `MemoryLanIdentityStore` (tests).
- `lan_service.dart` — `LanService` (+ `LanStatus`), app-wide (`lanService`): `open` (on the master, starts the engine
  first; connects; resumes the stored session), `unlock`, `enrollMaster`, `needsActivation` (`auth.identify`, the sign in's first step), `signIn`, `activate` (an invited person's code
  and new password, `auth.activate`), `signOut`, `devices`,
  `startPairing`, `revoke`, `browserCa`, `stopServer`, `leave` (back to cloud; a browser asks again), `call(op, args)` (what
  the LAN sources run: a write gets its `commandId`; a lost master is thrown as `{message, action, code: "unreachable"}`).
  A dropped socket reconnects once (→ `revoked`, `unreachable` or where it was); leaving `ready` fires `onSessionRejected`.
  On `ready` it subscribes to the master's events (`since` the last seq after a reconnect) and hands them to
  `ConnectionService.receive`; `resync_required` → `ConnectionService.resync`.
- `lan_pairing_service.dart` — `LanPairingService` (+ `LanPairingError`), flow-scoped (the pairing page): `search` (mDNS),
  `pair` (code exchange with a fresh key; the device becomes a `local` client), `pairScanned` (a QR: its token, each of its
  addresses until one answers), `pairWithPassword` (the sign in's: login and password are the secret, Argon2id in an
  isolate; `locked` for a locked account).
- `network_scan_service.dart` — `NetworkScanService` (+ `NetworkReach`), flow-scoped (the sign in): `scan` asks
  `cloudReachable` and `discoverMasters` at once and whether this computer `canHost` (engine present, not set up);
  online > master > none; `watch` looks again every 15 s until online, `hold` pauses it.

## capabilities/

- `capability_service.dart` — `CapabilityService` singleton, `Capability` (`available`, `needsInternet`, `hidden`):
  which areas the deployment mode has. `modes` mirrors every area's `modes` in `docs/app-areas.json` (a test keeps them
  equal, `action_modes` as `<area>.<action>`); `of(area)` reads the most specific declared area (undeclared = cloud only);
  on a master's devices a local area whose phase 4 release hasn't come is hidden (`_builtOnMaster`);
  `singleCompany` (not cloud); `internet` (hybrid only); `cloudServices` (cloud-only helpers such as the places search
  answer: cloud, or hybrid online). `PermissionsService.can`/`granted` ask it first.

## business/

- `sources/business_source.dart` — `BusinessSource`: create, profile, logo, e-mails (cloud only), location, branches.
  Used by `BusinessService`, `BusinessLocationService`, `BusinessBranchesService`. `business_cloud_source.dart` — REST.
  `business_lan_source.dart` — `BusinessLanSource` over `LanService.call`: profile and location from `business.profile` /
  `business.site.*` in the models' keys (`profileJson`, `locationJson`), screen keys → spec fields (`profileKeys`,
  `siteKeys`), the logo as a file (`fileJson`; `setLogo` uploads then `business.setLogo`); `create` is `business.create` (the welcome's, form keys → fields); branches and e-mails
  throw (hidden on a master).
- `sources/employees_source.dart` — `EmployeesSource`: current (+ active count), former, detail, invite (the id, and a
  master's activation code), edit, edit own profile. Used by `BusinessEmployeesService`. `employees_cloud_source.dart` —
  REST. `employees_lan_source.dart` — `EmployeesLanSource` over `LanService.call`: `employees.*` and `profile.edit`, the
  spec's names laid out as the cloud's rows (`cardJson`, `detailJson`; absent private keys stay empty), edits with the
  cloud's keys as they are.
- `employee_activation_model.dart` — `EmployeeActivation` (a master's code and when it expires),
  `EmployeeInvitationSent` (what inviting answers).
- `sources/delivery_source.dart` — `DeliverySource`: settings, carriers, options, areas, isochrone (cloud only). Used by
  `BusinessDeliveryService`, `DeliveryAreasService`. `delivery_cloud_source.dart` — REST, and the isochrone's largest ring.
- `business_service.dart` — `BusinessService` (+ `BusinessProfileStatus`): companies from `/init/`,
  the **active** one (every change goes through `useBusiness`, then `ConnectionService().rebind()`), create, profile,
  logo (`/business/logo/`, multipart `FILE`), emails. `currency`/`currencyCode` via
  `CurrencyCatalogService`.
- `business_model.dart` — `BusinessModel`: the light business from `/init/` (columnar table or a master's list).
- `business_profile_model.dart` — `BusinessProfileModel`, `BusinessActivity`, `BusinessVerification`.
- `business_employee_model.dart` — `BusinessEmployeeModel` (a row of `GET /business/employees/` or `.../former/`,
  compressed; the viewer's card forced first, kept without an id; `email` only on an invitation to an email with no account), `EmployeeState`, `EmployeeContract`, `EmployeeLeaveType`,
  `EmployeeWorkStatus` (`working` / `notStarted` / away + leave type), `employeeDay` (calendar day, no time zone).
- `business_employee_detail_model.dart` — `BusinessEmployeeDetail` (`GET /business/employees/detail/:ID`): `EmployeePerson`
  (private fields empty unless `fullProfile`), `EmployeeJob` (`salary` null ≠ 0), `EmployeeManager`, `EmployeeLeave`,
  `EmployeeSpan`, `EmployeeEnding`, and the workday/period/contract-status/end-reason/document/sex enums.
- `business_employees_service.dart` — `BusinessEmployeesService` (+ `BusinessEmployeesStatus`, `EmployeeDetailStatus`):
  current + former lists (a failed former read leaves it empty; not read without `viewsAll`), `total` = active count, selection (first read opens the
  viewer), details cached per id, `invite` (`POST /business/employees/invite/` by email, with or without an account; rereads
  and opens it; answers what was sent, a master's activation code included, or null on a refusal), `edit` (`PUT /business/employees/`), `editOwn` (the viewer's personal keys, `PUT /profile/`). Provided by the business page. Seam `seed`.
- `business_email_model.dart` — `BusinessEmailModel`, `BusinessEmailPurpose`.
- `business_language.dart` — `BusinessLanguage`.
- `business_location_model.dart` — `BusinessLocationModel`: written address **and** map point, two facts
  neither derived from the other; `point` is how it is written and pasted. Half a point is no point.
- `business_location_request.dart` — `updateLocationRequest` (**only what changed**; empty travels as `null`
  = erase), `parseLocationPoint` (the pair, a decimal comma, or a map link), `LocationPoint`. `COUNTRY` travels
  in this body: the backend hands that one key to the company's own write (clock, payment rails, carriers).
- `business_location_service.dart` — `BusinessLocationService` (+ status): `GET`/`PUT /business/location/` (the main
  branch's). Owned by the deliveries section and the branch form, not app-wide; no screen writes it (branches are edited
  through `BusinessBranchesService`).
- `business_branch_model.dart` — `BusinessBranchModel`: one row of `GET /business/branches/` (compressed); no country (the company's).
- `business_branch_request.dart` — `BranchDraft` (what the form collects), `createBranchRequest` (empty texts not sent, flags always), `editBranchRequest` (`ID` + **only what changed**; an emptied text travels as `""` = erase, `MAIN` only as `true`, a removed point as both `""`). Points at 6 decimals, as a pair.
- `business_branches_service.dart` — `BusinessBranchesService` (+ status): `GET`/`POST`/`PUT /business/branches/`, rereads after a write.
  Provided by the business page, not app-wide.
- `business_places_model.dart` — `PlaceSuggestion`, `PlaceModel`: the address search's answers, a picked place
  already in the shape of the form. A suggestion with no id is dropped; half a point is no point.
- `business_places_service.dart` — `BusinessPlacesService` (+ status): `/business/location/search/` and
  `/business/location/place/`. **Owned by the panel that searches**, not provided: it holds one editing session
  (the Places token). `unavailable` is a server with no key, not a failure — the form's fields are the answer
  on their own. `restrictTo` searches another country than the company's (`COUNTRY`).
- `business_delivery_model.dart` — `BusinessDeliveryModel`, `DeliveryOption`, `DeliveryZone`, `DeliveryMode`,
  `DeliveryCoverage`, `DeliveryProvider`, `DeliveryCatalog`, `DeliveryEtaUnit`. `delivers`/`pickup` three-state, `meeting` two-state.
- `business_delivery_request.dart` — `DeliveryFlag`, `deliveryFlagRequest`, `deliveryMeetingRequest`, `deliveryNotesRequest`,
  create/update/remove option bodies, `readDeliveryAmount` (refuses `1,500`, like the backend).
- `business_delivery_service.dart` — `BusinessDeliveryService` (+ status): the answer, its options and the
  carrier catalog (`/delivery/providers/`, read by the form only). Provided by the delivery settings page (deliveries section).
- `delivery_area_model.dart` — `DeliveryAreasModel` (`holding(point)`: active, cheapest first), `DeliveryArea` (`radius` | `polygon`,
  fee, minimum, active), `DeliveryAreaKind`, `DeliveryTravelMode`; `readRing`, `ringContains` (same ray casting as the backend),
  `ringSquareKm`, `simplifyRing` (`limit:` raises the tolerance until it fits), `maxRingPoints` (the backend's 250).
- `delivery_area_request.dart` — create/update/active/remove bodies; only the kind's shape travels, coordinates `{LATITUDE, LONGITUDE}` at 6 decimals.
- `delivery_areas_service.dart` — `DeliveryAreasService` (+ status, `limit = 20`): `/business/delivery/areas/`,
  `travelShape` (`POST /scorpius/v1/isochrone` → largest outline, simplified). Provided by the delivery area page.

## catalog/ — platform configuration from `/init/`

- `catalog_table.dart` — format-agnostic decoder for an `/init` catalog.
- `country_catalog_service.dart` / `country_model.dart` — operated countries.
- `phone_plan.dart` — `PhonePlan`: digits after a country code per numbering plan (`of(dial)`, `fits`), `national` drops the trunk `0`.
- `currency_catalog_service.dart` / `currency_model.dart` — currencies (`CurrencyKind`, symbol,
  side, decimals); `resolve(code)` falls back to the app currency; `CurrencyModel.parse`.

## client/

- `client_service.dart` — `ClientService.resolve()`: reads `/init/` before the tree exists
  (for `initialValidator`), fills `businessService` and the catalogs, returns the landing route or `null` (the first pending task's `route` wins over the home; `employment.invitation` is skipped when the person already has a company).
  `signOut(context)`: `POST /authentication/logout/` (best effort, 5 s), drops the token, clears the sidecar's
  credentials, goes to `/login` (a master's sign in there too), then `clear()`s every session service. A new session service with a cache → add it there.
  The same teardown runs when the backend rejects the session mid-use (`onSessionRejected`), without the logout call, plus a `session_expired` flag.
  With `useCookieSession` a failed logout aborts the sign out (only the backend can clear the cookie).
  `acceptInvitation(id)`: `PUT /profile/employments/` with `ACTION: accept`; throws the api error.
- `sources/session_source.dart` — `SessionSource`: `hasSession`, bootstrap (`/init`), accept invitation,
  sign out, identify, sign in (password, code), permission requests. Shared by `ClientService`, `SignInService`,
  `PermissionRequestsService`.
- `sources/session_cloud_source.dart` — `SessionCloudSource`.
- `sources/session_lan_source.dart` — `SessionLanSource`: `session.bootstrap` laid out as `/init` (`initFrom`), sign out on
  the master; sign in goes through `LanService` (`AuthMaster`), so identify/sign in/invitations throw; no permission requests yet.
- `client_model.dart` — `ClientModel`.
- `employment_invitation_model.dart` — `EmploymentInvitation`: one invitation of the `employment.invitation` task.
- `client_task.dart` — `ClientTask` (`invitations`), `ClientTaskKey` (backend key → pre-start route; `null` = no screen yet): `/init`'s `tasks`.

## connection/ — the realtime link (singular)

- `connection_service.dart` — `ConnectionService`: owns the `sockets` lifecycle and status; `open` does nothing outside the
  cloud. `on(event)` listens to the cloud's socket and to the master's stream alike (`receive`, fed by `LanService`;
  `resync` fires `onRestored`); `once`/`off`/`stream` are cloud only.
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
  new QR needed; falls back to `remove`), `signOut()` (sessions keep running, sidecar credentials cleared). Subscribes to `/events` → `statusOf`, logs inbound
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

- `cdn_service.dart` — `CdnService`: image base URLs from `/init/` (backend sends ids, not addresses); on a master,
  `lyra-file:` addresses (`LanFileImage`).
- `file_model.dart` — `FileModel`, `FileScope`.
- `image_file.dart` — `pickImageBytes()`, `writeTempImage(bytes)`, `discardTempImage(file)`.

## permissions/

- `permissions_service.dart` — `PermissionsService` singleton: `/init`'s `permissions` (company id → granted tree, or a
  master's list with wildcards, ids of `docs/app-areas.json`). `can(id)`, `canOpen(area)`, `granted(area)` (its granted actions, `null` = all) on the active company by default; absent on the path = denied, account
  areas (`dashboard`) always open, not loaded (older backend) = nothing hidden, an area the mode lacks (`CapabilityService`) denied before any grant. `own(id)` after `createBusiness`. Cleared on sign out.
- `permission_requests_service.dart` — `PermissionRequestsService` (+ status): `GET`/`POST /permissions/requests/` (active company), `isPending(id)`.
  Owned by `NoPermissionSection`. A `409` rereads the list and `/init` (`refreshCatalogs`) before rethrowing. Seam `seed`.
- `permission_request_model.dart` — `PermissionRequestModel`, `PermissionRequestState` (`granted` = held now, measured on read).
- `permission_request.dart` — `requestPermissionRequest` (`REASON` only when not blank), `kPermissionReasonMax`.

## home/

- `home_service.dart` — `HomeService`: side bar state (Hive) and `searchQuery`; `preload()` in `preCall`.

## preferences/

- `preferences_service.dart` — `PreferencesService` singleton (Hive box `preferences`, `preload()` in `preCall`):
  device-wide theme/language (applied to and persisted from `AppController`); per account (`bindUser` from
  `ClientService`) the last `/home...` path (`homePath`), the last active business (`useBusiness` from
  `BusinessService`) and per-business selections (`RememberedSelection`: `chat`, `employee`; `recall`/`remember`).

## inventory/ — table authoring

- `table_request.dart` / `table_field_request.dart` / `table_record_request.dart` — table / column / row bodies.
- `table_field_type.dart` — `TableFieldType`.
- `table_field_options.dart` — `OPTIONS`/`CATEGORIES` rules (`sameFieldOption`, `fieldLabelsOf`, `fieldLabelsText`, `fieldLabelsValue`).
- `table_template.dart` — `TableTemplate`: starting categories.
- `import_file.dart` — `ImportFormat`, `importExtensions` (the cloud's `kImportExtensions`, a master's
  `kLocalImportExtensions`: `.xlsx`, `.xlsm`, `.csv`), `importFormatOf`, `pickImportFile()`, `importTableName(path)`.
- `import_source.dart` — `ImportSource`, `ImportSourceGroup`.
- `product_date.dart` — `ProductDate`, `DateSeparatorFormatter`.
- `product_image.dart` — `ProductImage`: thumbnail sizing/URLs.
- `sku_generator.dart` — `nextSku(...)`.

## stock/ — reading and moving inventory

- `sources/inventory_source.dart` — `InventorySource`: tables, structure, detail, fields, records (+ match total), images,
  import (structure, then records), normalisation (cloud only). Used by `TablesService`, `TableDetailService`, `TableViewService`.
  `inventory_cloud_source.dart` — REST (reads the created table's id in either shape). `inventory_lan_source.dart` —
  `InventoryLanSource` over `LanService`: cloud bodies' keys → the spec's (`args`), a photo uploaded then
  `inventory.images.add`; an import uploads the file (purpose `import`) for each of its two ops; `normalize` is
  `inventory.tables.normalize`.
- `sources/stock_source.dart` — `StockSource`: summary page, a movement (answers the balance). Used by `StockSummaryService`.
  `stock_cloud_source.dart` — REST. `stock_lan_source.dart` — `StockLanSource`: the five operations as one
  `stock.move` (`operationOf`).
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

- `sources/money_source.dart` — `MoneySource` (+ `MoneyRailFields`, `moneyRailFields`, `moneyPaymentOptions`): summary, payments (search, record, void),
  receivables, payment accounts (+ rail sheets), rails catalogue, currencies, concepts catalogue, the accounting export's
  file. Used by every money service but `MoneyBotService` (cloud only). `money_cloud_source.dart` — REST, and the
  catalogue row readers (no export: `UnsupportedError`).
  `money_lan_source.dart` — `MoneyLanSource`: the master's `money.*` ops (summary, payments, receivables, accounts and
  rails, currencies, catalogue), money from and to minor units of the main currency (an account's fixed commission
  travels as an amount); the cloud's account bodies in the master's keys; `export.accounting` then the file's download.
Nothing here adds figures up: every total is the backend's answer.

- `money_service.dart` — `MoneyService` (+ `MoneySummaryStatus`, `MoneyRange`): `GET /money`
  (today = server day, so this and POS agree), `POST /money/summary` for other ranges.
  `MoneyRange.code` = backend shorthand (`today 7d 30d 12m`). `exportAccounting(request)`: the export's bytes, no state.
- `money_export_request.dart` — `MoneyExportFormat` (`xlsx`, `csv` zipped), `MoneyExportPeriod` (whole month or year,
  `day` as `YYYY-MM-DD`), `moneyExportDatasets`, `moneyExportRequest`, `moneyExportName`.
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
  `options` = `banks`, `documents`, `networks`. `locked` status = a master's `sealed_locked` (M-45).
- `money_method_model.dart` — `MoneyMethod` (account; `currency`, `fee`), `MoneyRail` (available rail; `currency`
  it is fixed to, if any), `MoneyMethodField` (one requirement), `MoneyPaymentOption`, `MoneyFee` + `MoneyFeeType`
  (`none`/`fixed`/`percent`). Rail ≠ account ≠ settlement kind.
- `account_mask.dart` — `AccountMask`, `AccountMaskFormatter`: spaces a number as typed; never
  touches what it cannot describe (email, alias, `+…`), never drops a digit. Backend re-applies it.
- `money_method_request.dart` — create/update/remove. Account travels as `fields:` keyed by column;
  blanks stripped on create, sent as `null` on update (= clear). `CURRENCY`, `FEE_TYPE`, `FEE` (edit: `none` + `null` = remove).
- `money_catalog_service.dart` — `MoneyCatalogService`: `GET /money/catalog`; settlement kinds read as `PosPaymentMethod`.
- `money_currencies_service.dart` — `MoneyCurrenciesService` (+ status): `GET/PUT/DELETE /money/currencies` — main currency + exchange currencies. Every write rereads.
- `money_currency_model.dart` — `MoneyCurrencies` (`main`, `exchanges`, `codes`), `MoneyExchange`, `MoneyRateMode` (`official`/`custom`). Non-positive rate = `null`.
- `money_currency_request.dart` — `saveMoneyExchangeRequest` (upsert; `RATE` only when custom), `removeMoneyExchangeRequest`.
- `currencies_contract.md` — **proposed backend contract** for currencies and for an account's `currency`/`fee` (not built yet).
- `money_concept_model.dart` — `MoneyConcept`, `MoneyDirection` (`incoming`/`outgoing`; `value` travels).

## pos/ — owned by the POS page

- `sources/pos_source.dart` — `PosSource`: day summary, payment methods (unfiltered), catalogue page, open tickets,
  open, write a line, close, cancel. Used by all four POS services. `pos_cloud_source.dart` — REST.
  `pos_lan_source.dart` — the master's `pos.*` ops; money in minor units of the answer's `currency` ↔ the models'
  amounts, percents as text (`"7.5"`), a typed charge's price in the company's currency.
- `pos_service.dart` — `PosService`: `/pos/` — `mineSales`, `categories`.
- `pos_catalog_service.dart` — `PosCatalogService`: `POST /pos/catalog/`, cursor-paged (no total);
  `search()` (`SEARCH`), `filter()` (`CATEGORY`), `more()`/`retryMore()`. `CODE` not wired.
  Listens to `stock/changed` and patches loaded products.
- `pos_product_model.dart` — `PosProduct` (`stock`/`reserved` null = not counted, POS-6), `PosCatalogPage`.
- `pos_invoice_service.dart` — `PosInvoiceService`: **the ticket is a backend invoice**. Opens on
  first line, lines via `PUT /pos/invoices/items/` (holds units), `close`, `cancel`, `recover()`
  (`?MINE=1`). Owns tax rate and totals; optimistic, reconciles when idle; failed write rereads.
  Listens to `invoice/*` and `stock/changed` → `notice`/`noticeLabel`, `isShort`. Seams `seed`/`receive`.
- `pos_invoice_event.dart` — `PosInvoiceEvent` (the `invoice/*` names + thin payload), `PosTicketNotice`.
- `pos_invoice_model.dart` — `PosInvoice`, `PosInvoiceLine` (`productId` null on a charge line; `qty` ≠ `held`;
  `tracked` false only from a master).
- `pos_payment_method.dart` — `PosPaymentMethod` (`reference`, `change` flags).
- `pos_methods_service.dart` — `PosMethodsService`: `GET /pos/methods` (channels ignored).
- `pos_cart_line.dart` — `PosCartLine`: a line as drawn; `key` = backend `lineId` or `draft:…`
  (`isPending`); `held` vs `quantity` (`isHeld`; always true for a charge or an untracked product).

## sales/ — owned by the sales section

- `sources/sales_source.dart` — `SalesSource`: board page, fulfil (answers the sale), approve (cloud only), detail,
  stages, channels. Used by `SalesService`, `SaleDetailService`, `SalesCatalogService`. `sales_cloud_source.dart` — REST.
  `sales_lan_source.dart` — `SalesLanSource`: the master's `sales.*` ops, money from minor units; no `approve`.
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

## chats/ — owned by the messages section

`/aries/v1` via the `aries` client. Contract: `E:/andromeda/backend/projects/lyra/docs/aries-chat-desk.md`.

- `chats_service.dart` — `ChatsService` (+ `ChatsStatus`, `ChatsFilter`): inbox `GET /chats` (filters, `SEARCH`,
  paging), `summary`, `stages`, `tags` (catalog → `tagOf(code)`), `team`, `selected`. Applies
  `chat/message|handover|stage|tags|attention|attended` to held rows; unknown/new chat → debounced page-1 reread (only on page 1, else `pending`). Notifies
  (`FloatFlag`) on `chat/attention|alert|assigned`. `moved(from, to)` after a send opened a new session.
  Seams `seed`/`seedTags`/`receive`.
- `chat_thread_service.dart` — `ChatThreadService` (+ `ChatThreadStatus`): one open chat, **created per
  panel**. `detail/:ID` + `messages/:ID` (`BEFORE`, `ALL`), `send` (returns the landing chat id),
  `pause` `resume` `assign` `setStage` `resolve` `markRead`, `refreshDetail` (the AI spend has no event); patches the inbox row after its writes and
  its tags after each detail read; `chat/tags` replaces the detail's tags.
  Messages deduped by id; ticks never go backwards; `rekeyed` renames. Seams `seed`/`receive`.
- `chat_model.dart` — `ChatModel` (row, tag codes), `ChatsPage`, `ChatStage`, `ChatTag` (catalog, detail, event), `ChatLevel`, `ChatWaiting`, `ChatBot`
  (`isPausedAt`), `ChatPerson`, `ChatLine`, `ChatSummary` (`awaiting` null ≠ 0), `ChatStageOption`,
  `chatText`/`chatInt`/`chatDouble`/`chatDate`/`chatCodes`/`chatEvent`.
- `chat_message_model.dart` — `ChatMessage` (`queued` local), `ChatMessagesPage`, `ChatAuthorKind`, `ChatMessageStatus`.
- `chat_detail_model.dart` — `ChatDetailModel` (full `tags`), `ChatAttention` (`also`), `ChatPayment`, `ChatCartItem`, `ChatUsage` (`usage`: null = unreadable ≠ zero), `ChatUsageArea`.
- `chat_request.dart` — send, pause, id-only (resume/read), assign (`USERNAME` always travels),
  stage (`null` undoes), resolve bodies; `kChatStageSold`, `kChatStageEnded`.
- `chat_event.dart` — `ChatEvent`: socket event names.

## maps/ — the base map (deliveries section)

`/scorpius/v1` via the `scorpius` client. Server side: `E:/andromeda/backend/projects/lyra/lib/models/maps/MODULE.md`.

- `map_tiles_service.dart` — `MapTilesService` (+ `MapTilesStatus`): `GET /tilesets` (vector ones only), `tilesetFor(lat, lng)`
  (the box holding the point, else the first).
- `map_tileset_model.dart` — `MapTilesetModel`: name, type, zoom range, bounds, center (TileJSON order: lon first).
- No client yet for routes, travel times and coverage (`POST /scorpius/v1/{route,matrix,isochrone,coverage}`).
  Before writing one, read "Provider independence" in the server doc: the app calls only `/scorpius`, never a map provider, and keeps only lat/lng.

## sign_in/ and sign_up/

- `sign_in/sign_in_service.dart` — `SignInService`: `email/verify` (account + method), `email/sign_in/password`, code sign in, resend, pending email + account flag (`pending`, `clearPending`).
- `sign_in/login_method.dart` — `LoginMethod`: `method` text of `email/verify` (code, password, reserved OAuths).
- `sign_up/sign_up_service.dart` — `SignUpService`: `email/sign_up/code` (ticket, kept in memory) then `email/sign_up/names` (token).

## Backend endpoint index

`/init/` · `/permissions/requests/` · `/authentication/email/{verify,sign_in/password,sign_in/code,sign_up/code,sign_up/names}/` · `/authentication/logout/` · `/business/{create,profile,logo,emails,emails/verify,payments}/`
`/business/employees/{,former/,detail/$id}`
`/business/location/{,search,place}/` · `/business/delivery/{,options,providers}/`
`/channels/{,providers/,detail/$id}` · `/connections/{,providers/,detail/$id}`
`/inventory/products/builder/{list,structure,details,fields,normalize}/` ·
`/inventory/products/records/{list,manage,images}/` · `/inventory/products/import/{structure,records}/$format/` ·
`/inventory/stock/summary/`
`/sales/` · `/sales/stages/` · `/sales/detail/$id` · `/sales/fulfillment/` · `/chats/stage/`
`/pos/` · `/pos/catalog/` · `/pos/methods/` · `/pos/invoices/{,items,close,cancel}`
`/aries/v1/chats{,/stages,/tags,/summary,/detail/$id,/messages/$id,/messages,/read,/bot/pause,/bot/resume,/assign,/stage,/alerts/resolve}` · `/aries/v1/team`
`/scorpius/v1/tilesets` · `/scorpius/v1/raster/$name/$style/{z}/{x}/{y}{r}.png` · (no client yet) `/scorpius/v1/{route,matrix,isochrone,coverage}`
`/money/` · `/money/summary/` · `/money/ai/` · `/money/catalog/` · `/money/methods/` ·
`/money/payments/{,search,void}/` · `/money/receivables/`
