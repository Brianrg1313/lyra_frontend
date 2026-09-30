# Offline / LAN: phase 0 specs

**Status** Draft for review, 2026-09-30. Phase 0 of `docs/plan-offline-lan.md` (§11).
**Owner of the rules** These specs, not the backend. Where the cloud behaves differently, the
contract tests of phase 4 (§7.6 of the plan) show it, and the difference is settled here: either
the spec changes, or the difference is accepted and written down under "Differences from cloud".

The engine (`lyra_node`) is written from these files. They describe **what the app shows and
what the product decides**, taken from `lib/services/**` (models, requests and the `///` notes
on them) and from `docs/app-areas.json`. They never describe how the backend stores or routes
anything (plan principle 1). Nobody writing the engine needs to open `backend/`.

## Files

| File | What it fixes |
|---|---|
| `protocol-v1.md` | Transport, frames, handshake, sessions, errors, events, paging, files, op catalogue |
| `specs/session.md` | Local accounts, sign in, devices, the bootstrap answer (`/init` today), permissions and permission requests |
| `specs/business.md` | The company, its site, logo, settings, bundled catalogues and vocabularies |
| `specs/inventory.md` | Tables, fields, records, images, import, search |
| `specs/stock.md` | The ledger: counters, movements, reasons, holds, summary |
| `specs/pos.md` | The counter: catalogue, open ticket, lines, holds, checkout, cancel, recovery, outbox |
| `specs/sales.md` | The sales board: rows measured from tickets, stages, handover, detail |
| `specs/money.md` | Payments, summaries, receivables, payment accounts, currencies, accounting export |
| `specs/employees.md` | Staff lists, detail, local invitation, edits, sealed fields |
| `specs/deliveries.md` | Delivery settings, options, areas |

Areas with no spec, and why:

| Area | Why |
|---|---|
| `business.clients`, `business.statistics` | Placeholders in the app today (`SectionMessage` "coming soon"). They get a spec in the same change that builds them in the cloud (plan principle 9). |
| `business.branches` | One site per master (plan D6). The site is `business.site` in `specs/business.md`. |
| messages, channels, connections, Baileys, maps tiles/isochrone, money AI, business e-mails | Cloud only (plan §2). No op exists for them. |
| `deliveries.*`, `finance.receivables` | Specified for `hybrid`, **hidden in `local`**: nothing reads deliveries offline, and credit sales are deferred (decided 2026-09-30). |

## Conventions every spec follows

**Identity**
- Every record has an `id`, a UUIDv7 string minted by the engine (or by a POS outbox for the
  documents it creates, §8.4 of the plan). Ids are opaque to the app, which already treats every
  id as a string.
- Human codes (ticket codes, employee codes) are separate fields, never ids.

**Money**
- Stored and sent as **integers in minor units** plus an ISO 4217 code, never as floating point.
  The number of minor digits comes from the currency catalogue (`CurrencyModel.decimals`).
- The `XLanSource` converts to the `double`s the current models hold, so models and screens do
  not change (plan principle 8).
- Rounding: half away from zero, applied **once per line** and never on a sum. A total is always
  the sum of already rounded parts, so the parts on a receipt add up to the total printed under
  them.
- Percentages (tax, fees) travel as decimal strings in percent (`"16"`, `"7.5"`), never `0.16`,
  matching the app (`PosInvoiceService.maxTax`).
- Every amount the engine answers is computed by the engine. **No op accepts a total from a
  client**, only prices on typed-in lines and payment amounts.

**Time**
- Instants are ISO 8601 UTC strings on the wire, as the app reads them today.
- The company has a **time zone** (`business.settings.timezone`, IANA name, nullable: `null` is the
  country's default zone, `business.md` B-9). "Today", "this month" and every day boundary are computed in that zone, on
  the master's clock (so the POS and the finance screen agree, as they do today).
- Calendar days with no time (birthdays, contract dates, leaves) travel as `YYYY-MM-DD` and are
  never shifted by a time zone (`employeeDay` in the app).

**Absence**
- `null` means "not known / not applicable" and is never folded into `0` or `""`. The app relies
  on that everywhere: a price that is `null` is asked for, a sale total that is `null` is a sale
  not priced yet, a salary that is `null` is not a salary of zero.
- On an edit, **a missing key is "leave it", `null` is "clear it"**. Every edit op in these specs
  follows that rule unless its section says otherwise.

**Lists**
- Paged lists answer `{items, page, size, total}` (page based) or `{items, cursor, more}`
  (cursor based), as named in each op. `total` counts the whole filter, not the page.
- Every list has a fixed, total order (a sort key plus `id`), so paging never repeats or skips.
- Text search: case-insensitive and accent-insensitive ("cafe" finds "Café"), substring match on
  the fields each op names. There is no semantic search offline (the cloud's embeddings are out
  of scope).

**Vocabularies**
- Closed lists the app already reads from the server (payment concepts, settlement kinds,
  stock reasons, sale stages, handover modes, payment rails, banks, document types, delivery
  providers, countries, currencies, phone plans) are **product data, not backend design**. The
  release build snapshots them into `Catalogs` in `lyra_protocol` (plan §7.5). The engine serves that
  snapshot, and in hybrid refreshes it from the cloud.
- An engine rule that depends on a code (for example "the concept `settlement` pays a credit
  ticket down") reads the **flag** the vocabulary carries (`settles: true`), never the code, so a
  new code with the same flag works without an engine release.

**Writes**
- Every write carries a `commandId` (UUIDv7, minted by the client). Sending the same `commandId`
  again returns the first answer and does nothing twice. That is what makes a retry after a
  dropped connection, and the POS outbox replay, safe.
- Every write is authorised on the master against the permission ids of `docs/app-areas.json`
  (plan §5.4). Each op lists the id it needs.
- Every committed write appends to the oplog and emits the events its section lists.
- Deletes are soft unless a section says otherwise: the row gets a tombstone and stops being
  listed, and whatever referenced it keeps reading it.

**Errors**
- Every refusal has a stable `code` (snake case) that the engine never renames, a `message` in
  the company language, and optionally an `action` (see `protocol-v1.md`). The codes each op can
  answer are listed in its spec.

## How a spec is written

```
## <domain>.<thing>

What it is, in two lines.

### Data            fields, types, nullability, who writes each one
### Rules           numbered, testable, one fact each
### Ops             op name · permission · args · answer · errors · events
### Events          name · when · payload
### Differences from cloud   what behaves differently offline, and why
### Open questions  numbered, answered in review
```

Rules are numbered (`POS-7`) so the contract tests can name the rule they check.

## Review checklist (exit criterion of phase 0)

- [x] Every open question answered or moved to the plan's risks. Still open by decision: tax
  (`pos.md` Open question 2) and credit (`money.md`), deferred by the product owner; the two
  delivery questions, which only matter in `hybrid` (phase 6).
- [ ] Every service in `lib/services` that has a local mode maps to ops in a spec (table below).
- [x] The protocol draft is agreed and `lyra_protocol` matches it (`test/protocol_catalogue_test.dart`).
- [ ] The EULA text is drafted by a lawyer (outside these files).

## Service → spec map

| App service (`lib/services`) | Spec | Ops prefix |
|---|---|---|
| `client/client_service.dart` (`/init`, sign out, accept invitation) | session | `session.*`, `account.*` |
| `sign_in/`, `sign_up/` | session | `auth.*` |
| `permissions/*` | session | `permissions.*` |
| `business/business_service.dart` (profile, logo) | business | `business.*` |
| `business/business_location_service.dart`, `business_branches_service.dart` | business (`business.site`) | `business.site.*` |
| `catalog/*`, `files/cdn_service.dart` | business (catalogues) | `catalog.*` |
| `business/business_employees_service.dart` | employees | `employees.*`, `profile.*` |
| `business/business_delivery_service.dart`, `delivery_areas_service.dart` | deliveries | `delivery.*` |
| `stock/tables/*`, `inventory/*` | inventory | `inventory.*` |
| `stock/summary/*`, `stock/movements/*` | stock | `stock.*` |
| `pos/*` | pos | `pos.*` |
| `sales/*` | sales | `sales.*` |
| `money/*` (except `money_bot_service.dart`) | money | `money.*`, `export.*` |
| `connection/connection_service.dart` | protocol (events) | `events.*` |
| `chats/`, `channels/`, `connections/`, `baileys/`, `maps/`, `money_bot_service.dart`, `business_places_service.dart`, business e-mails | none | cloud only |
