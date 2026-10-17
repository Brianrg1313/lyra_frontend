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
  domains (chats, channels, connections, knowledge, maps, baileys, places, money AI, sign up, business
  e-mails, badges, account, shipments, opening hours, kitchen) are not split.

## local_server/ — the master's engine (`lyra_node`), desktop only

Reached through `LanService.server` (the `lan/` services own it).

- `local_server_service.dart` — `LocalServerService` (+ `LocalServerStatus`): `refresh` (also records the LAN port on the
  stored device), `setUp` (the owner, and the company when made from the cloud; answers the 24 recovery words once; enrols this app as the master device and keeps its
  `LanDevice`), `enroll` (a new certificate for this app, engine stopped), `start` (attaches to a running engine that
  proved it is ours, restarted when it is not the installed version; else spawns it detached and waits), `stop`, `recover` (enrols too); `error` keeps the engine's
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
  first; a master app without its key enrolls on its own when the engine runs unattended; connects; resumes the stored session), `unlock`, `enrollMaster`, `needsActivation` (`auth.identify`, the sign in's first step), `signIn`, `activate` (an invited person's code
  and new password, `auth.activate`), `signInWithGrant` (the cloud grant, `auth.grant`), `unseal` (the password opens a
  granted session's sealed fields, `auth.unseal`), `instanceId` (from the hello), `signOut`, `devices`,
  `startPairing`, `revoke`, `browserCa`, `stopServer`, `leave` (back to cloud; a browser asks again), `call(op, args)` (what
  the LAN sources run: a write gets its `commandId`; a lost master is thrown as `{message, action, code: "unreachable"}`).
  A dropped socket reconnects once (→ `revoked`, `unreachable` or where it was); leaving `ready` fires `onSessionRejected`.
  On `ready` it subscribes to the master's events (`since` the last seq after a reconnect) and hands them to
  `ConnectionService.receive`; `resync_required` → `ConnectionService.resync`.
- `lan_pairing_service.dart` — `LanPairingService` (+ `LanPairingError`), flow-scoped (the pairing page): `search` (mDNS),
  `pair` (code exchange with a fresh key; the device becomes a `local` client), `pairScanned` (a QR: its token, each of its
  addresses until one answers), `pairWithPassword` (the sign in's: login and password are the secret, Argon2id in an
  isolate; `locked` for a locked account).
- `network_scan_service.dart` — `NetworkScanService` (+ `NetworkReach`), flow-scoped (the sign in): the backend only from its `CloudPresence`
  (no HTTP, no timer: connected → online at once, a drop → offline at once and a LAN look); `scan` asks `discoverMasters` and this computer's engine status: `canHost` (present, not set up), `masterHere` (set up);
  online > master > none, `searching` until the socket and the LAN have answered; `watch` looks at the LAN again every 15 s while offline; `hold` pauses it all.
- `hybrid_service.dart` — `HybridService` (+ `HybridJoin`), app-wide (`hybridService`), plan §9.6: `join(login,
  password?)` after an online sign in on a paired device (the master's session too → `hybrid`; another person's kept
  session signed out first; the password when the sign in had one, else or when refused the cloud grant
  (`SyncCloudSource.grant`, injectable); `needsPassword` only when neither and the login used a password there from this device (`hasPassword`, injectable), else `noPassword`: nothing asked → `signIn` once), `resume` (boot and the kept session: `hybrid` when the
  master keeps the session), `adopt` (a master just made from the cloud), `workOffline` / `workOnline` (session kept),
  `stop` (sign out), the internet from its `CloudPresence` alone, no timer (connected/dropped →
  `CapabilityService.internet` at once, the cloud socket reopened when it returns; no answer yet changes nothing); a session on the master alone (`masterOnly`, followed from `LanService`) follows it
  too, and `canGoOnline` says when an online sign in would join it (`shouldOfferOnline` / `offeredOnline`: offered by itself once per session); the link: `shouldAskLink` (once a session, `askedLink`), `linkCandidates` (cloud companies with
  `business.settings.edit`, the master's name first), `link` (`business.link`), `createOnline` (none to join: the master's company
  made online from its profile, `cloudCompanyFrom`, then linked), `declineLink`; `companyFrom(profile,
  cloudId)` (the setup's company from the cloud profile, as the engine's catalogues take it).
- `sync_service.dart` — `SyncService` (+ `SyncState`), app-wide (`syncService`), `business.md` B-33 to B-36: enrols the
  master by itself, once a session, when `hybrid` is online, linked and the person owns the company (`sync.prepare` →
  `SyncCloudSource.enrol` → `sync.enroll`); never a revoked one; `taken` on `site_has_master`; `enrol(replace)` is the
  owner's choice from the server section; `refresh` reads `sync.status`. A network failure retries when the internet returns.
- `sync_cloud_source.dart` — `SyncCloudSource`: `POST /edge/v1/devices` (`edge` api) with `REPLACE` only when asked;
  `grant(instance)`: `POST /edge/v1/grants` (any member, no company needed).

## capabilities/

- `capability_service.dart` — `CapabilityService` singleton, `Capability` (`available`, `needsInternet`, `needsLink`, `hidden`):
  which areas the deployment mode has. `modes` mirrors every area's `modes` in `docs/app-areas.json` (a test keeps them
  equal, `action_modes` as `<area>.<action>`); `of(area)` reads the most specific declared area (undeclared = cloud only);
  outside the cloud what the master serves is open, the rest (cloud only, or a local area whose phase 4 release hasn't
  come, `_builtOnMaster`) is the cloud's: open in hybrid online and linked, `needsLink` in hybrid unlinked,
  `needsInternet` (locked, never hidden) otherwise; `local_server` only on a paired device or a computer
  (`canHostMaster`); `shows` = works now (actions, grants), `exists` = drawn (side bar, tabs), `locked` = drawn locked;
  `singleCompany` (not cloud); `internet`, `linked` (hybrid only); `modeChanged` (notifies); `cloudServices`
  (cloud-only helpers such as the places search answer: cloud, or hybrid online and linked). `PermissionsService.can`/`granted` ask it first.

## business/

- `sources/business_source.dart` — `BusinessSource`: create, profile, logo, e-mails (cloud only), location, branches.
  Used by `BusinessService`, `BusinessLocationService`, `BusinessBranchesService`. `business_cloud_source.dart` — REST.
  `business_lan_source.dart` — `BusinessLanSource` over `LanService.call`: profile and location from `business.profile` /
  `business.site.*` in the models' keys (`profileJson`, `locationJson`), screen keys → spec fields (`profileKeys`,
  `siteKeys`), the logo as a file (`fileJson`; `setLogo` uploads then `business.setLogo`); `create` is `business.create` (the welcome's, form keys → fields); branches and e-mails
  throw (hidden on a master).
- `sources/employees_source.dart` — `EmployeesSource`: current (+ active count), former, detail, invite (the id, and a
  master's activation code; a permissions template: the cloud's `TEMPLATE_ID`, a master's `template`), edit, edit own profile. Used by `BusinessEmployeesService`. `employees_cloud_source.dart` —
  REST. `employees_lan_source.dart` — `EmployeesLanSource` over `LanService.call`: `employees.*` and `profile.edit`, the
  spec's names laid out as the cloud's rows (`cardJson`, `detailJson`; absent private keys stay empty), edits with the
  cloud's keys as they are.
- `employee_activation_model.dart` — `EmployeeActivation` (a master's code and when it expires),
  `EmployeeInvitationSent` (what inviting answers).
- `sources/delivery_source.dart` — `DeliverySource`: settings, carriers, options, areas, isochrone (cloud only). Used by
  `BusinessDeliveryService`, `DeliveryAreasService`. `delivery_cloud_source.dart` — REST, and the isochrone's largest ring.
  `delivery_lan_source.dart` — `DeliveryLanSource` (`hybrid` only): `delivery.*` laid out as the cloud's rows
  (`settingsJson`, `areasJson`: amounts, kilometres), cloud bodies → the master's keys and units (`args`: minor units,
  metres, outline pairs); the isochrone is the cloud's while `cloudServices`.
- `business_service.dart` — `BusinessService` (+ `BusinessProfileStatus`): companies from `/init/`,
  the **active** one (every change goes through `_use`: `useBusiness(cloudKey)`, `CapabilityService.linked`; then
  `ConnectionService().rebind()`), `linked(cloudId)` (joined online), create, profile,
  logo (`/business/logo/`, multipart `FILE`), emails. `currency`/`currencyCode` via
  `CurrencyCatalogService`.
- `business_model.dart` — `BusinessModel`: the light business from `/init/` (columnar table or a master's list);
  `cloudId` (a master's link, `business.md` B-30), `cloudKey` (what the `business_id` header carries).
- `business_profile_model.dart` — `BusinessProfileModel`, `BusinessActivity`, `BusinessVerification`.
- `business_employee_model.dart` — `BusinessEmployeeModel` (a row of `GET /business/employees/` or `.../former/`,
  compressed; the viewer's card forced first, kept without an id; `email` only on an invitation to an email with no account), `EmployeeState`, `EmployeeContract`, `EmployeeLeaveType`,
  `EmployeeWorkStatus` (`working` / `notStarted` / away + leave type), `employeeDay` (calendar day, no time zone).
- `business_employee_detail_model.dart` — `BusinessEmployeeDetail` (`GET /business/employees/detail/:ID`): `EmployeePerson`
  (private fields empty unless `fullProfile`; `sealedLocked` on a master session a cloud grant opened), `EmployeeJob` (`salary` null ≠ 0), `EmployeeManager`, `EmployeeLeave`,
  `EmployeeSpan`, `EmployeeEnding`, and the workday/period/contract-status/end-reason/document/sex enums.
- `business_employees_service.dart` — `BusinessEmployeesService` (+ `BusinessEmployeesStatus`, `EmployeeDetailStatus`):
  current + former lists (a failed former read leaves it empty; not read without `viewsAll`), `total` = active count, `find` (a URL's person; `me` = the viewer's card), details cached per id, `inviteTemplates` (the templates an invitation may carry: the viewer's keys only, none without `business.employees.permissions` or while `PermissionsSource.online`), `invite` (`POST /business/employees/invite/` by email, with or without an account; rereads
  the list; answers what was sent, a master's activation code included, or null on a refusal), `edit` (`PUT /business/employees/`), `editOwn` (the viewer's personal keys, `PUT /profile/`). Provided by `EmployeesSection`. Seam `seed`.
  With `businessId`, each list read hands the viewer's title to `OwnJobTitleService`.
- `own_job_title_service.dart` — `OwnJobTitleService` singleton (`.value` provider): the viewer's job title per company (the `me` row of `EmployeesSource.current`), read once per company (`load`), `remember` (a list the section read), `clear` on sign out. Seam `source`.
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
- `business_branch_model.dart` — `BusinessBranchModel`: one row of `GET /business/branches/` (compressed); no country (the company's); `series` (the sales number prefix, uppercase).
- `business_branch_request.dart` — `BranchDraft` (what the form collects), `createBranchRequest` (empty texts not sent, flags always), `editBranchRequest` (`ID` + **only what changed**; an emptied text travels as `""` = erase, `MAIN` only as `true`, a removed point as both `""`). `SERIES` uppercase. Points at 6 decimals, as a pair.
- `business_branches_service.dart` — `BusinessBranchesService` (+ status): `GET`/`POST`/`PUT /business/branches/`, rereads after a write (and `BranchService.load`).
  Provided by the business page, not app-wide.
- `branch_service.dart` — `BranchService` singleton (+ `BranchStatus`), `.value` provider, cloud only: the branch the person works in (`branch_id` on every api and the socket's `auth`, `useBranch`); `bind(company)` from `BusinessService._use` (the kept one per company, `RememberedSelection.branch`, on the header at once), `load` (`GET /business/branches/`: the person's branches, main first; a kept one the list lacks gives way to the first), `select` (header, kept, socket `rebind`), `settled` (the home waits on it), `shouldAsk`/`asked` (several and none picked, or refused), `refused` (`onBranchRefused`: any `action: "select_branch"` answer, or a socket refused so).
- `business_places_model.dart` — `PlaceSuggestion`, `PlaceModel`: the address search's answers, a picked place
  already in the shape of the form. A suggestion with no id is dropped; half a point is no point.
- `business_places_service.dart` — `BusinessPlacesService` (+ status): `/business/location/search/` and
  `/business/location/place/`. **Owned by the panel that searches**, not provided: it holds one editing session
  (the Places token). `unavailable` is a server with no key, not a failure — the form's fields are the answer
  on their own. `restrictTo` searches another country than the company's (`COUNTRY`).
- `business_delivery_model.dart` — `BusinessDeliveryModel`, `DeliveryOption`, `DeliveryZone`, `DeliveryMode`,
  `DeliveryCoverage`, `DeliveryProvider`, `DeliveryCatalog`, `DeliveryEtaUnit`. `delivers`/`pickup` three-state, `meeting` two-state; an option's `branch` (where a national/international one leaves from; null = whichever serves).
- `business_delivery_request.dart` — `DeliveryFlag`, `deliveryFlagRequest`, `deliveryMeetingRequest`, `deliveryNotesRequest`,
  create/update/remove option bodies (`BRANCH` only off a local reach, on edit only when changed, `""` = whichever serves), `readDeliveryAmount` (refuses `1,500`, like the backend).
- `business_delivery_service.dart` — `BusinessDeliveryService` (+ status): the answer, its options and the
  carrier catalog (`/delivery/providers/`, read by the form only). Provided by the delivery settings panel (`modals/deliveries/delivery_settings/`).
- `delivery_area_model.dart` — `DeliveryAreasModel` (`scope`, both maps in `areas`; `of(branch)`: one map, null = shared;
  `inForce(branches)`: the backend's `DeliveryAreas.inForce`; `holding(point)`: active, cheapest first), `DeliveryArea` (`branch`,
  `radius` | `polygon`, fee, minimum, active), `DeliveryScope {global, branch}`, `deliveringBranch` (the backend's
  `Coverage.dispatcher`: area owner per branch, else the closest `online` branch), `DeliveryAreaKind`, `DeliveryTravelMode`;
  `readRing`, `ringContains` (same ray casting as the backend),
  `ringSquareKm`, `simplifyRing` (`limit:` raises the tolerance until it fits), `maxRingPoints` (the backend's 250).
- `delivery_area_request.dart` — create (`BRANCH` only when it has one)/update/active/remove bodies, `deliveryScopeRequest`
  (`DELIVERY_SCOPE`, a delivery setting); only the kind's shape travels, coordinates `{LATITUDE, LONGITUDE}` at 6 decimals.
- `delivery_areas_service.dart` — `DeliveryAreasService` (+ status, `limit = 20` per map): `/business/delivery/areas/`,
  `setScope` (`PUT /business/delivery/`, then rereads the areas), `travelShape` (`POST /scorpius/v1/isochrone` → largest
  outline, simplified). Provided by the deliveries desk.

## shipments/ — a branch's deliveries board (`envios-frontend.md`; cloud only, `api` direct; owned by the deliveries desk)

- `shipment_model.dart` — `ShipmentState` (codes, `en_route` = `enRoute`; `going`), `ShipmentStateInfo` (`catalog`: name,
  attention, `next`), `Shipment` (`read`, `list` of the compressed board, `leftBoard`: an event with `state: null`; id = the
  sale's, `name` = number else ticket, `charged`, `stored`), `ShipmentCarrier`, `ShipmentDestination`, `ShipmentWindow`,
  `ShipmentStep`, `ShippingSettings` (+ the backend's ranges), `DeliverySlot` (a franja: moments, day and hours as said,
  taken, load, seats), `DeliveryOffer` (what the bot offers: `said` hours), `ShipmentCarriers` (riders by job, providers).
- `shipment_request.dart` — `CarrierChoice` (rider / provider + reference / none), `shipmentStateRequest`,
  `editShipmentRequest` (**only what changed**; empty = `""` takes it off; an address travels with the point it keeps),
  `shippingSettingsRequest` (only what changed; no limit = `""`).
- `shipments_service.dart` — `ShipmentsService` (+ status, `ShipmentsView {going, delivered}`): the board of the
  `branch_id` header's branch, the states' catalog, the person's grant (`canDispatch`, `canConfigure`, `canSchedule` =
  `appointments.configure`), `loadCarriers` (once), `windows`, `move` (answers the row, placed); `shipment/changed`
  replaces, drops (`state: null`, another view) or places in window order; `onRestored` rereads. Seams `seed`, `receiveEvent`.
- `shipping_settings_service.dart` — `ShippingSettingsService` (+ status): `/shipments/settings/`, `measure` (every franja
  with `ALL`, and `/offer/`; a refusal kept in `slotsError`), `save` (only what changed, then measures). Owned by its panel.

## appointments/ — when a branch attends (`sedes-frontend.md` §11; cloud only, `api` direct)

- `opening_hours_model.dart` — `OpeningStretch` (weekday 0 = Sunday, minutes from midnight, `clock`, `minutes`, `service`
  rows narrow a day), `ClosedDay` (`YYYY-MM-DD`, `branch` null = every branch).
- `opening_hours_request.dart` — `setWeekRequest` (the **whole** week of a branch, its services' rows sent back),
  `closeDayRequest`, `reopenDayRequest`.
- `opening_hours_service.dart` — `OpeningHoursService({branch})` (+ status): the branch's week (its services' rows kept
  apart) and the closures here or everywhere; `saveWeek`, `close`, `reopen`. Owned by the shipping schedule panel.

## catalog/ — platform configuration from `/init/`

- `catalog_table.dart` — format-agnostic decoder for an `/init` catalog.
- `country_catalog_service.dart` / `country_model.dart` — operated countries.
- `phone_plan.dart` — `PhonePlan`: digits after a country code per numbering plan (`of(dial)`, `fits`), `national` drops the trunk `0`.
- `currency_catalog_service.dart` / `currency_model.dart` — currencies (`CurrencyKind`, symbol,
  side, decimals); `resolve(code)` falls back to the app currency; `CurrencyModel.parse`.

## client/

- `client_service.dart` — `ClientService.resolve()`: reads `/init/` before the tree exists
  (for `initialValidator`), fills `businessService` and the catalogs, returns the landing route or `null` (the first pending task's `route` wins over the home; `employment.invitation` is skipped when the person already has a company).
  Only an answer with an `action` judges the session (dropped on `login`); no answer (no network) keeps it and returns `/login`, whose page enters with it once the backend answers.
  `signOut(context)`: the session source's sign out (best effort, 5 s; on a master's devices the cloud's too when one is
  stored), drops the token, `hybridService.stop()`, clears the sidecar's credentials, goes to `/login` (a master's sign in there too), then `clear()`s every session service. A new session service with a cache → add it there.
  The same teardown runs when the backend rejects the session mid-use (`onSessionRejected`), without the logout call, plus a `session_expired` flag.
  With `useCookieSession` a failed logout aborts the sign out (only the backend can clear the cookie).
  `acceptInvitation(id)`: `PUT /profile/employments/` with `ACTION: accept`; throws the api error.
- `sources/session_source.dart` — `SessionSource`: `hasSession`, bootstrap (`/init`), accept invitation,
  sign out, identify, sign in (password, code), permission requests. Shared by `ClientService`, `SignInService`,
  `PermissionRequestsService`.
- `sources/session_cloud_source.dart` — `SessionCloudSource`.
- `sources/session_lan_source.dart` — `SessionLanSource`: `session.bootstrap` laid out as `/init` (`initFrom`), sign out on
  the master; sign in goes through `LanService` (`AuthMaster`), so identify/sign in/invitations throw; requests through `permissions.requests.*`.
- `client_model.dart` — `ClientModel`.
- `employment_invitation_model.dart` — `EmploymentInvitation`: one invitation of the `employment.invitation` task.
- `client_task.dart` — `ClientTask` (`invitations`, `method`), `ClientTaskKey` (backend key → pre-start route; `null` = no screen yet): `/init`'s `tasks`.
  `security.two_factor` is exclusive: `resolve` returns `/two_factor` before seeding anything (that `/init` carries nothing else).

## connection/ — the realtime link (singular)

- `cloud_presence.dart` — `CloudPresence`: `presenceSocket` (backend `/presence`, no session) open while the sign in or a `HybridService` session holds one (the socket shared, closed with the last); `live` null until the first answer, then connected or not (the first holder ignores the status the last one left); socket.io reconnects on its own.
- `connection_service.dart` — `ConnectionService`: owns the `sockets` lifecycle and status; `open` does nothing in
  `local`, nor in `hybrid` while the company is unlinked (its handshake would be refused; linking opens it); in `hybrid` the cloud's socket runs beside the master's stream. `on(event)` listens to the cloud's socket and to the master's stream alike (`receive`, fed by `LanService`;
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
  also answers the locally synthesized WhatsApp Personal code. Seam `seed`.
- `channel_provider_model.dart` — `ChannelProviderModel`, `ChannelProviderField`, `ChannelFieldType`.
  `ChannelProviderModel.whatsappPersonal()` is **not** in the backend catalog: a personal number
  linked by QR through `baileys_server`; no fields.
- `channel_lite_model.dart` / `channel_detail_model.dart` — list row / form payload. Both carry
  `tables` (`ChannelTableModel`); the detail also `paymentMethods` (`ChannelPaymentModel`).
- `channel_table_model.dart` — `{id, name}`; re-joined by the backend on read, a deleted table does not come back.
- `channel_payment_model.dart` — `{id, code, label, method}`; same re-join rule (an account turned off stops coming back).
- `channel_preset.dart` — `ChannelPreset` (network, scope, tools; all sell), `ChannelPresetOffer` by catalog
  (`ready`/`soon`/`hidden`; WhatsApp Personal always ready). Fills the create panel only.
- `channel_agent_role.dart` — `ChannelAgentRole`. `channel_data_source.dart` — `ChannelDataSource`.
  `channel_tools.dart` — `ChannelTool`.
- `channel_request.dart` — create/update bodies. `TABLES`, `TOOLS`, `PAYMENT_METHODS` always travel
  and replace the whole selection (empty = none).

## knowledge/ — frequent questions (knowledge section; cloud only, `api` direct)

- `knowledge_service.dart` — `KnowledgeService` (+ `KnowledgeStatus`): `GET /knowledge/`, `create`/`edit`/`remove` (reread after
  each write: `state` and product names are the backend's), `toggle` (row flipped at once, reverted on failure), `pending`.
- `knowledge_entry_model.dart` — `KnowledgeEntry` (`fromResponse`: the compressed list), `KnowledgeState`, `KnowledgeSource`,
  `KnowledgeBranch`, `KnowledgeProduct` (`{id, table, name}`, equal by id).
- `knowledge_request.dart` — `KnowledgeDraft`, `createKnowledgeRequest`, `editKnowledgeRequest` (the whole scope always travels,
  empty = clear), `toggleKnowledgeRequest`, `deleteKnowledgeRequest`, `splitKnowledgeTags`.
- `knowledge_product_search.dart` — `KnowledgeProductSearch`: `POST /knowledge/products/` (`SEARCH`), only the latest answer counts.

## kitchen/ — recipes, modifiers and the kitchen's reports (supply chain section; cloud only, `api` direct)

Contract: `E:/andromeda/backend/projects/lyra/docs/guides/cocina-frontend.md`. Tables and summaries through `Sources`.

- `kitchen_read.dart` — `kitchenNum` `kitchenInt` `kitchenText` `kitchenBool` `kitchenDate` `kitchenMaps` `kitchenTexts`.
- `kitchen_api.dart` — `KitchenApi.reason` (the refusal's code), `KitchenApi.report` (floating flag; an `action` rethrown).
- `kitchen_product_model.dart` — `KitchenProduct`: a summary row named by its first text column, `unit` (a measure column's or a "unit" column's), `stock` with decimals, `supplies`, `made`.
- `made_consumes_model.dart` — `MadeConsumes` (`mapFrom`): what each record of a made table consumes and can be sold now, beside the rows of `records/list` (`consumes`).
- `made_product_model.dart` — `MadeFields` (`of`: name = first `TITLE` else text, price = first `PRICE`, `others` typed in a field), `MadeProduct` (`listFrom` an aligned page: values by FIELD_ID, `consumes`).
- `made_products_service.dart` — `MadeProductsService({tableId})` (+ status, `MadeProductDraft`): one made table's products (structure, pages of 50 with `MATCH`, `more`), the supplies' units (`unitOf`, `units`); `save` creates the name/price columns a table lacks, then the record with its `DATA` (an edit only what changed), `CONSUMES` and `BATCH` in one call, and reads the first page again. Owned by the made products view.
- `kitchen_units.dart` — `KitchenUnit`, `kitchenUnitsFor(unit)` (g/kg, ml/l by their spellings; else only its own), `kitchenBestUnit(qty, unit)` (0.3 kg reads 300 g).
- `recipe_model.dart` — `Recipe` (`read`, `namedAfter`: a write answers without names), `RecipeLine`, `RecipeMode` (`order`/`batch`), `RecipeUse`.
- `recipe_measure.dart` — `RecipeMeasure`, `measureRecipes`: `POST /recipes/availability` (≤ 200 ids per call); shared by `KitchenProductsService` and `StockSummaryService`.
- `recipe_availability_model.dart` — `RecipeAvailability` (`mapFrom`: by product, absent = no recipe; `capacity` only on a batch), `RecipeLimit`, `RecipeShort`.
- `presentation_model.dart` — `Presentation`.
- `modifier_model.dart` — `ModifierGroup` (`max` null = all, `required` = `min` > 0), `ModifierOption` (`spends`), `ModifierProduct`, `ModifierLine`.
- `kitchen_report_model.dart` — `ConsumptionReport`/`ConsumptionSupply`/`ConsumptionDish`/`ConsumptionBatch`, `VarianceRow` (`counted` false = no comparison), `DishCost`/`DishCostLine` (`unitCost` null = never bought with a cost).
- `kitchen_request.dart` — `kitchenQuantity` (whole numbers as integers), recipe (`recipeLinesRequest`: also a made record's `CONSUMES`), delete, pause, produce, discard, presentations, modifier group (option ids kept) and delete bodies; `kitchenWindowRequest` (whole local days in ISO 8601).
- `kitchen_products_service.dart` — `KitchenProductsService` (+ status): the **supplies** tables only (none = empty, no table), the open one's summary pages, their recipes measured per page, `remeasure`; `stock/changed` composite → a dish's `available`, else a row's stock. Seams `seed`/`receive`.
- `recipe_service.dart` — `RecipeService({product})` (+ `RecipeStatus`, `BatchResult`): one product's recipe (`404 recipe_not_found` = `none`), availability and presentations; save (a made product's as its record's `CONSUMES`/`BATCH` through `Sources.inventory`, then read again; a supply's preparation `PUT /recipes`), remove (`removable`: never a made one's), pause, uses, produce, discard, presentations; each write measures again. Per opened panel. `fetch` (a recipe for a modifier's removals).
- `modifiers_service.dart` — `ModifiersService` (+ status): `GET/PUT/DELETE /inventory/modifiers`; every write rereads.
- `kitchen_reports_service.dart` — `KitchenReportsService` (+ `KitchenReport`, status): one report and one window; only the last read counts.
- `kitchen_product_search.dart` — `KitchenProductSearch`: every table's summary `MATCH` at once (supplies, then made, then catalog), `namesIn(tables)`, `productsIn(tables)` (by id, with their unit), `suppliesById`.
- `till_kitchen_service.dart` — `TillKitchenService` (POS page, `pos.kitchen`): `load` (`GET /modifiers` once → which products `offers`), `groupsOf` (`POST /modifiers/availability`), `shortOf` (`POST /recipes/availability` → `short`); a failed read is none. Seam `seed`.

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

- `permissions_service.dart` — `PermissionsService` singleton: `/init`'s `permissions` (company id → granted tree, replaced in the active company by `branch_permissions`' tree for the branch worked in when the person has one there; of the
  ids of `docs/app-areas.json`; a master answers the same tree, `session.md` S-34). `can(id)`, `canOpen(area)`, `granted(area)` (its granted actions, `null` = all) on the active company by default; absent on the path = denied, account
  areas (`dashboard`, `account`) always open, `local_server` open in the cloud (this computer's, not a company's), not loaded (older backend) = nothing hidden, an area the mode lacks (`CapabilityService`) denied before any grant. `own(id)` after `createBusiness`; `owns()` (created here, or in a master's `owned`). Cleared on sign out.
- `permission_requests_service.dart` — `PermissionRequestsService` (+ status): `GET`/`POST /permissions/requests/` (active company), `isPending(id)`.
  Owned by `NoPermissionSection`. A `409` rereads the list and `/init` (`refreshCatalogs`) before rethrowing. Seam `seed`.
- `permission_request_model.dart` — `PermissionRequestModel`, `PermissionRequestState` (`granted` = held now, measured on read).
- `permission_request.dart` — `requestPermissionRequest` (`REASON` only when not blank), `kPermissionReasonMax`.
- `member_permissions_service.dart` — `MemberPermissionsService` (+ status): one person's document, the templates and the viewer's
  own grant, a draft in catalog keys (`toggle`, `apply`, `discard`, `save` sends only what changed, `revoke`), `canChange`/`canApply`
  (escalation), `readOnly` (self, owner, `all` without `all`, `online`); no username = the viewer's own; with several branches `works` (where they work, a draft: `toggleWorks`, `worksEverywhere`, sent as `BRANCHES`), `editIn(branch)` (the draft is that branch's own structure, or the base until it has one: `inherits`; a change there is sent with `BRANCH`), `resetBranch` (`RESET`), `branchable` (not `all`), `placeable`. Owned by `EmployeePermissions`.
- `permission_member_model.dart` — `PermissionMemberModel` (+ `access`, `grant`, `online`: a syncing master's, read-only; `branches` null = every one, `byBranch` → `PermissionBranchGrant`, `worksIn`), `PermissionTemplateModel`, `PermissionTemplateRef`,
  `permissionsMine` (`GET /permissions` → `Grant`).
- `permission_member_request.dart` — `assignMemberRequest` (`USERNAME`, `TEMPLATE_ID?`, partial `PERMISSIONS?`, `BRANCHES` only when given, `BRANCH`, `RESET` only with `BRANCH`).
- `sources/permissions_source.dart` — `PermissionsSource`: `mine`, `templates`, `member(username)`, `assign`, `revoke`.
- `sources/permissions_cloud_source.dart` — `PermissionsCloudSource`: `/permissions/`, `/permissions/templates/`, `/permissions/members/`.
- `sources/permissions_lan_source.dart` — `PermissionsLanSource`: `permissions.get`, `.templates.list`, `.members.detail/assign/revoke`.

## badges/ — what is pending, from `/init` and the socket

Contract: `E:/andromeda/backend/projects/lyra/lib/models/badges/MODULE.md`. Cloud only (a master measures none: no dots).

- `badge_model.dart` — `BadgeModel` (one badge: key, kind, count, level, anchors, dismissible, title l10n key, data),
  `BadgeKind` (`count`/`alert`/`news`), `BadgeLevel` (`max`), `BadgeAnchor` (a place's count/level/keys; `counts` = a number,
  else a dot), `BadgeState` (`fromJson` of the compressed table, `anchor`, `union`: several anchors and/or badge keys, each badge once).
- `badge_place.dart` — `BadgePlace`: **every place in the app that draws a badge → the anchors (or badge keys) it reads** (side bar
  entries via `section(key)`, tabs, header, the two channel-form fields, the profile's country and logo by key). Move a dot here.
  `sidebar.business` and `topbar.account` are not read. `messages` reads `sidebar.chats` (`chats.attention` + `chats.unread`),
  `sales`/`knowledge` their side bar anchors, `salesProcess` the sales board's `process` tab (`sales.new`), `inventoryTransfers` the transfers button and page (`inventory.incoming`).
- `badges_service.dart` — `BadgesService` singleton (`.value` provider): `seed(data, business:)` (`/init`'s, kept only
  when measured for the active company, else read), `refresh` (`GET /badges/`), `seen(keys)` (dismissible only,
  optimistic, `POST /badges/seen/`), `discover(place)` (its `news` seen), `at(place)`, `clear`. Rereads on
  `badges/changed` / `badges/reset` (gathered 300 ms), `onRestored`, and a company switch (old dots dropped at once).
  Reads are REST, never `badges/get`: after a switch the socket still answers for the previous company. Seam `transport`.
  Starts `NotificationsService` (`_listen`) and clears it on sign out.
  **Rows new to this person** (`BadgeRow`: `chat` by chat id, `sale` by its `chat`): `opened(kind, id)` →
  `POST /badges/opened/` (a second call while one travels is sent again after it). The backend answers with
  `badges/opened` `{kind, id}` (`openedEvent`, to this person's screens: `ChatsService`/`SalesService` drop the
  row's `unseen`) and `badges/changed`. `chats.unread` / `sales.new` count exactly the rows marked `unseen`.
- `notification_model.dart` — `NotificationModel` (one row of `GET /notifications/` or one `notification/new`: id, type, title, body
  shown as received, level, link, data, seen, date); `area` = the `HomeSection.key` a type is about (`chat.new` → messages,
  `sale.ticket` → sales, `knowledge.pending` → knowledge): the gate and where tapping goes. A new gated type gets its line there.
- `notifications_service.dart` — `NotificationsService` singleton (`.value` provider): `notification/new` → kept on top of
  `recent` (deduped by id, 30 kept) and shown as a `FloatFlag` — **only if the person can open its `area`** (the event goes to
  the whole company room); `load` (`GET /notifications/`, when the bell opens), `markSeen`, `clear` (sign out, company switch).

## account/ — the signed-in person's own account (cloud only, `api` direct; owned by `EmployeesSection`)

- `two_factor_model.dart` — `TwoFactorMethod` (`app`/`email`), `TwoFactorStatus` (`recoveryLeft` only for the app),
  `TwoFactorEnrollment` (secret + `otpauth` uri, `groupedSecret`), `TwoFactorProof` (`code`|`recovery`; `body(codeKey:)`:
  `CODE`, or `CURRENT_CODE` beside a new factor's own), `recoveryCodesFrom`.
- `account_security_service.dart` — `AccountSecurityService` (+ `AccountSecurityStatus`): `GET /authentication/two_factor`,
  `stageApp`/`enableApp` (→ recovery codes), `stageEmail`/`enableEmail`, `disable`, `regenerate`, static `sendCode`
  (`two_factor/code`) and `verify` (`two_factor/verify`, the sign in's task); `createPassword` (`email/sign_up/password`,
  the first one only; 409 → `hasPassword`). Writes rethrow the backend's error.
- `employment_record_model.dart` — `EmploymentRecord`: a row of `GET /profile/employments` (compressed, company nested).
- `account_history_service.dart` — `AccountHistoryService` (+ status): the work history. Seam `seed`.

## home/

- `home_service.dart` — `HomeService`: side bar state (Hive) and `searchQuery`; `preload()` in `preCall`; `goTo` reopens a section on its last page (`PreferencesService.lastPathIn`).

## preferences/

- `preferences_service.dart` — `PreferencesService` singleton (Hive box `preferences`, `preload()` in `preCall`):
  device-wide theme/language (applied to and persisted from `AppController`); per account (`bindUser` from
  `ClientService`) the last `/home...` path (`homePath`, recorded on `Navis.delegate`), per business the last path of each section (`lastPathIn`), the last active business (`useBusiness` from
  `BusinessService`), per-business selections (`RememberedSelection`: `chat`, `table`, `branch`; `recall`/`remember`)
  and how inventory tables open (`InventoryView`, `inventoryView` / `useInventoryView`);
  `linkDeclined` / `declineLink` (the "not now" to joining a server with its company online); device-wide per master
  instance, `hasMasterPassword` / `rememberMasterPassword` (written by `LanService.signIn`/`activate`).

## inventory/ — table authoring

- `table_request.dart` / `table_field_request.dart` / `table_record_request.dart` — table / column / row bodies.
- `table_field_type.dart` — `TableFieldType`.
- `table_field_options.dart` — `OPTIONS`/`CATEGORIES` rules (`sameFieldOption`, `fieldLabelsOf`, `fieldLabelsText`, `fieldLabelsValue`).
- `table_template.dart` — `TableTemplate`: the create modal's category codes.
- `table_template_model.dart` — `TableTemplateModel`, `TableTemplateField`: a starting table of `GET .../builder/templates/`.
- `table_templates_service.dart` — `TableTemplatesService` (+ status): the templates for the company's activity; owned by the inventory section's empty state.
- `import_file.dart` — `ImportFormat`, `importExtensions` (the cloud's `kImportExtensions`, a master's
  `kLocalImportExtensions`: `.xlsx`, `.xlsm`, `.csv`), `importFormatOf`, `pickImportFile()`, `importTableName(path)`.
- `import_source.dart` — `ImportSource`, `ImportSourceGroup`.
- `product_date.dart` — `ProductDate`, `DateSeparatorFormatter`.
- `product_image.dart` — `ProductImage`: thumbnail sizing/URLs; a stored id, an import's address, or a file name waiting for its file (`missing`, kept in the cell).
- `picture_key.dart` — `pictureKey` (equal to the backend's `Ingest.key`), `isPictureName`, `looksLikePicture` (bytes sniff).
- `picture_import_model.dart` — `PictureProgress` (`image/progress` and `…/status` counters, changed `tables`), `PictureImportStatus` (+ `names`, `failures`), `PictureFailure`.
- `picture_import_service.dart` — `PictureImportService` (singleton, app scope; cloud only, `inventory.picture_import` + `inventory.pictures`): on `image/progress` `client` > 0 claims, downloads from the device and delivers (or fails) until nothing is left (never on the web); `afterImport` looks in the spreadsheet's folder for the names it wrote; `lookIn(folder)`, `unzip(zip)` (unpacked here, size caps) upload only files a missing name keys to `match`; `read`, `retry`, `check`. Calls `api` directly.
- `sku_generator.dart` — `nextSku(...)`.

## stock/ — reading and moving inventory

- `sources/inventory_source.dart` — `InventorySource`: tables, templates (cloud only; a master answers none), structure, detail,
  fields, records (+ match total), images, import (structure, then records), normalisation (cloud only). Used by `TablesService`, `TableDetailService`, `TableViewService`.
  `inventory_cloud_source.dart` — REST (reads the created table's id in either shape). `inventory_lan_source.dart` —
  `InventoryLanSource` over `LanService`: cloud bodies' keys → the spec's (`args`), a photo uploaded then
  `inventory.images.add`; an import uploads the file (purpose `import`) for each of its two ops; `normalize` is
  `inventory.tables.normalize`.
- `sources/stock_source.dart` — `StockSource`: summary page (of a `tableId`, or the primary; in a `StockSummarySort`'s order), a movement (answers the balance), a product's presentations (cloud; a master none), a product's ledger page (`movements`, cloud only). Used by `StockSummaryService`, `StockHistoryService`.
  `stock_cloud_source.dart` — REST. `stock_lan_source.dart` — `StockLanSource`: the five operations as one
  `stock.move` (`operationOf`). Also transfers (search, create, update, receive) and a branch's prices (read, set, remove):
  cloud only, the LAN source throws `UnsupportedError` (a master is one site).
- `transfers/stock_transfer_model.dart` — `StockTransfer` (`read`; `from`/`to` branch ids, lines, units, received, `settled`, `movedAt`, `sentBy`), `StockTransferLine` (`sku`, quantity, received, `shortage`), `StockTransferStatus` (`draft sent received cancelled`), `StockShortage` (`damage loss theft`), `StockTransfersPage`.
- `transfers/stock_transfer_request.dart` — `createTransferRequest` (`SEND` only to send at once, lines without units dropped), `editTransferRequest`, `transferActionRequest` (send / cancel), `receiveTransferRequest` (only the lines counted short), `searchTransfersRequest`.
- `transfers/stock_transfers_service.dart` — `StockTransfersService` (+ status, `StockTransferSide`, `TransferProduct`): one side and status at a time (opens on incoming `sent`), paging, writes answer the row (`_place`), `transfer/changed` replaces or rereads, `onRestored` rereads; `canSend`/`canReceive` from the person's own grant (`PermissionsSource.mine`: `inventory.transfer`, `inventory.receive`); `nameOf` (the table's summary, first text column, 200 rows, once per table), `searchProducts` (primary table, free = stock − reserved), `destinations`. Owned by the transfers page.
- `tables/tables_service.dart` — `TablesService` (+ `TablesStatus`, `TableImportResult`,
  `TableImportStage`): list, create, rename, delete, import (then `PictureImportService.afterImport`); listens to `table/normalizing|ready`.
- `tables/table_detail_service.dart` — `TableDetailService`: `/inventory/products/builder/details/$id`.
- `tables/table_view_service.dart` — `TableViewService` (+ `TableStructureStatus`, `TableViewStatus`,
  `TablePaging`, `fieldsGrewAtEnd`): structure, paged records, `/records/manage/` (a created record is placed with its answered id and its page re-read in place, no reset), `/records/images/`, `writeStock`; `image/progress` naming its table re-reads the cached pages in place (gathered 3 s).
- `tables/table_stock_mover.dart` — `TableStockMover`: the sheet's `StockMover` (moves through `StockSource`, writes the balance in the row).
- `tables/table_lite_model.dart` — list row, `TableKind` (`catalog made supplies`; unknown = catalog).
- `tables/table_detail_model.dart` — `TableDetailModel` and its summaries (`TableColumnsSummary`,
  `TableAgentSummary`, `TableChannelsSummary`, `TableChannelReader`, `TableFieldVisibility`, …).
- `tables/table_structure_model.dart` — `TableStructureModel`, `TableFieldModel`.
- `tables/table_view_model.dart` — `TableViewModel` (`consumes` of a made page), `TableColumnModel`, `TableRowModel`.
- `tables/table_normalize_model.dart` — `POST .../builder/normalize/` result.
- `tables/table_normalizing_model.dart` / `table_ready_model.dart` — `table/normalizing` / `table/ready` notices.
- `prices/branch_price_model.dart` — `BranchPrice` (a product's own price at a branch: `price` null = the catalog's, `inheritsDiscount`, `discount` null = no offer there), `setBranchPriceRequest` (`DISCOUNT` null with `clearDiscount`), `removeBranchPriceRequest`.
- `prices/branch_prices_service.dart` — `BranchPricesService({productId, tableId})` (+ status): every branch's own prices of one product, `here` (the branch worked in), `canPrice` (`products.price` from the person's grant), `set`/`remove` (the header's branch only; reread after), `price/changed` for the product rereads. Owned by its panel.
- `summary/stock_summary_service.dart` — `StockSummaryService({tableId, supplies, recipes})`: `POST /inventory/stock/summary/` (`TABLE_ID`, `SORT`: `sortBy`); `supplies` = moves with decimals; `recipes` = each page's recipes measured (`recipeOf`); `presentations` (a failed read = none); `image/progress` naming its table is a quiet `syncColumns`.
- `summary/stock_summary_model.dart` — `StockSummaryPage`, `StockSummaryRow` (`stock`, `reserved`, `transit`: `num`, a supply's decimals), `StockSummaryColumn` (`sortable`; fixed `image stock reserved transit performance`), `StockSummarySort`.
- `movements/stock_movement_model.dart` — `StockMovement` (`num quantity`, `PRESENTATION`, `COST` only on `restock`), `StockBalance` (`num`), `StockOperation`, `StockReason` (`waste`), `stockNum`, `stockFigure`.
- `movements/stock_ledger_model.dart` — `StockLedgerEntry` (operation, reason, positive `qty` and its `sign`, actor, `madeFor`, `pack`, `cost`, `available` after), `StockLedgerPage`.
- `movements/stock_mover.dart` — `StockMover`: what the movement form writes through (`StockSummaryService`, `TableStockMover`).
- `movements/stock_history_service.dart` — `StockHistoryService({productId})`: `POST /inventory/stock/movements` (`PRODUCT_ID`, pages of 30); the dishes a `for` names, from the catalog tables' first rows (`KitchenProductSearch.namesIn`), once.
- `movements/stock_changed_model.dart` — `stock/changed` notice: emitted for **every** stock move
  (sale, restock, another till's hold), carries the balance after it; `exact` keeps a supply's decimals;
  `composite` (a dish made to order): only `available` means anything — the POS keeps its hold, the ticket ignores it.

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
  delete is soft; every branch's) and rails (`GET /business/payments`); `usable`: the active branch's and the company's (what a payment may land in). `fields(code)` = a rail's requirement sheet;
  `options` = `banks`, `documents`, `networks`. `locked` status = a master's `sealed_locked` (M-45).
- `money_method_model.dart` — `MoneyMethod` (account; `currency`, `fee`, `branch` null = the company's, `servesBranch`), `MoneyRail` (available rail; `currency`
  it is fixed to, if any), `MoneyMethodField` (one requirement), `MoneyPaymentOption`, `MoneyFee` + `MoneyFeeType`
  (`none`/`fixed`/`percent`). Rail ≠ account ≠ settlement kind.
- `account_mask.dart` — `AccountMask`, `AccountMaskFormatter`: spaces a number as typed; never
  touches what it cannot describe (email, alias, `+…`), never drops a digit. Backend re-applies it.
- `money_method_request.dart` — create/update/remove. Account travels as `fields:` keyed by column;
  blanks stripped on create, sent as `null` on update (= clear). `BRANCH` on create only with one, on update only when moved (`(id: null)` = the company). `CURRENCY`, `FEE_TYPE`, `FEE` (edit: `none` + `null` = remove).
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
  A dish: `add(product, modifiers:)` (`MODIFIERS`, null keeps the line's), `carries`; a `negotiable_short` refusal kept in `short`
  until `confirmWithout(lines)` (same body + `WITHOUT`) or `dropShort`; `asksModifiers` (`invalid_modifiers`). Types `PosModifierPick`, `PosShortWrite`.
- `pos_invoice_event.dart` — `PosInvoiceEvent` (the `invoice/*` names + thin payload), `PosTicketNotice`.
- `pos_invoice_model.dart` — `PosInvoice`, `PosInvoiceLine` (`productId` null on a charge line; `qty` ≠ `held`;
  `tracked` false only from a master; a dish's `without`/`omitted`/`modifiers`: `PosLineOmission`, `PosLineModifier`).
- `pos_payment_method.dart` — `PosPaymentMethod` (`reference`, `change` flags).
- `pos_methods_service.dart` — `PosMethodsService`: `GET /pos/methods` (channels ignored).
- `pos_cart_line.dart` — `PosCartLine`: a line as drawn; `key` = backend `lineId` or `draft:…`
  (`isPending`); `held` vs `quantity` (`isHeld`; always true for a charge or an untracked product); `omitted` names, `modifiers`.

## sales/ — owned by the sales section

- `sources/sales_source.dart` — `SalesSource`: board page, fulfil (answers the sale), approve (cloud only), detail,
  stages, channels. Used by `SalesService`, `SaleDetailService`, `SalesCatalogService`. `sales_cloud_source.dart` — REST.
  `sales_lan_source.dart` — `SalesLanSource`: the master's `sales.*` ops, money from minor units; no `approve`.
Rows are measured on read from their owning collection (invoice, conversation, ticket); nothing is a stored list.

- `sales_service.dart` — `SalesService`: `GET /sales` per section (`open(section)`),
  `STAGE`/`CHANNEL`/`MINE` filters (server-side), paging (`hasMore` vs `total`, not rows read),
  `fulfil()` and `approve(sale, amount?, currency?)`. `approve` writes against `SaleModel.conversation`, never `id`,
  and rereads the board (approving is not closing: the row stays in process). Listens to `sale/progress` and `ConnectionService.onRestored` (see sales
  section). `review(sale)`: opening a sale clears its `unseen` and sends `BadgesService.opened(sale, chat)`;
  `badges/opened` (kind `sale`) clears every row with that `chat`. Seams `seed`/`receive`.
- `sales_catalog_service.dart` — `SalesCatalogService`: `GET /sales/stages` (stages in precedence,
  handover modes/states) + `GET /pos/methods` for `channels`. `sections` not read (tab titles are `S`).
  `of(section)`, `stageName`/`channelName` fall back to the code.
- `sale_model.dart` — `SaleModel` (`number`: the branch's internal `A-000123` of a completed sale, empty before; also on `SaleDetailModel` and `PosInvoice`), `SalesPage`, `SaleSource`, `SaleSection`, `SaleLevel`,
  `saleAmount`/`saleCount`/`saleDate`. **`saleAmount` returns `null`, not `0`.** Action rules:
  `canFulfil`, `canApprove` (at `verifying` **and** has a `conversation`). `unseen`: a channel sale this person
  has not opened (kept by `moved`, cleared by `opened`).
- `sale_detail_service.dart` — `SaleDetailService`: `GET /sales/detail/$reference` (ticket code,
  row id or chat all resolve). **Created per opened panel**, never cached. `missing` =
  `sale_not_found` (news, not an error).
- `sale_detail_model.dart` — `SaleDetailModel` + `SalePaymentModel`, `SaleProofModel`,
  `SaleHandoverModel`, `SaleOriginModel`, `SaleItemModel` (a dish's `omitted` names and `modifiers`: `SaleItemModifier`), `SaleTaxModel`, `SaleHoldModel`,
  `SaleReceiptModel` (`payment.received`: each approval), `SaleDueModel`/`SaleDueLine` (`due`: charged apart from the total),
  `saleFields(map)`. `payment.proofs` (oldest first) is parsed; `proof` is its last entry.
  `payment.hasBalance`: credit, or `collected`/`outstanding` present (a channel ticket paid in parts).
  `SaleProofModel` kind comes from the **file** (`isImage`/`isFile`/`isLostImage`), not `kind`.
  Meaningful nulls: `reservations` null on a ticket vs `[]`; `handover` null = nothing to hand
  over. `SaleItemModel.isUnheld`.
- `sale_stage_model.dart` — `SaleStage`, `SaleHandoverMode`, `SaleHandoverState`, `SaleStagesCatalog`.
- `sale_channel_model.dart` — `SaleChannel` (from `GET /pos/methods`).
- `sale_progress_model.dart` — `sale/progress` notice; every field always travels; null `section` =
  left both lists (`isGone`); label arrives as `name`.
- `sale_fulfillment_request.dart` — `fulfilSaleRequest(...)`: sets `MODE`/`STATE`, never a stage;
  send only what **changed** (re-sending the mode resets its state).
- `sale_approval_request.dart` — `approveSaleRequest(id:, amount?, currency?)`, `kSaleApprovedStage = "paid"`:
  `PUT /chats/stage` body; `id` is the conversation; `AMOUNT` only for a short payment, `CURRENCY` only with it.

## chats/ — owned by the messages section

`/aries/v1` via the `aries` client. Contract: `E:/andromeda/backend/projects/lyra/docs/guides/aries-chat-desk.md`.

- `chats_service.dart` — `ChatsService` (+ `ChatsStatus`, `ChatsFilter`): inbox `GET /chats` (filters, `SEARCH`,
  paging), `summary`, `stages`, `tags` (catalog → `tagOf(code)`), `team`, `selected`. Applies
  `chat/message|handover|stage|tags|attention|attended` to held rows; unknown/new chat → debounced page-1 reread (only on page 1, else `pending`). Notifies
  (`FloatFlag`) on `chat/attention|alert|assigned`. `moved(from, to)` after a send opened a new session.
  `unseen`: an inbound `chat/message` sets it on every row but `selected`; `select` and `badges/opened` clear it.
  Seams `seed`/`seedTags`/`receive`.
- `chat_thread_service.dart` — `ChatThreadService` (+ `ChatThreadStatus`): one open chat, **created per
  panel**. `detail/:ID` + `messages/:ID` (`BEFORE`, `ALL`), `send` (returns the landing chat id),
  `pause` `resume` `assign` (`assignable`: `GET /team?ID=`, who may take this chat by its branch) `setStage` `resolve` `markRead`, `refreshDetail` (the AI spend has no event); reports the chat
  opened (`BadgesService.opened`) after `load` and on every inbound message while open; patches the inbox row after its writes and
  its tags after each detail read; `chat/tags` replaces the detail's tags.
  Messages deduped by id; ticks never go backwards; `rekeyed` renames. Seams `seed`/`receive`.
- `chat_model.dart` — `ChatModel` (row, tag codes, `unseen`), `ChatsPage`, `ChatStage`, `ChatTag` (catalog, detail, event), `ChatLevel`, `ChatWaiting`, `ChatBot`
  (`isPausedAt`), `ChatPerson`, `ChatLine`, `ChatSummary` (`awaiting` null ≠ 0), `ChatStageOption`,
  `chatText`/`chatInt`/`chatDouble`/`chatDate`/`chatCodes`/`chatEvent`.
- `chat_message_model.dart` — `ChatMessage` (`queued` local), `ChatMessagesPage`, `ChatAuthorKind`, `ChatMessageStatus`.
- `chat_detail_model.dart` — `ChatDetailModel` (full `tags`), `ChatAttention` (`also`), `ChatPayment`, `ChatCartItem`, `ChatUsage` (`usage`: null = unreadable ≠ zero), `ChatUsageArea`.
- `chat_request.dart` — send, pause, id-only (resume/read), assign (`USERNAME` always travels),
  stage (`null` undoes; `AMOUNT`/`CURRENCY` for a short `paid`), resolve bodies; `kChatStagePaid` (approve),
  `kChatStageSold` (close), `kChatStageEnded`.
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

`/init/` · `/badges/{,seen/}` · `/profile/employments/` · `/authentication/two_factor/{,app,email,code,recovery,verify}/` · `/authentication/email/sign_up/password/` · `/permissions/requests/` · `/authentication/email/{verify,sign_in/password,sign_in/code,sign_up/code,sign_up/names}/` · `/authentication/logout/` · `/business/{create,profile,logo,emails,emails/verify,payments}/`
`/business/employees/{,former/,detail/$id}`
`/business/location/{,search,place}/` · `/business/delivery/{,options,providers}/`
`/channels/{,providers/,detail/$id}` · `/connections/{,providers/,detail/$id}` · `/knowledge/{,products/}`
`/inventory/products/builder/{list,structure,details,fields,normalize}/` ·
`/inventory/products/records/{list,manage,images}/` · `/inventory/products/import/{structure,records}/$format/` ·
`/inventory/products/import/images/{status,claim,deliver,fail,match,retry}/` ·
`/inventory/stock/summary/` · `/inventory/stock/movements` · `/inventory/stock/transfers{,/receive,/search}` · `/inventory/products/prices`
`/inventory/recipes{,/$id,/availability,/pause,/uses,/produce,/discard,/consumption,/variance,/cost}` · `/inventory/modifiers{,/availability}` · `/inventory/presentations{,/$id}`
`/sales/` · `/sales/stages/` · `/sales/detail/$id` · `/sales/fulfillment/` · `/chats/stage/`
`/pos/` · `/pos/catalog/` · `/pos/methods/` · `/pos/invoices/{,items,close,cancel}`
`/aries/v1/chats{,/stages,/tags,/summary,/detail/$id,/messages/$id,/messages,/read,/bot/pause,/bot/resume,/assign,/stage,/alerts/resolve}` · `/aries/v1/team{,?ID=}`
`/scorpius/v1/tilesets` · `/scorpius/v1/raster/$name/$style/{z}/{x}/{y}{r}.png` · (no client yet) `/scorpius/v1/{route,matrix,isochrone,coverage}`
`/money/` · `/money/summary/` · `/money/ai/` · `/money/catalog/` · `/money/methods/` ·
`/money/payments/{,search,void}/` · `/money/receivables/`
