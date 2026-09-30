# Plan: offline / LAN mode (local master)

**Status** Proposal, 2026-09-30. Product decisions settled the same day (§13). Phase 0 in
review: specs and protocol draft in `docs/offline/` (open questions listed there). Nothing built yet.
**Scope** This app (`lyra/app`), `core`, two new Dart packages, and, for the hybrid phase only,
a narrow new API on the backend (`backend/projects/lyra`).
**Goal** The app works without the cloud. One desktop install (Windows, macOS or Linux) is the
**master**: it stores the data of **one company at one site**, encrypted, and serves it over the
LAN. Every other install (desktop, web, Android, iOS, POS) is a **client** of that master. Only
features that really need the internet (WhatsApp, AI, e-mail, maps and place search) are left
out.

Three customer profiles drive the design:

| Profile | Mode | Cloud cost to us | Source of truth |
|---|---|---|---|
| Doesn't want our cloud at all | `local` | zero | the master |
| Wants no dependence on the internet | `local` | zero | the master |
| Uses the cloud but often loses the connection | `hybrid` | today's cost | cloud plus master, reconciled by sync |

`cloud` (today's app, no master) stays the default and does not change.

---

## 1. Principles (non-negotiable)

1. **Not the backend's architecture.** The master is a new implementation, written from the
   product behaviour the app shows, never ported from `backend/projects/lyra`. It uses its own
   storage (one encrypted SQLite file plus an operation log, not MySQL plus Mongo), its own
   protocol (versioned RPC over one WebSocket, not the REST paths), and its own ids (UUIDv7).
   No backend endpoint names, table names, AI prompts or routing rules go into it. In hybrid,
   the backend translates its model to a small **edge contract** (§9), so the master never
   learns how the backend stores anything.
2. **Encrypted at rest and in transit, with no exceptions.** A copied database file, backup or
   client cache is useless without its keys. Nothing travels on the LAN in the clear, and no
   connection is accepted unless the other side's identity has been verified (§5.3). Salaries
   and personal data get a second layer (§6.3).
3. **One company, one site.** A master holds exactly one company and one site (the current
   one). There is no business selector and no list of branches in `local` mode (D6).
4. **One writer.** Only the master writes the company's data. Clients send commands and do not
   replicate the database. That rules out split-brain inside a LAN. The one exception is the
   POS outbox (§8.4), and it is append-only.
5. **The master is chosen, never elected.** The admin designates it. Moving it is an explicit,
   guided operation (§10.3).
6. **Not fiscal software.** Lyra records sales and payments and hands that data to other
   systems. It never issues fiscal documents, so it never needs a tax authority's
   certification. Tickets and receipts say so, and accounting data leaves through exports (§8.5) (D1).
7. **Free, proprietary software.** Anyone may use `local` mode at no cost. Nobody may sell,
   modify, redistribute or reverse-engineer it. That is enforced by a licence agreement,
   accepted on first run, backed by signed and obfuscated builds (§10.5). There is no
   activation, licence key or device limit (D2).
8. **Screens don't know the mode.** Mode only reaches the data-source layer and a capability
   gate (§7.3). Widgets, `S`, `FloatFlag` errors and models stay as they are.
9. **Every feature declares its modes.** A new feature says whether it is `cloud-only`, or
   `local` too, in the same change that adds it (§12). Otherwise local mode silently falls behind.

---

## 2. Feature availability

| Area (`docs/app-areas.json`) | `local` | `hybrid`, internet down | Notes |
|---|---|---|---|
| Sign in / accounts | local accounts | cached verifier on master | §6.4. No e-mail codes offline. |
| Business profile, logo, settings | yes | yes | Logo in the encrypted file store. |
| Branches | the site only | the master's site only | The site is edited as the business location. No list, no creation. Manual lat/lng; no place search. |
| Employees, contracts, leaves, salaries | yes | the site's staff | Sealed fields (§6.3). Invitations: the owner creates the local user directly. |
| Clients | follows the cloud | follows the cloud | A placeholder in the app today; specified when it is built (principle 9). |
| Statistics | follows the cloud | follows the cloud | Same. The master will compute them from its own data. |
| Inventory tables, records, images | yes | yes | Plain CSV/XLSX import. No AI normalisation or embeddings. |
| Stock, movements, summary | yes | the site's stock | Stock is stored as deltas (§9.3). |
| POS | yes | yes | Can keep selling when the master is unreachable (§8.4). |
| Receipts / tickets | non-fiscal | non-fiscal | Principle 6. |
| Accounting export | yes | yes | §8.5. |
| Sales board (in person) | yes | yes | |
| Sales from WhatsApp or AI | — | queued in the cloud | Pulled down when back online. |
| Finance: overview, payments, methods | yes | yes | |
| Finance: receivables (credit sales) | — | yes | Credit as a payment option is still being researched; hidden in `local` until decided (`docs/offline/specs/money.md`). |
| Currencies: official rates | last known | last known | Custom rates work as today. |
| Money AI (`/money/ai`) | — | — | Cloud only. |
| Messages (aries), channels, connections, Baileys | — | — | Cloud only. |
| Deliveries: settings, areas | — | yes | Hidden in `local`: only AI channels read them today. In hybrid they are kept and edited on the master (`docs/offline/specs/deliveries.md`). |
| Deliveries: map tiles, isochrone, route | — | — | Cloud only. An offline tile pack is future work (§14). |
| Business e-mails, verification | — | — | Cloud only. |
| Permission requests | yes | yes | Handled by the local owner or admin. |

A cloud-only area in `local` mode is **hidden** (it isn't part of the product there). In
`hybrid` with the internet down it is **shown with `SectionMessage`** ("needs internet").

---

## 3. Topology and lifecycle

```
                ┌───────────────────────────── LAN ──────────────────────────────┐
                │                                                                  │
  [cloud] ◀──(hybrid only: edge sync, §9)──▶  MASTER (Win/macOS/Linux desktop)     │
                │                            ├─ Lyra app (UI process)               │
                │                            │     starts / attaches to ↓           │
                │                            └─ lyra_node (background process)      │
                │                                  TLS only, :4780                   │
                │                                  ├─ encrypted SQLite + oplog      │
                │                                  ├─ encrypted file store          │
                │                                  └─ serves the web build          │
                │          ▲            ▲             ▲              ▲              │
                │   desktop client  POS client   Android/iOS     browser (web)      │
                └──────────────────────────────────────────────────────────────────┘
```

**Engine lifecycle (D4).**
- The engine is its own executable, `lyra_node`, shipped with the desktop app. It is not an
  isolate of the app: an isolate would die with the window.
- **Opening the app on the master starts the engine**, or attaches to the one already running.
- **Closing the app leaves the engine running** in the background, detached, so clients keep
  working.
- **The engine never starts by itself.** There is no OS service, no auto-start at boot or login,
  and no scheduled task. After a reboot, the server is down until someone opens the app on the
  master.
- The engine runs as the signed-in OS user, so the user-scope OS vault (DPAPI, Keychain,
  libsecret) is available (§6.2). Signing out of the OS or shutting down ends it, and clients
  see "server unavailable" (and the POS outbox takes over, §8.4).
- The app talks to its own engine like any client: over TLS, with the master's own device
  certificate, which is enrolled at setup. On attach, the app checks that the running process
  is our engine (the certificate plus a local control secret kept in the vault) before trusting
  it. The same pattern as `BaileysLauncher` / `CONTROL_API_KEY` today.
- "Stop server" in the admin screen shuts it down cleanly, after a warning that lists connected
  devices.
- Single instance: a lock file in the data folder stops a second engine from opening the DB.

**Other rules.**
- **Clients** = any build (desktop, web, mobile), paired with the master (§5.3). Web and mobile
  can never be master: `DeploymentRole.master` is compiled out when `kIsWeb` or on
  Android/iOS.
- **Web in LAN mode is served by the master itself** (`https://<master>:4780/`). A page
  loaded from our cloud over HTTPS can't call an HTTP LAN address (mixed content, Private
  Network Access), and serving it locally also works with no internet at all. Web has an extra
  trust requirement (§5.3).
- **One master = one company, one site** (principle 3). In hybrid, each site that wants offline
  resilience has its own master, which only holds its site's data (§9.1).

---

## 4. Code layout

| Unit | Path | Content |
|---|---|---|
| `lyra_protocol` (new repo, pure Dart) | `E:/andromeda/frontend/packages/lyra_protocol` | Op names, request/response and event DTOs, error codes, `protocolVersion`. Shared by the app and the engine. |
| `lyra_node` (new repo, pure Dart, no Flutter) | `E:/andromeda/frontend/packages/lyra_node` | The engine: storage, crypto, domain, oplog, network, backup, sync. `bin/lyra_node.dart` = the background executable (§3). |
| app: sources | `lib/services/<domain>/sources/` | `XSource` interface, `XCloudSource` (today's REST calls moved here), `XLanSource` (protocol client). |
| app: mode and gateway | `lib/toolkit/deployment.dart`, `lib/toolkit/lan.dart` | `DeploymentMode {cloud, local, hybrid}`, `DeploymentRole {master, client}`, the LAN client (RPC plus events), capability table. |
| app: engine launcher | `lib/services/local_server/` | `LocalServerService`: start, attach, verify, stop, status of `lyra_node` (master only). |
| app: setup screens | `lib/screens/pre_start/deployment/` | Choose mode, licence agreement, create master, pair client, unlock master, recovery key. |
| app: admin screens | `lib/screens/home/sections/business/settings/local_server/` | Devices, backups, key rotation, sync status, conflicts, stop server. |

Both packages are **their own private git repositories next to `core`** (D7). The engine is pure
Dart so that it (a) runs as a background executable, (b) is tested with `dart test` against an
in-memory DB, and (c) has no widget dependency. Each gets its own `MODULE.md` and a row in
CLAUDE.md §2 when it's created.

Proposed engine internals:

```
lyra_node/lib/src/
  storage/   db.dart (SQLCipher open, WAL, single writer), migrations/NNN_*.sql, repos/
  crypto/    keyring.dart (DEK/KEK), envelope.dart (AES-256-GCM), kdf.dart (Argon2id), sealed.dart
  domain/    identity/ business/ employees/ clients/ inventory/ stock/ pos/ sales/ money/ deliveries/
  oplog/     hlc.dart, oplog.dart (append, feed since seq), tombstones
  net/       server.dart (TLS only), tls.dart (installation CA), pairing.dart (PAKE),
             discovery.dart (mDNS), auth.dart, rpc.dart (router + authorization),
             files.dart, web_bundle.dart
  export/    accounting.dart (§8.5)
  backup/    snapshot.dart, schedule.dart, restore.dart
  sync/      (phase 6) edge_client.dart, outbound.dart, inbound.dart, conflicts.dart
  audit/     audit_log.dart (hash-chained)
  process/   lock.dart, control.dart (app ↔ engine attach and stop)
```

---

## 5. Network and protocol

### 5.1 Transport
- One port (default `4780`, configurable). It serves HTTPS for files and the web bundle, and a
  WSS endpoint `/rpc` for everything else. **TLS 1.3 only. There is no plaintext listener at
  all**, not even a redirect. HSTS is on for the web bundle.
- RPC frame: `{id, op, args}` → `{id, ok: true, data}` | `{id, ok: false, error: {code, message, action}}`.
  `error` already has the shape the api layer normalises to (`{message, action}`), so
  `FloatFlag.showFromError` and `onSessionRejected` (`action: "login"`) work unchanged.
- Op names are domain verbs (`pos.ticket.addLine`, `stock.move`, `employees.update`) listed
  in `lyra_protocol`. They are deliberately not the backend's paths.
- Events: `{event, seq, data}`. Clients subscribe with `since: <lastSeq>` and replay what they
  missed after a reconnect. This replaces socket.io for local domains (`stock/changed`,
  `invoice/*`, `sale/progress`, `table/*`), and the app maps each event onto the same models
  it uses today.
- Files: `GET /f/<fileId>` with the session header, range support. The engine decrypts and
  streams them over TLS. Uploads: `PUT /f` (multipart), which returns a `fileId`.
- `hello` handshake: protocol version, engine version, required minimum client version. A
  client that is too old or too new gets a clear "update" answer instead of undefined errors.

### 5.2 Discovery
- mDNS / DNS-SD `_lyra._tcp` advertises only a random instance id and the port. Nothing about the
  company is in the advertisement.
- Fallbacks: a typed IP or host, or the QR from pairing, which lists every master address.
- Discovery is only a hint. Trust comes from pairing (§5.3), so a spoofed advertisement at most
  gets a refused connection.

### 5.3 Trust: nobody on the LAN can read or intercept traffic (D3)

Encryption alone isn't enough. An attacker on the LAN could also stand *in the middle*, with
their own certificate, and decrypt everything. So a connection is only accepted when **both
sides have verified each other's identity** through a channel the attacker can't touch. Wi-Fi
encryption (WPA2/3) is not counted on, because anyone with the Wi-Fi password is already inside.

**Installation CA.** On setup the master creates its own certificate authority and a server
certificate for its IPs and hostname. The CA's private key stays in the encrypted keyring. The
CA carries **X.509 Name Constraints**: it can only vouch for the master's own addresses, never
for any other site. So installing it on a computer can't be abused to intercept that computer's
other traffic.

**Native clients (desktop, Android, iOS): the recommended way to use the LAN.**
- An admin, signed in on the master, opens "Add device". The master shows a QR and an 8-digit
  code, valid for 5 minutes and one use only.
- **QR**: it holds `{addresses, port, instanceId, caFingerprint, pairingToken}`. The camera sees
  the master's screen directly, so the fingerprint can't be swapped on the way.
- **Code**, when there's no camera: the code isn't sent. It is the shared secret of a PAKE
  exchange (SPAKE2 / CPace). That proves to both sides that no one else is in the middle, and
  it delivers the CA fingerprint authenticated. A wrong guess ends the attempt, and three
  failures void the code.
- The client creates its own keypair and gets a **device certificate** signed by the
  installation CA. After that, every connection is **mutual TLS** with the CA **pinned**: the
  client only accepts the master, and the master only accepts paired devices.

**Web browsers.** A browser can't pin a certificate or do mutual TLS reliably, and "click
through the warning" is exactly the hole described above. So option (a) is **rejected**, and web
in LAN mode **only works on a computer where the installation CA is installed**:
- If a native Lyra client is already paired on that computer, it offers to install the CA in
  the OS trust store. The pinned channel already verified it.
- Otherwise, the admin exports the CA to a USB drive from the master's admin screen and installs
  it on the other computer.
- As a last resort it can be downloaded, but the OS install dialog shows the fingerprint, and
  the setup guide requires checking it against the one on the master's screen.
- Without the CA, the browser shows its certificate error and Lyra's setup guide explains why
  it must not be bypassed.
- Web sessions are also bound to the pairing: the first sign in from a browser needs a pairing
  code approved on the master, and the device appears in "Devices" like any other.

**Rejected: option (c)**, a public certificate for `<id>.lan.<our-domain>`. That name needs
internet DNS to resolve, so it fails exactly during the outages this mode exists for.

**Revocation.** "Devices" lists every paired device (name, platform, last seen, user). Revoking
one kills its sessions at once, and its certificate goes on the engine's deny list.

### 5.4 Authorization
- Every op is checked on the master against the signed-in user's permissions (the same ids as
  `docs/app-areas.json`, evaluated with the same rules as `PermissionsService`). Clients hide
  what they can't open, but the **master is the gate**. An op the user may not run fails with
  `code: forbidden`.
- Queries shape their answer by permission. For example, the employees list leaves out
  salaries unless the user has the HR permission. The data never leaves the master; it isn't
  just hidden in the UI.

---

## 6. Security

### 6.1 Threat model

| Threat | Mitigation | Remaining risk |
|---|---|---|
| Someone copies the DB file or a backup | SQLCipher AES-256 + encrypted file store + encrypted backups | none without the keys |
| Someone steals the whole master disk | KEK in the user-scope OS vault, which depends on the OS user's password. **Passphrase mode** or BitLocker/FileVault recommended. Sealed fields (§6.3). | An OS user with no password, and no disk encryption, weakens the vault. Setup warns about it. Sealed fields still hold. |
| A POS or client device is stolen | Client cache encrypted with a key **held by the master**, handed over per session. Device revocation. | Whatever is on screen while the thief holds an open session |
| Someone on the LAN sniffs traffic | TLS 1.3 only, no plaintext listener | none |
| Someone on the LAN intercepts (man-in-the-middle, rogue master) | Pinned installation CA, mutual TLS, pairing by QR or PAKE code, web only with the CA installed (§5.3) | A user who installs a fake CA without checking its fingerprint |
| An employee's client reads data beyond their role | Server-side authorization and permission-shaped queries | none known |
| Someone reverse-engineers the app to learn the backend | Independent engine and protocol (§1), obfuscated builds | The public cloud REST contract is already in any client build, as it is today. |
| Someone modifies or redistributes the software | Licence agreement, code-signed binaries, the engine checks its own signature at start (§10.5) | A determined attacker can patch a local binary; that's what the licence is for. |
| An admin or malware runs on the running master | Out of scope: keys are in memory | accepted |
| Tampering with history (sales, payments) | Hash-chained audit log, append-only facts | a determined local admin can still rebuild the chain; hybrid sync detects it |

### 6.2 Key hierarchy
```
Recovery key (24 words, shown once at setup, the owner must confirm it)
        │ wraps
        ▼
DEK  (256-bit random: SQLCipher key + file-store key derivations via HKDF)
        ▲ wrapped by
KEK  = user-scope OS vault secret  (unattended mode: default)
     | Argon2id(owner passphrase)   (passphrase mode: typed in the app when it starts the engine)
```
- The engine runs as the signed-in user (§3), so the user-scope vault (Windows DPAPI, macOS
  Keychain, Linux libsecret) is always reachable. No machine-scope or service secrets are
  needed.
- In passphrase mode the engine starts **locked**: it answers only `hello` and `unlock` until the
  app on the master sends the passphrase. Clients see "server locked" until then.
- Losing both the KEK and the recovery key means **the data is gone for good**. That is
  intended, and setup says so plainly.
- Key rotation: re-wrap the DEK (cheap). A full DEK rotation re-encrypts everything
  (`sqlcipher_export`) and is offered as a maintenance action.

### 6.3 Sealed fields (salaries and personal data)
- Salaries, personal documents, bank data of payment methods, and employees' private profile
  fields are encrypted **again** with a *sealed key* (SK).
- SK is wrapped once per user who holds the matching permission, using a key derived from that
  user's password (Argon2id). It is also wrapped by the recovery key.
- Two scopes, each with its own SK: `hr` (employees' private fields and salaries, held by
  `business.employees.view_personal`) and `payments` (account holder, document and number of
  payment methods, held by `finance.methods.view`).
- So the master can read sealed fields **only while an authorised user has a session open**.
  Someone who steals the disk and breaks the OS vault still can't read salaries.
- Granting that permission re-wraps SK for the new user, and needs a user who already holds SK.
  Revoking it deletes that user's wrap. A password reset through the recovery key re-wraps it.
- Cost: reports that need salaries while no HR user is signed in can't run. That is intended.

### 6.4 Accounts and sign in
- `local` mode: local accounts (username or e-mail plus password, Argon2id). An optional POS
  PIN for fast cashier switching lets the user into the POS only. Rate limiting and lockout
  happen on the master.
- `hybrid` mode: the normal cloud sign in while online. After each successful cloud sign in,
  the master stores an Argon2id **offline verifier** of that password, so the same person can
  sign in during an outage. The verifier lasts **30 days** after the last online sign in, and the
  owner can change that (D5).
- Sessions: short-lived access token (15 min), refreshed over the paired device channel, and
  bound to the device certificate. Signing out on a client ends the session on the master.

### 6.5 Client cache
- Clients keep only what the UI needs to redraw: preferences, last selections, and the POS
  catalogue snapshot and outbox. They do **not** mirror the database.
- That cache is a Hive box encrypted with a per-device key (`HiveAesCipher`). The key is
  wrapped by a secret the master hands over after sign in. A revoked device can't open its own
  cache.
- POS exception: the POS must open its outbox while the master is down (§8.4). So its
  outbox-and-catalogue key is also wrapped by the cashier's PIN. A stolen POS needs a valid PIN
  to read it.

### 6.6 Audit
- Append-only `audit` table, hash-chained (`h_n = H(h_{n-1} ‖ entry)`). It records sign ins,
  permission changes, device pairing and revocation, sealed-field reads, deletes, voids,
  restores, and engine start and stop. The owner can view it and export it.

---

## 7. App changes (client side)

### 7.1 The data-source seam (the biggest refactor)
There are about 110 direct `api.* / aries.* / scorpius.*` calls in 34 files under `lib/services`.
Per domain:
1. Define `XSource` (abstract, returns the **existing models**, throws the normalised error).
2. Move the current calls into `XCloudSource` unchanged. **No behaviour change**, verified by
   the existing tests.
3. Add `XLanSource` (protocol ops → models, via a `fromLocal` factory next to `fromJson`).
4. The service receives its source from `Sources.of(mode)`, one resolver in `lib/toolkit/deployment.dart`.

Order: `client` (`/init` → `session.bootstrap`), `permissions`, `business`, `catalog`, `stock`,
`inventory`, `pos`, `sales`, `money`, `business_employees`, `branches` (single site),
`clients`, `delivery`. `chats`, `channels`, `connections`, `maps`, `baileys` and places search
stay cloud-only: no source split, just the capability gate.

### 7.2 Realtime
`ConnectionService` becomes a front for two transports: socket.io (cloud) and LAN WSS (local,
hybrid). The `receive(...)` seams of the services already take decoded events, so the LAN
transport emits the same event names and payload models. `onRestored` fires after a reconnect
and replay, as it does today.

### 7.3 Capabilities
`CapabilityService`: `(mode, role, internet reachable, master reachable) → available(area)`.
It works together with `PermissionsService.canOpen` (both must allow). The home side bar, the
routes and deep links respect it. Hidden or `SectionMessage` behaviour follows §2. In `local`,
the business selector and "create business" are hidden (principle 3).

### 7.4 Boot flow
`initialValidator` reads `DeploymentMode` from preferences first:
- `cloud` → today's path, unchanged.
- `local`/`hybrid` + master → `LocalServerService` starts or attaches to `lyra_node` (§3), then
  unlocks it in passphrase mode, then sign in.
- `local`/`hybrid` + client → find the master (last address, then mDNS, then the pairing
  screen), then sign in.
A fresh install asks: "Use Lyra online / On this network (this computer is the server) / On
this network (connect to a server)". Web skips the server option. The first local setup shows
the licence agreement (principle 7), which must be accepted.

### 7.5 Catalogs
Countries, currencies and phone plans come from `/init` today. The app bundles a snapshot
(`assets/catalogs/*.json`, regenerated at release). The master serves it, and in hybrid
refreshes it from the cloud.

### 7.6 i18n, docs, tests
- Every new string in `intl_en.arb`, including the "not a fiscal document" note on receipts.
- `MODULE.md` of each touched module updated in the same change (CLAUDE.md §5).
- Tests: each service's tests run against a fake cloud source **and** an in-memory `lyra_node`
  (a contract test per domain), so both implementations are held to the same expectations.

---

## 8. The engine (master side)

### 8.1 Storage
- **One** SQLite database file with SQLCipher (principle 3). Candidates: `sqlite3` with a
  bundled SQLCipher library, shipped next to the `lyra_node` executable. Evaluate `drift` for
  typed queries and migrations.
- WAL, one writer (every command serialised), readers in parallel. That is plenty for a single
  site with dozens of clients.
- Money as integers in minor units plus a currency code, never doubles.
- Every row: `id` (UUIDv7), `created_hlc`, `updated_hlc`, `deleted` (tombstone), `origin`
  (the device).
- Migrations are numbered and forward-only, run at start inside a transaction after an
  automatic backup.

### 8.2 Oplog
Every committed command appends `{seq, hlc, entity, id, kind, payload, actor, device}` to
`oplog`. It is the event feed for clients (§5.1), the source of hybrid sync (§9), and a
readable history for support.

### 8.3 Domain rules
Each domain gets a short functional spec, `docs/offline/specs/<domain>.md`, written from the
app's behaviour and product decisions, **not from backend code**. Index, shared conventions
and the protocol draft: `docs/offline/README.md`. The minimum rules to specify:
- **POS ticket**: open on the first line, lines hold stock, close/cancel release or consume
  holds, tax rate per ticket, totals computed by the engine (the app keeps "every total is the
  server's answer").
- **Stock**: movements are the truth, and balances are a projection. Reasons match
  `StockReason`. Negative stock is allowed and flagged, never refused, when the movement came
  from an offline outbox.
- **Ticket numbering**: a per-device series (`<device>-<n>`), so offline POS devices never
  collide. It is an internal reference only, never a fiscal number (principle 6).
- **Money**: payments (record and void, where the concept decides the direction), receivables,
  summaries by range computed on the master's day, methods and currencies.
- **Sales board**: stages and fulfilment for in-person and POS sales.
- **Employees**: lists, detail, edit, own profile, sealed fields.
- **Statistics**: aggregates from the projections above.

### 8.4 POS outbox (clients working while the master is down, D8)
In the first `local` release:
- A POS client that loses the master keeps selling. It uses its cached catalogue and prices,
  and queues `{commandId, hlc, op, args}` in its encrypted outbox (§6.5).
- Only append-only ops are allowed offline: sell, record payment, cancel its own ticket.
  Catalogue and settings edits need the master.
- When the master is back, the outbox is replayed. `commandId` makes the replay idempotent.
  Resulting negative stock is flagged for review.
- UI: a persistent "offline: N sales pending" banner. The client can't sign out while the
  outbox isn't empty (warning plus an admin override).
- This matters more because the engine doesn't auto-start (§3): after a power cut, the POS
  sells until someone opens the app on the master.

### 8.5 Accounting export (principle 6)
Lyra hands data to accounting and fiscal systems instead of being one.
- Export of sales, payments, receivables and stock movements for a date range, as CSV and XLSX,
  with stable column names. Encoding and separators are chosen per locale.
- Every row carries its Lyra id, so re-exports can be matched on the other side.
- Permission `finance.export` (in `app-areas.json`). Each export is logged in
  the audit log.

---

## 9. Hybrid: edge sync with the cloud (phase 6, needs backend work)

### 9.1 Who talks to whom
- The master in `hybrid` belongs to **one site** of a cloud company. It holds that site's
  operational data (its stock, POS, tickets, payments, staff) and the company data that site
  uses (catalogue, prices, clients, payment methods, its employees).
- **Clients at that site use the master for local domains**, online or not. That gives one write
  path, so a failover mid-session never switches the source of truth. Cloud-only domains (§2)
  go straight to the cloud, as today.
- The master mirrors its oplog to the cloud and pulls cloud changes relevant to its site
  (WhatsApp sales for that site, catalogue or price edits made elsewhere).

### 9.2 Edge contract (new, small, owned by the backend)
- `POST /edge/v1/commands`: a batch of domain commands with `commandId` (idempotent),
  `hlc`, `origin`. The answer is per-command: accepted with a cloud id, or rejected with a
  reason.
- `GET /edge/v1/changes?cursor=`: changes for this company and site, in the edge vocabulary.
- `POST /edge/v1/snapshot`: first link of an existing local install (migrating local to hybrid),
  or rebuild of a master.
- Authenticated as an **edge device** of the company and site (its own credential, revocable
  from the cloud), not as a user. TLS as for any cloud call.
- The backend maps edge vocabulary ↔ its own model. The master keeps a `cloud_id ↔ local_id`
  map, so neither side adopts the other's ids.
- Handover document for the backend team: `docs/task-edge-sync-backend.md`, in the same style
  as `task-cookie-session-backend.md`.

### 9.3 Conflict policy per kind of data

| Kind | Examples | Policy |
|---|---|---|
| Append-only facts | sales, tickets, payments, stock movements, audit | no conflict: union, deduplicated by `commandId` |
| Counters | stock balance | never synced as a value: recomputed from movements |
| Editable records | products, prices, clients, employees, settings | field-level last-writer-wins by HLC; a true concurrent edit of the same field goes to a **conflicts inbox** for the owner |
| Deletes | anything | tombstones win over an older edit; an edit newer than the delete revives it and is flagged |
| Permissions / users | roles, grants | the cloud wins (security decisions are never made offline) |

Clock: HLC on the master. Clients take the master's time. A master clock that is off by more
than a threshold blocks sync and warns.

---

## 10. Operations

### 10.1 Backups
- Automatic daily encrypted snapshot while the engine runs (a SQLCipher backup plus the file
  store, one `.lyrabak`), rotated, to a configurable folder (a USB drive or network share).
  Encrypted with the DEK, restorable with the recovery key on any machine.
- Manual backup and restore in the admin screen. A restore runs the migrations and is logged
  in the audit log.
- Optional, paid: end-to-end encrypted backup to our cloud (zero-knowledge; we only store blobs).

### 10.2 Updates
- The master must be at a version ≥ every client (§5.1 `hello`). The master serves the web
  bundle, so web clients update with it. Desktop and mobile clients show an "update
  available/required" notice.
- Updating the master app restarts the engine: the update stops the running engine first and
  the new app starts the new one.
- The engine refuses to open a DB migrated by a newer version.

### 10.3 Moving or replacing the master
- Guided: take a backup on the old master, install on the new one, restore with the recovery
  key, and the devices re-pair automatically by `instanceId` (the CA travels in the backup).
- Future: a warm standby (a second desktop that receives the encrypted oplog), promoted manually.

### 10.4 Platform chores
- Windows: firewall rule on install, code-signed binaries (antivirus), a detached background process.
- macOS: notarisation, the local network permission prompt, the Keychain, a background process
  that outlives the app window (`LSUIElement` helper).
- Linux: libsecret or passphrase, a detached process (`setsid`).
- None of them register an OS service or login item (D4).
- Diagnostics screen: addresses, port reachability, connected devices, oplog lag, sync status.

### 10.5 Licence and integrity (principle 7)
- EULA: free use, proprietary, no sale, modification, redistribution or reverse engineering. It
  is shown and accepted on the first local setup, and the acceptance is recorded in the audit log.
  **The legal text needs a lawyer**; this plan only places it.
- Release builds use `--obfuscate --split-debug-info`, code signing on every platform, and the
  engine verifies its own signature at start, refusing to run if it was modified.
- No activation, no phoning home, no device limit: `local` must work with no internet ever.

---

## 11. Phases

Sizes are relative (S < M < L < XL). Each phase ships on its own and leaves `cloud` unchanged.

| # | Phase | Contents | Size | Exit criteria |
|---|---|---|---|---|
| 0 | Specs | Write `docs/offline/specs/*`, protocol v1 draft, EULA drafted by a lawyer | M | specs reviewed |
| 1 | Data-source seam | §7.1 steps 1–2 for every local domain, `CapabilityService`, `DeploymentMode` (only `cloud` reachable) | L | `flutter analyze` clean, all tests green, no behaviour change |
| 2 | Engine core | `lyra_protocol`, `lyra_node` storage, crypto (§6.2), oplog, migrations, identity, audit, process lifecycle (§3), `LocalServerService` | L | engine tests: encrypt, reopen, key loss = unreadable, migration; app close leaves the engine alive |
| 3 | LAN networking | TLS-only server, installation CA, QR and PAKE pairing, mutual TLS, CA install for web, mDNS, RPC, events, files, web bundle, setup screens (§7.4) | L | a second PC, a phone and a browser pair and sign in; a MITM test on the LAN fails to read or pair; revocation works |
| 4 | Domains, one per release | business (single site) → inventory and stock → POS → sales → finance and accounting export → employees (sealed fields) → clients, deliveries → statistics | XL | each domain's contract tests pass on both sources |
| 5 | Operations | backups and restore, update gating, master migration, diagnostics, POS outbox (§8.4), EULA flow, signed builds | L | disaster drill: kill the master, restore on new hardware, POS outbox replays |
| 6 | Hybrid | backend edge API (§9.2), sync engine, conflicts inbox, offline verifier (§6.4), local → hybrid migration | XL | a week-long soak with scripted outages and no divergence |
| 7 | Hardening | passphrase unlock UI polish, external security review (incl. LAN pentest), performance with 50 clients | M | review findings closed |

`local` can be released after phase 5, without the cloud. `hybrid` needs phase 6.

---

## 12. Rules to add to CLAUDE.md when phase 1 lands
- A new service call goes through its domain's `XSource`, never `api.*` from a service.
- A new area in `app-areas.json` declares `modes: ["cloud"]` or `["cloud","local"]`, and the
  capability table reads it.
- A new local op → `lyra_protocol` + engine handler + authorization rule + contract test, in
  the same change.
- Sensitive fields (money of a person, identity documents, bank data) are sealed by default.
- Nothing is ever served or accepted without TLS and a verified peer, including debug builds.

---

## 13. Decisions (2026-09-30)

| # | Question | Decision |
|---|---|---|
| D1 | Fiscal invoicing | Lyra is not fiscal or accounting software and won't be certified. Tickets are non-fiscal; data leaves via exports (§8.5). |
| D2 | Licensing | Free to use, proprietary: no sale, modification or redistribution. EULA plus signed builds; no activation (§10.5). |
| D3 | Traffic security in the LAN | Encrypted **and** authenticated: TLS 1.3 only, installation CA with name constraints, pinned mutual TLS for native clients, QR/PAKE pairing, and web only with the CA installed. "Accept the warning" and the public-DNS certificate are rejected (§5.3). |
| D4 | Engine lifecycle | Opening the app starts the engine; closing the app leaves it running; it never starts without the app (no OS service or auto-start) (§3). |
| D5 | Offline verifier in hybrid | 30 days, changeable by the owner. |
| D6 | Scope of a master | One company, one site (the current one). No business selector and no branch list offline. |
| D7 | Engine packages | Their own private repos next to `core`. |
| D8 | POS selling without the master | Yes, in the first `local` release (§8.4). |

---

## 14. Out of scope / future
- Offline map tiles (a `.pmtiles` region pack drawn on the client).
- Offline AI (a local model for table normalisation or the assistant).
- Several sites or companies in `local` mode (D6).
- Automatic master failover; auto-start of the engine (D4).
- Fiscal documents of any country (D1).

## 15. Risks
- **Double maintenance**: every local feature exists twice. Mitigated by the contract tests
  (§7.6) and by the rule that each feature declares its modes (§12). Accept that some
  features ship cloud-first.
- **Re-specifying business rules** that live only in the backend today (holds, totals,
  summaries). Phase 0 specs are the guard. Differences found later are bugs in the spec, not
  reasons to copy backend code.
- **Key loss = data loss.** Support will get these calls. Setup forces the owner to confirm the
  recovery key, and the admin screen reminds them until a backup exists.
- **Server down after a reboot** (D4): nothing runs until someone opens the app on the master.
  The POS outbox (§8.4) covers sales, but other clients stop working. The setup guide and a
  client message ("ask someone to open Lyra on the server") make this clear.
- **Web setup friction**: installing the CA on each browser computer is extra work. Native
  clients are the recommended path, and web is documented as the secondary option.
- **Hybrid divergence.** A soak test with scripted outages is the exit criterion, not a unit test.
- **LAN environments** (client isolation on Wi-Fi, blocked mDNS, captive firewalls). Mitigated
  by the manual address, QR fallback and the diagnostics screen.
