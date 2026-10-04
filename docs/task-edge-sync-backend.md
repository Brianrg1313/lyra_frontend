# Task: edge sync with a company's master (backend side)

**Scope** Backend (`E:/andromeda/backend/projects/lyra` and its `core` package): a new, small API
for masters (`/edge/v1`), an edge-device credential, the id map, the allowance, and the cloud grant.
**Origin** `docs/plan-offline-lan.md` §9 (phase 6) and decisions D10, D11, D14, D15, D18, D19. A master is
the desktop install that holds one company's site offline (`lyra_node`, the engine). Once it is
linked to its cloud company, the two hold the same data, kept equal by this sync.
**Built on the backend** (2026-10-04, `lib/models/edge/MODULE.md` there, not deployed): §1, §2, `/status`;
`/commands` applying `account` and parking every other entity (accepted, ids mapped, kept in order for
when it is served); `/changes` and `/snapshot` with `member`; the allowance always `within`. Not yet:
the other entities, §9, §12. Checked with the engine against the dev backend: the first link, a
permission changed in the cloud reaching the master, access taken away, revoking, replay, a forged
signature, a clock off.
**Frontend side** The engine syncs by itself over HTTPS (the app may be closed). The app enrols it
and asks for grants with the person's cloud session. The engine is tested against an in-memory
copy of this contract (`lyra_node/test/support/edge_cloud.dart`), which is the reference when this
text is unclear.

## Words

- **Master**: one engine install, one company, one site (plan D6, D11). Identified by its
  `instance` (UUIDv7, never changes).
- **Edge device**: the backend's record of an enrolled master: its id, company, site, public key,
  revoked or not.
- **Local id**: an id the master made (UUIDv7). On the wire it is written `m:<uuid>`.
- **Cloud id**: an id the backend made, written as the backend writes it (no prefix).
- **HLC**: a hybrid logical clock stamp, `<15-digit millis>:<5-digit counter>:<node>`, fixed width,
  so comparing the strings compares the stamps. The master's node is its `instance`; the backend's is
  `cloud`.

## 1. Enrolment (user session)

The app calls these with the signed-in person's normal session (`Authorization`, `business_id`).
Only the company's owner (`all`) may enrol or revoke.

`POST /edge/v1/devices` (the backend's convention: a client's keys are UPPERCASE)
```json
{ "INSTANCE": "0192…", "NAME": "Front desk PC", "PUBLIC_KEY": "<base64, 32 bytes Ed25519>", "ENGINE_VERSION": "0.1.0" }
```
- The company is the request's `business_id`; it must be the one the master is linked to
  (`company.cloud_id` on the master, set by `business.link`).
- The site is the company's main site unless the body names `SITE` (D11: one master per site). A site
  that already has a live edge device: `409` with `action: "site_has_master"` (the API's error shape). The same `instance` enrolling
  again replaces its key and revokes the old one: that is how a reinstalled master comes back.
- Answer, in these keys (the app hands it to the engine as is):
```json
{
  "device": "<edge device id>",
  "company": "<cloud company id>",
  "site": "<cloud site id>",
  "edgeKey": { "kid": "2026-10", "publicKey": "<base64, 32 bytes Ed25519>" },
  "allowance": "within" | "subscribed" | "exceeded",
  "endpoint": "https://api…/edge/v1"
}
```
`edgeKey` is the backend's signing key for grants (§8); the master pins it. `endpoint` lets one
backend move the edge API elsewhere later.

`DELETE /edge/v1/devices/:id`: revokes it. Its next call gets `401 {code: "edge_revoked"}` and the
master stops syncing.

`GET /edge/v1/devices`: the company's edge devices, `{keys, values}` as the API's lists
(`id name site instance engine_version revoked last_seen date`), for a future settings screen. These
three need the `server` permission; enrolling and revoking, `all` too.

## 2. Authentication of a master (every other `/edge/v1` call)

No token. Every request is signed with the master's Ed25519 private key:

```
Edge-Device:    <edge device id>
Edge-Time:      <unix millis>
Edge-Nonce:     <16 random bytes, base64url>
Edge-Signature: <base64 Ed25519 signature of the string below>

<METHOD>\n<path with query, exactly as sent>\n<Edge-Time>\n<Edge-Nonce>\n<sha256 hex of the raw body, empty body = sha256 of "">
```

Refuse with `401` and a `code`: unknown device (`edge_unknown`), revoked (`edge_revoked`), bad
signature (`edge_signature`), time more than 5 minutes off (`edge_clock`, with `now` in millis so the
master can tell its clock is wrong), a nonce seen from that device in the last 10 minutes
(`edge_replay`). Update the device's "last seen".

## 3. The allowance (D15)

Within the free allowance or with a subscription, the company's data lives in the cloud and on its
master. Past the allowance without a subscription it lives on the master only; the cloud keeps
serving sign in, the account and the link. The allowance and how it is measured are the backend's to
decide (data size, rows, devices…); the master only needs the state.

- Every answer of §4 to §6 carries `"allowance": "within" | "subscribed" | "exceeded"`.
- While `exceeded`, `/commands`, `/changes` and `/snapshot` answer `402 {code: "allowance_exceeded"}`
  and change nothing. The master pauses and asks `GET /edge/v1/status` (always served:
  `{allowance, device, company, site}`) every hour; it resumes from its cursors, nothing is lost.
- Signing in, the account and the grants (§8) are served whatever the state.

## 4. Pushing: `POST /edge/v1/commands`

```json
{ "phase": "snapshot" | "live", "changes": [ <change>, … ] }
```
- At most 200 changes and 1 MB per call. Process them **in order**: a later change may refer to what
  an earlier one created (`m:` ids, §7).
- `phase: "snapshot"` is the master's whole state, sent once at the first link (a master made offline
  with data, D18): every record as `upsert`, every fact as `append`. Same rules as `live`.
- Answer, one result per change, in the same order:
```json
{
  "allowance": "within",
  "results": [
    { "commandId": "…", "status": "accepted", "cloudId": "<id it created or matched>" },
    { "commandId": "…", "status": "duplicate", "cloudId": "…" },
    { "commandId": "…", "status": "rejected", "reason": "<stable code>", "data": { } }
  ]
}
```
- `duplicate`: that `commandId` was already applied (keep them at least 90 days); answer what the
  first one answered. A network retry must never apply a change twice. An `append` of a fact the
  backend already has (the same id) is a `duplicate` too.
- `rejected`: a rule on the backend's side refuses it (an unknown reference, a value it can't store).
  The master keeps it for the owner and does not retry. Never reject for a conflict: those are
  settled by the clock (§5).
- A failure of the whole call (5xx, timeout) means nothing was applied, or it was and the retry
  comes back `duplicate`: the master retries the same batch with the same `commandId`s.

### The change

```json
{
  "commandId": "<instance>:<seq>:<n>",
  "hlc": "001727800000000:00000:<node>",
  "entity": "product",
  "id": "m:0192…" | "<cloud id>",
  "op": "upsert" | "delete" | "append" | "void",
  "fields": { "name": "…", "table": "<id or m:id>" },
  "cells": { "<field id or m:id>": "…" },
  "actor": "<e-mail of the person, or null>"
}
```
- `commandId` is opaque to the backend: the master makes it from its oplog (`<seq>`, and `<n>` when
  one local write changes several records) or, for the first upload, `<instance>:snap:<entity>:<id>`.
- `upsert` creates the record if the id is new, otherwise changes **only the fields present**.
  `fields` and `cells` (a product's values, keyed by its table's field ids) are settled per key.
- `delete` is a tombstone. `append` adds a fact (never edited after). `void` marks a fact void
  (`fields.reason`).
- `actor` lets the backend show who did it; null for the engine itself or a local account without an
  e-mail.

## 5. Conflicts: the same rule on both sides

Both sides keep, per record, **the HLC of each field** (each cell of a product too), and apply:

- A field takes an incoming value only when the incoming `hlc` is newer than the field's stamp. Equal
  or older: ignore it (still `accepted`). Both sides end with the same value without asking each
  other.
- `delete` wins over older edits. An `upsert` newer than the delete brings the record back.
- Facts never conflict (union by `commandId`). A `void` newer or older is applied once.
- Stock balances are never sent: each side computes them from the movements.
- Permissions: the cloud's word wins. They only come down (`member`, §11), never go up after the
  first link (§10); the master refuses to change them while it syncs.
- The backend keeps its own HLC per company: it stamps its own edits with it (node `cloud`), and on
  receiving a master's change it moves its clock past that stamp, so the next cloud edit sorts after
  it. A stamp more than 1 minute in the backend's future is still applied as sent: the master already
  refuses to make such stamps.

The master shows the owner a field both sides changed since its last pull (a "conflicts inbox"); the
backend does nothing special for it.

## 6. Pulling: `GET /edge/v1/changes?cursor=<opaque>&limit=500`

```json
{ "allowance": "within", "changes": [ <change>, … ], "cursor": "<opaque>", "more": false }
```
- Changes the cloud made to this company's company-wide records and to this site's records and facts
  after `cursor`, oldest first, in the shape of §4 with **cloud ids only** (an `m:` id the backend has
  mapped is answered by its cloud id) and `hlc` the stamp the field got on the backend.
- **No echo**: never answer a change this edge device pushed. Do answer changes from the app, the
  WhatsApp bot, another site's master (for company-wide records) or the web.
- `commandId` of a pulled change: the backend's own, unique; the master deduplicates by it.
- An empty or missing `cursor` means "from the moment this device was enrolled". A cursor older than
  what the backend keeps: `410 {code: "cursor_expired"}`; the master then rebuilds from `/snapshot`.

## 7. Ids

Neither side adopts the other's ids. On the wire a record is named by its cloud id once the backend
has answered one, and by `m:<local id>` before that.

- The backend keeps a map per edge device: `(device, entity, m:<local id>) → cloud id`, filled when it
  accepts a change that creates something. Any `m:` id in `id`, `fields` or `cells` keys is resolved
  through it; an `m:` id it has never seen is `rejected` with `unknown_reference`.
- The answer's `cloudId` is how the master learns it; from then on the master sends the cloud id.
- Pulled changes carry cloud ids; a cloud id the master hasn't seen is a new record there.
- The company and the site are mapped at enrolment (`company`, `site`) and never sent as `m:`.

## 8. Snapshot: `GET /edge/v1/snapshot?cursor=<opaque>&limit=500`

The cloud's whole state for this company (company-wide records) and site, paged, as `upsert` and
`append` changes. The last page carries `"done": true` and `"changes_cursor"`: where `/changes`
continues. Used for a master made from a cloud company (D16), a master rebuilt, and after
`cursor_expired`.

## 9. The cloud grant (E3, plan D14)

One session for two homes: a person signed in online on a device with a master opens their session on
the master with a statement the backend signs, checked by the master **offline**.

`POST /edge/v1/grants` (user session) `{ "device": "<edge device id>" }` → `{ "grant": "<token>" }`
- Only for an active member of the master's company.
- `token` = `base64url(payload) "." base64url(signature)`, the signature Ed25519 over the payload's
  bytes with the key whose public half is `edgeKey` (§1). Payload, UTF-8 JSON:
```json
{ "v": 1, "kid": "2026-10", "device": "<edge device id>", "company": "<cloud company id>",
  "account": { "id": "<cloud user id>", "email": "ada@…" },
  "nonce": "<16 random bytes, base64url>", "iat": 1727800000, "exp": 1727800120 }
```
- Lifetime 2 minutes. The master accepts each `nonce` once and maps the account by e-mail.
- Rotating the key: a new `kid`; the master learns new keys through `GET /edge/v1/status`
  (`edgeKeys: [{kid, publicKey}]`), signed by the transport only, so add a new key **before** using it.

## 10. Accounts at the first link (D10)

The master's local users are sent as `account` upserts in the snapshot (e-mail, names, and
`permissions`: the person's document on the master). For each one, the backend creates a cloud
account with that e-mail, as a company opens one for someone it hires (its owner claims it by signing
up with the e-mail), and adds it to the company with that document and **its access**: the people
working on the master keep working there the moment its permissions become the cloud's. A company
template's id is the master's own and is dropped (the permissions stay); a global one is kept.
- An e-mail of someone the company already has (the owner who links, someone already invited):
  `accepted` with that person's id, nothing changed — the cloud's document is the one that counts.
- Any other e-mail that has a cloud account: `rejected` `{reason: "account_exists"}`, settled by the
  company's administrator, never merged.

The answer's `cloudId` is the person's `member` id. Accounts without an e-mail are not sent; the app
asks for one before linking.

## 11. Vocabulary (first version)

Scope: **company** records are shared by every site's master; **site** ones belong to the edge
device's site. Amounts are integers in minor units of `currency`. Instants are ISO 8601 UTC; `date`
is a calendar day `YYYY-MM-DD` in the company's zone. A ref is an id of the named entity.

| entity | scope | ops | fields |
|---|---|---|---|
| `company` | company | `upsert` | `name` `legalName` `nickname` `caption` `activity` `taxId` `country` `language` `currency` `phone` `website` `incorporationDate` `timezone` |
| `site` | site | `upsert` | `name` `legalName` `taxId` `phone` `address` `landmark` `city` `region` `postalCode` `latitude` `longitude` (both in millionths of a degree, or both null) `storefront` `online` |
| `product_table` | company | `upsert` `delete` | `name` `description` `color` `primary` (at most one table: setting it takes it from the others, on each side by itself) |
| `product_field` | company | `upsert` `delete` | `table` (ref) `name` `description` `type` `position` `width` `options` `unit` `visibility` `summary`. What a field change does to others travels as changes of its own: the other fields' `position`, and each product's cell after a new `type` |
| `product` | company | `upsert` `delete` | `table` (ref); `cells` keyed by `product_field` |
| `stock_movement` | site | `append` | `product` `table` (refs) `operation` `reason` `quantity` `note` `source` `invoice` (ref, null) `at` |
| `payment` | site | `append` `void` | `concept` `direction` `amount` `currency` `method` `reference` `counterpart` `ticket` (ref, null) `note` `date` `at`; `void`: `reason` `at` |
| `currency` | company | `upsert` | id = ISO code; `mode` (`official` / `custom`) `custom` (rate, `1 main = rate`) `active` |
| `account` | company | `upsert` | snapshot only, §10: `email` `firstName` `lastName` `permissions` (`{access, all, sections, template: {scope, id} \| null}`, the shape of `member`) |
| `member` | company | `upsert` `delete` | **pulled only**, never pushed. id = the person's cloud account id (the `account`'s cloud id once mapped). `email` (how the master finds a person it hasn't mapped) `access` `all` `sections` (`{<section>: {access, <action>: bool}}`, the permissions catalog's keys) `template` (`{scope: "global" \| "company", id}` or null) `custom`. One per member of the company, the owner included, and per person with an active job and no access yet (`access` false). Sent whole on any change to a person's permissions or access. `delete` = out of the company |

The rules behind each field are the specs in `lyra/app/docs/offline/specs/` (`business.md`,
`inventory.md`, `stock.md`, `money.md`). Next versions add: POS tickets and their lines, the
handover, employees, clients, deliveries, files (logo, product images).

## 12. Where a browser finds the master (plan §9.7, D19)

The cloud's web app can't discover a master on the LAN; it tries the name and addresses the master
reported, and accepts the answer only when the master's `instance` matches the one given here.

`PUT /edge/v1/lan` (master, signed as §2)
```json
{ "instance": "0192…", "host": "ryzer-llc.local", "port": 4780, "addresses": ["192.168.1.20"] }
```
- Sent after enrolment and whenever the master's name or addresses change (the name can become
  `ryzer-llc-2.local` after a conflict on its LAN). Replaces the previous one; `204`. `host` is null
  before the master's company exists. `instance` must be the enrolled one (`409 {code: "edge_instance"}`).

`GET /edge/v1/devices` (user session, §1) adds, per live device, `instance`, `host`, `port`,
`addresses` and `lanAt` (when they were reported), and answers to **any active member** of the
company, not only the owner: these fields only, for members; the full row stays the owner's.

## 13. Open questions for the backend

1. **Matching on the first link.** A master made offline and a cloud company that already has data:
   the master's records are added to the cloud's. Should the backend match the same product (SKU,
   then name) or currency instead of creating a duplicate? If it matches, `accepted` with the
   existing `cloudId` is all the master needs.
2. **Sealed fields** (plan §6.3): a person's pay, identity documents, payment accounts. The master
   can't open them without a holder signed in, so they don't travel yet. Proposal: sealed to a key the
   backend holds per company, opened only by the backend's own code.
3. **The allowance's measure** and what the person sees when it is exceeded.
4. How long a cancelled company's data stays readable for a site to pull it (plan §9.4).

## Done when

- A master enrolls, pushes its snapshot, and its data shows in the cloud app.
- A product edited in the cloud app shows on the master within one sync cycle; one edited on the master
  shows in the cloud app; the same field edited on both while the master is offline ends equal on
  both sides (the newer stamp).
- A batch retried after a timeout applies nothing twice.
- A revoked device gets `401 edge_revoked`; past the allowance the edge calls answer `402` and resume
  afterwards without losing a change.
- A grant made for one master is refused by another master, after its expiry, and the second time.
- A person's permissions changed in the cloud app reach the master within one sync cycle (`member`),
  and the people a master uploads at the first link keep the permissions they had there. **Seen on the
  dev backend (2026-10-04)**, the cloud side played by its models.
- A master's reported `host` shows in `GET /edge/v1/devices` for a member, and a new report replaces it.
