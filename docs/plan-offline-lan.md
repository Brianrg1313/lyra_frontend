# Plan: offline / LAN mode (local master)

## Where we are (2026-10-04) — read this first

Each release's detail is in the release log (appendix A). Phases are in §11, decisions in §13.

| Phase | State | Open |
|---|---|---|
| 0 Specs | done | the EULA waits for a lawyer |
| 1 Data-source seam | done | — |
| 2 Engine (`lyra_node`) | done | — |
| 3 LAN (TLS, pairing, web build, mDNS) | done on one computer | the exit check on real hardware (a second PC, a phone, a browser, a LAN MITM attempt; the camera, the OS trust-store dialogs, Firefox) |
| 4 Domains | business, inventory and stock, import, POS, sales, finance, employees, permissions (the cloud's model) done | the app's permissions editor on the catalog (cloud and master); clients and deliveries, then statistics |
| 4b One app (§9.6) | E1 done; E2 done in code and tests | E2 on real hardware; E3, the cloud grant |
| 5 Operations | not started | — |
| 6 Sync (§9) | the engine's half done (`EdgeSync`, tested against an in-memory backend) | the app's ops (enrol, status, inbox) and the server section showing the sync, both waiting on the backend's `/edge/v1/devices`; the next entities (POS tickets, employees, clients, files); the cloud's web finding its master (§9.7, D19, planned, nothing built) |
| 7 Hardening | not started | — |

**Next step:** the app's permissions editor (`EmployeePermissions`) on the cloud's catalog, through
`/permissions/members` online and `permissions.members.*` on a master; then clients and deliveries,
statistics, and E3 (engine side; the backend's part is §9 of `docs/task-edge-sync-backend.md`).
**Real hardware goes last** (owner's call, 2026-10-04): the exit checks of phase 3 and 4b and the
"not yet seen" list below run together once the code is done.

**Built, not yet seen on screen**
- Permissions on a master (2026-10-04): the cloud's catalog, templates and per-person document, a
  new member admitted with nothing, assign/revoke applied to open sessions at once. No screen calls
  the ops yet (the editor is the next step).
- E2: `hybrid` (the online sign in opens the master's session too), sections locking and opening in
  place with the internet, "work offline", the server section online, the link (D18).
- A session on the master alone offering "sign in online" by itself once the backend answers (2026-10-03).
- The sign in page swapping the cloud's form and the offline one in place, both ways (2026-10-04),
  through the backend's `/presence` namespace (`lyra` backend `lib/models/bridge/presence.js`, **not
  deployed yet**; HTTP every 15 s is the fallback).
- An invitation on a real master, its code typed on a second device, that person's own profile.
- "Create Master Server" from the sign in, end to end to the master's home (checked up to the
  welcome's modal).

**Known issues**
- A Mac's Chrome needs macOS's Local Network permission to open a master by name or IP (seen
  2026-10-01 as `ERR_NETWORK_IO_SUSPENDED`; not retried).

**Repos** All on this disk, **nothing pushed**, no remotes except `core`'s.
- The backend (`backend/projects/lyra`): the permissions catalog gained `server` and `money.export` and the
  areas map the master's ids (2026-10-04), plus `pnpm permissions:export`; **uncommitted**, beside other
  work in progress there.
- The app: `main` (the `feat/offline-*` branches are merged into it).
- `lyra_protocol`, `lyra_node`: `main`.
- `core`: `feat/offline-lan`, which holds what the app depends on; its `main` is behind it.

**Running a master**
- `dart build cli` in `lyra_node`, then `flutter run -d windows` here (the CMake install copies the
  engine next to `app.exe`).
- A browser reaches a master only at the address the master serves, never at `flutter run -d chrome`'s:
  `https://<company-label>.local:4780` (§5.2; the server section shows it, the IP below) or
  `https://<ip>:4780`. A browser's pairing belongs to the address it was made at. The engine serves
  the web build only if `lyra_node/web` is next to `app.exe` or `LYRA_WEB` points at one (a 404
  otherwise), so `flutter build web --release --no-web-resources-cdn` goes before
  `flutter run -d windows`. The `.local` name was checked resolving on Windows, not yet in a browser
  on another device.
- This computer's earlier master was wiped on 2026-10-01 (passphrase forgotten): its data and the
  app's secure storage are in `%LOCALAPPDATA%\Lyra\backup-2026-10-01`, readable only with that
  master's 24 words; delete it otherwise. A fresh start offers "Create Master Server" again.

**Gate** `flutter analyze` clean; `flutter test` 1189 passing with the 5 known failures of
`test/MODULE.md`; `lyra_node`: `dart analyze` clean, `dart test -x process` passing.

**Keeping this current:** at the end of each release, update the table, the next step and the
"not yet seen" list here, and add the release's detail to appendix A. Nothing else at the top.

**Scope** This app (`lyra/app`), `core`, two new Dart packages, and, for the hybrid phase only,
a narrow new API on the backend (`backend/projects/lyra`).
**Goal** The app works without the cloud. One desktop install (Windows, macOS or Linux) is the
**master**: it stores the data of **one company at one site**, encrypted, and serves it over the
LAN. Every other install (desktop, web, Android, iOS, POS) is a **client** of that master. Only
features that really need the internet (WhatsApp, AI, e-mail, maps and place search) are left
out.

The mode is a fact of the company, never a choice made on the first screen (D9):

| The company has | Mode | Cloud cost to us | Source of truth |
|---|---|---|---|
| No computer (phones, the web) | `cloud` | today's cost | the cloud, today's app unchanged |
| A computer, not linked online, or past the free allowance without a subscription | `local` | zero (sign in and the account only) | the master of each site |
| A computer linked online, within the free allowance or subscribed (D15) | `hybrid` | today's cost | the master of each site plus the cloud, reconciled by sync (§9) |

With a computer there is always a master, which keeps a full copy of its site: losing the internet
changes nothing on the LAN. Linking, crossing the allowance, subscribing or cancelling moves between
`local` and `hybrid` without losing data (§9.4).

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

Nothing disappears (D17): a cloud-only area in `local`, or in `hybrid` with the internet down, is
**shown locked** (the side bar marks it, the section says it needs the internet); an area whose master
side isn't built yet (phase 4) is locked the same way, saying it isn't available without the internet
yet. Only what can't exist on the device (the server section on a phone or in the cloud's browser) is
left out.

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

Engine internals (phase 2 built `storage`, `crypto`, `identity`, `oplog`, `audit`, `process`; the file
list is `lyra_node/MODULE.md`):

```
lyra_node/lib/src/
  storage/   store.dart (SQLCipher open, WAL, single writer), migrations.dart, migrations/mNNN_*.dart
  crypto/    keyring.dart (DEK/KEK), envelope.dart (AES-256-GCM), secrets.dart (Argon2id, HKDF),
             recovery.dart (24 words), vault.dart (DPAPI, Keychain, libsecret), sealed.dart (phase 4)
  identity/  accounts.dart, passwords.dart
  domain/    business/ employees/ clients/ inventory/ stock/ pos/ sales/ money/ deliveries/
  oplog/     hlc.dart, oplog.dart (append, feed since seq), commands.dart (commandId ledger)
  net/       server.dart (TLS only), tls.dart (installation CA), pairing.dart (PAKE),
             discovery.dart (mDNS), auth.dart, rpc.dart (router + authorization),
             files.dart, web_bundle.dart
  export/    accounting.dart (§8.5)
  backup/    snapshot.dart, schedule.dart, restore.dart
  sync/      (phase 6) edge_client.dart, outbound.dart, inbound.dart, conflicts.dart
  audit/     audit_log.dart (hash-chained)
  process/   lock.dart, control.dart (signed state file and stop requests), runner.dart, status.dart
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
- Browsers open the master by a name, never an address: `<label>.local`, made once from the
  company's name (`panaderia-don-jose.local`; kept through a rename, so saved links still work).
  The master answers it over mDNS, with no router setup, and only to a question about that name.
  If another device on the LAN already answers it, the master takes `label-2`, `label-3`… Its
  certificate carries the name, and the browser root already allows any `.local` name. The name
  works from the moment the company is created, with no restart.
- **Planned (2026-10-03, D19): the claim made sturdier.** Today `LanName.claim` asks once per name,
  only at start or renewal. Two gaps: two masters starting together both hear silence and take the
  same name; and a device that takes the name later is never noticed. Fixes: a random 0–250 ms wait
  before the first question and three questions 250 ms apart per name (RFC 6762 §8.1); and the
  `MdnsResponder` watching for another address answering its own name (§9), which claims again
  (the taken name skipped), issues the transport with the new name and reports it to the cloud
  (§9.7). The name can therefore change between starts: whoever needs it reads it, never derives it.
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

The CA exists as **two self-signed roots of one key and name** (phase 3 finding): native clients
pin the plain one inside their own TLS context, and only the name-constrained one goes into an OS
trust store for web. Dart's TLS (BoringSSL) refuses IP name constraints outright, so a native
client can't verify through the constrained root; every certificate the key signs chains to both
(`protocol-v1.md` §3).

**Native clients (desktop, Android, iOS): the recommended way to use the LAN.**
- An admin, signed in on the master, opens "Add device". The master shows a QR and an 8-digit
  code, valid for 5 minutes and one use only.
- **QR**: it holds `{addresses, port, instanceId, caFingerprint, pairingToken}`. The camera sees
  the master's screen directly, so the fingerprint can't be swapped on the way.
- **Password** (D13), the sign in of a device that has none yet: the account's e-mail (or username)
  and password are the PAKE secret, through what the master keeps of the password (`protocol-v1.md`
  §3). No admin and no code: any active account adds its own devices, which appear in "Devices" and
  are revoked from there; a wrong password counts towards that account's lockout (S-4).
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
  the setup guide requires checking it against the one on the master's screen. (Not built in
  phase 3: the two ways above cover it, and a download over a connection the browser doesn't
  trust yet is the warning this section refuses.)
- Without the CA, the browser shows its certificate error and Lyra's setup guide explains why
  it must not be bypassed.
- Web sessions are also bound to the pairing: the first sign in from a browser needs a pairing
  code approved on the master, and the device appears in "Devices" like any other.

**Rejected: option (c)**, a public certificate for `<id>.lan.<our-domain>`. That name needs
internet DNS to resolve, so it fails exactly during the outages this mode exists for.

**Revocation.** "Devices" lists every paired device (name, platform, last seen, user). Revoking
one kills its sessions at once, and its certificate goes on the engine's deny list.

### 5.4 Authorization
- Every op is checked on the master against the signed-in user's permissions: **the cloud's own
  permission system** (backend `lib/models/permissions`), copied in `lyra_protocol`: the same
  stored document, the same catalog keys per op as the cloud's routes, the same areas map for the
  app (`session.md` session.permissions). Clients hide what they can't open, but the **master is
  the gate**. An op the user may not run fails with `code: forbidden`.
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
- Two scopes, each with its own SK: `hr` (employees' private fields and salaries, held by the
  catalog key `employees`) and `payments` (account holder, document and number of payment methods,
  held by `money`): the keys the cloud requires for those screens (`session.md` P-9).
- So the master can read sealed fields **only while an authorised user has a session open**.
  Someone who steals the disk and breaks the OS vault still can't read salaries.
- Granting that permission re-wraps SK for the new user, and needs a user who already holds SK.
  Revoking it deletes that user's wrap. A password reset through the recovery key re-wraps it.
- Cost: reports that need salaries while no HR user is signed in can't run. That is intended.
- A person's own private data (`employees.md` E-3, E-13) is theirs without holding SK: SK also
  derives a key pair whose public half is stored, and each such value is sealed to it and to the
  person's own key pair, which their password opens. Writing then needs no key at all; the
  person's session keeps their private key beside the SKs it opened.

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
Nothing is asked up front (D9). `Deployment.restore` reads what the device holds: a stored pairing
(`LanDevice`, written by the setup or by pairing) makes it a master or a client; anything else is the
cloud app. `initialValidator` then:
- master → `LocalServerService` starts or attaches to `lyra_node` (§3), then unlocks it in
  passphrase mode, then sign in.
- client → find the master (last address, then mDNS, then the pairing screen), then sign in.
- a browser on a master's page with no pairing → the pairing screen (its page has no cloud).
- anything else → the sign in, which follows the network (D13, `NetworkScanService`): it asks the
  backend and listens for masters on mDNS at once, and again every 15 s until the backend answers.
  - The backend answers → today's cloud sign in, whatever is on the LAN.
  - No backend, a master answers → that master's sign in: e-mail and password. They pair the device
    first (the password way, §5.3) and then sign it in; no code, no admin at the master.
  - Neither, on a desktop with the engine not set up → "Create Master Server": the same e-mail and
    password become the owner, and the setup asks only for the rest (names, licence, the recovery
    words). Then it signs the owner in and lands on the welcome, whose "create company" makes the
    company (`business.create`), as in the cloud.
  - Neither, anywhere else (web, phones) → a placeholder that looks again.
Leaving the LAN ("use Lyra another way") forgets the pairing and returns to the sign in; the master's
engine and data stay. The first local setup shows
the licence agreement (principle 7), which must be accepted. Whether a master syncs with the cloud is
the company's subscription (§9.4), read from the master, never a setting of the device.

### 7.5 Catalogs
Countries, currencies and phone plans come from `/init` today. The release bundles a snapshot in
`lyra_protocol` (`Catalogs`, regenerated at release), which both the engine and the app compile in:
the master serves it, the app reads it before any master exists, and in hybrid the master
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
- The sync runs whenever a master is **linked** to its cloud company (D18, `business.md` B-30) and the
  company is within the free allowance or subscribed (D15). Past the allowance without a subscription
  it pauses: the master keeps working alone, the cloud keeps serving the sign in, the account and the
  link, and the sync picks up from where it stopped once the company is within it again. A master
  never linked doesn't sync at all (`local`).
- **Every site has its own master** (D11), so each keeps working through an outage. A master
  belongs to **one site** of a cloud company. It holds that site's operational data (its stock,
  POS, tickets, payments, staff) and the company data that site uses (catalogue, prices, clients,
  payment methods, its employees).
- **Clients at that site use the master for local domains**, online or not (§9.6). That gives one
  write path, so a failover mid-session never switches the source of truth. Cloud-only domains (§2)
  go straight to the cloud, as today.
- **The engine syncs, not the app.** It dials out to the cloud over HTTPS on its own, so the sync goes
  on while the app is closed (D4: the engine outlives the window). Nothing listens: no port is
  opened for the cloud (§9.5). The app only enrols the master (below) and shows the sync's state.
- The master pushes its oplog and pulls the cloud's changes relevant to its site (WhatsApp sales for
  that site, catalogue or price edits made elsewhere, a payment recorded from a phone away from the
  office).

### 9.2 Edge contract (new, small, owned by the backend)
The handover is `docs/task-edge-sync-backend.md`: endpoints, the vocabulary, the id map, the
credential, the allowance and the cloud grant (E3). In short:
- **Enrolment.** The engine makes an Ed25519 key pair for the edge; the app, signed in online as
  the owner, registers its public key with the backend (user session) and hands the answer to the
  engine: the edge device's id, the cloud site, and the backend's **edge key**, pinned for the
  grants (§9.6). Revocable from the cloud; the engine never sees a person's cloud token.
- **Authentication.** Every edge request is signed with the master's private key (method, path, time,
  nonce, body digest). No bearer secret travels or rests anywhere.
- `POST /edge/v1/commands`: a batch of changes in order, each with a `commandId` (idempotent), its
  `hlc` and its origin. The answer is per change: accepted (with the cloud id of what it created),
  or rejected with a reason, which the master keeps for review and never retries.
- `GET /edge/v1/changes?cursor=`: what changed in the cloud for this company and site after the
  cursor, never what this master sent (no echo).
- `GET /edge/v1/snapshot?cursor=`: the cloud's whole state for this site, paged, to fill a new or
  rebuilt master; the first link uploads the master's state through `/commands`.
- **Ids.** Neither side adopts the other's. The wire speaks cloud ids, and the master's own ids as
  `m:<id>` until the cloud has answered with one; the master keeps the `cloud_id ↔ local_id` map,
  and the backend resolves `m:` ids it has seen from that edge device.
- The backend maps the edge vocabulary to its own model.

### 9.3 Conflict policy per kind of data

| Kind | Examples | Policy |
|---|---|---|
| Append-only facts | sales, tickets, payments, stock movements, audit | no conflict: union, deduplicated by `commandId`; a later state (a void, a close) is a new fact about it |
| Counters | stock balance | never synced as a value: recomputed from movements |
| Editable records | products, prices, clients, employees, settings | field-level last-writer-wins by HLC; a true concurrent edit of the same field goes to a **conflicts inbox** for the owner |
| Deletes | anything | tombstones win over an older edit; an edit newer than the delete revives it and is flagged |
| Permissions / users | roles, grants | the cloud wins (security decisions are never made offline) |

- Both sides apply the same rule, so they converge without asking each other: a field keeps the
  value with the newest HLC. The master keeps each field's stamp and whether it was written here.
- **A true concurrent edit** is a field changed on the master since its last pull that the cloud
  changed too, to another value. The newer stamp still wins on both sides; the other value goes to
  the conflicts inbox, where the owner can put it back (a new edit, synced as any other).
- A change the cloud refuses (a rule broken on its side) is kept with the reason and shown to the
  owner; the master's data isn't rolled back.
- Sealed fields (§6.3) cross only when the backend gets a way to keep them sealed: the master has
  no key to open them while nobody is signed in. Until then they stay on the master (task doc).

Clock: HLC on the master. Clients take the master's time. A cloud stamp further ahead than
`HlcClock.maxDrift` stops the sync and warns, instead of dragging every later stamp forward.

### 9.4 Linking, subscribing and cancelling (D10, D11, D15, D18)
- **Linking** a master made offline (D18) enrols it and uploads its data (its whole state as
  `/commands`, then the oplog from there on); a master made from the cloud (D16) is enrolled when it
  is made and downloads the cloud's (`/snapshot`). When both sides already hold data, the master's
  is added to the cloud's: matching the same product or client on both sides is the backend's
  (task doc, open question).
- **Accounts.** Linking makes a cloud account for each local user (D10), so everyone keeps signing
  in. A local user whose e-mail already has a cloud account is not merged: that person settles it
  with their administrator. Local accounts with a username and no e-mail need one first.
- **The allowance** (D15) is measured by the backend, which answers the enrolment and every edge
  call with it; past it the master pauses the sync (§9.1). **Subscribing** lifts it.
- **Cancelling** keeps every site's data: each site's master pulls its own site's data one last time,
  stops syncing and goes on as a `local` install of its own. In the cloud the main site stays the
  company's and the secondary sites become inactive. A site without a master downloads its data to a
  new one before the subscription ends.
- Open: how long the cloud keeps a cancelled company's data, read-only, for a site to pull it.

### 9.5 Remote access (D12)
The master is never reachable from the internet: no open port, no forwarding.
- **With a subscription**, a device away from the LAN uses the cloud, which holds the synced data;
  what it changes reaches the master by the normal sync (§9.3).
- **Without one**, the owner can bring the device into the LAN with their own VPN (WireGuard,
  Tailscale). Pairing already takes a typed address; the master's certificate names only LAN
  addresses (name constraints, §5.3), so the owner must be able to add the VPN's address to it.
- A relay of ours (the master dialling out, end-to-end TLS through it) is left for when owners
  without a subscription ask for it: it costs us traffic for installs that don't pay.

### 9.6 One app, one session (D14 to D17, 2026-10-01)
The owner's model of the product: the cloud and the master are two homes of the same data, never two
apps. What the person sees, how they sign in and what the side bar holds don't change with the network.
- **Where the data lives (D15).** Within the free allowance the company's data lives in the cloud
  **and** on its master, kept equal by the edge sync (§9.2, §9.3); with a subscription too. Past the
  allowance without a subscription it lives on the master only, and the cloud keeps serving what is
  vital (signing in, the account, the link to the master), so the data is always reachable. The
  allowance and its measure are the backend's (`docs/task-edge-sync-backend.md`).
- **Mode on a device with a master.** A paired device (or the master) signed in online whose master takes
  the session runs `hybrid` (one whose master doesn't answer, away from the office, runs `cloud` until it
  does: the server section's "try again"):
  the local domains always go to the master (one writer, principle 4; it always holds the full copy),
  the cloud-only areas to the cloud while the internet answers, locked while it doesn't. A domain whose
  master side isn't built yet reads the cloud while online. Losing the internet never signs anyone out
  and never changes what the local domains show; coming back unlocks the cloud areas in place.
  "Work offline" (the server section) is the same state chosen on purpose, the session kept.
- **One session, two credentials (D14).** Signing in online on a device with a master also opens that
  person's session on the master (30-day rotating refresh, `session.md` S-21), so the session survives
  the internet, the subscription and a restart. The master accepts a **cloud grant**: a short-lived
  statement signed by the backend's edge key (the account, this master's id, a nonce, the expiry) that
  the master checks offline against the key pinned when it was linked, single use, then maps to its own
  account. Until the backend issues grants, the master's password opens it: the one typed online when
  it was a password sign in, otherwise asked once after a Google or code sign in.
- **The server section is everywhere a master can be (D16).** In the cloud too, on a computer: create a
  master from there, whose owner is the signed-in account (its password asked, since the sealed keys of
  §6.3 hang on it) and whose company starts from the cloud company's profile (name, logo, country,
  currency); the rest arrives by the sync. The master stores the cloud company's id (the link).
- **The link (D18).** A master made offline doesn't know its cloud company. At the first online sign in
  on its devices its owner is asked once, in plain words, whether to join this server with the company
  online (named when there is one, picked among several, the one named like the master's first); "not
  now" is remembered and the server section offers it again. Until linked, the cloud-only areas are
  locked with their own message (`needsLink`). The cloud-only calls carry the linked id
  (`BusinessModel.cloudKey`); the local domains keep the master's.

### 9.7 The cloud's web finds its master (D19, planned 2026-10-03)
A browser on the cloud's web build can't discover anything (no multicast: `lan_web.dart` `discover`
answers nothing), but it can try a name it already knows. So the cloud tells it the name, and the
master proves who it is.
- **The master reports its address.** Over the edge channel (signed, §9.2), once after enrolment and
  every time its transport is issued with another `host` or other addresses (start, renewal, a name
  conflict, §5.2): `{instance, host, port, addresses}`. Only an enrolled master can: one never linked
  (`local`) is invisible to the cloud's web, by design.
- **The web asks the cloud** for its company's masters (one per site, D11) with those fields, and
  keeps the answer in the browser, so it can still try them once the internet is gone.
- **The web probes.** `GET https://<host>:<port>/lyra/probe`, the host first, then each address (the
  certificate names them too), a 2 s timeout each. The engine answers `{instance}` with
  `Access-Control-Allow-Origin` set to the cloud's web origins only (a built-in list; a development
  origin added by `LYRA_WEB_DEV` while developing, since `flutter run -d chrome` serves from
  `localhost`), and answers Chrome's local network preflight (`Access-Control-Allow-Private-Network:
  true`). The instance is no secret: the installation CA, shown to anyone on the LAN in the TLS
  handshake, already carries it.
- **Only a match counts.** The web accepts a master only when the probed `instance` is the one the
  cloud named. A name collision, another company's master or anything else answering that name is
  ignored. The probe only succeeds where the browser trusts this master's browser root (§5.3), that
  is, on a computer that has used it before; elsewhere TLS fails, which looks the same as "absent".
- **It offers, never redirects.** A banner: "Your company's server is on this network · Open", which
  goes to `https://<host>:<port>/`. That is another origin: no storage is shared, so the person signs
  in again on the master's `/login` (D13), and the browser's pairing is the one made at that origin.
- **When it probes.** A public origin calling a `.local` name or a private address makes Chrome ask
  for local network access, so the web never probes unprompted the first time: the server section
  online (on the web) has "Find it on this network", and losing the internet probes with the kept
  list (the moment the master matters most). After one success the browser remembers it (per-viewer
  `localStorage`) and probes on its own after each sign in. In development the prompt never shows
  (`localhost` is already local), so only a deployed origin shows the real behaviour.
- Backend side: `docs/task-edge-sync-backend.md` §12.

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
| 4b | One app (§9.6) | E1 nothing disappears: locked areas, the server section in the cloud, a network failure keeps the session · E2 one session: `hybrid` on a device with a master, the master's session opened with the cloud's sign in (password), "work offline", a master made from the cloud with the company's profile · E3 the cloud grant (engine side, backend task) | L | a paired device loses and regains the internet without signing in again or losing a section |
| 5 | Operations | backups and restore, update gating, master migration, diagnostics, POS outbox (§8.4), EULA flow, signed builds | L | disaster drill: kill the master, restore on new hardware, POS outbox replays |
| 6 | Hybrid | backend edge API (§9.2), sync engine, conflicts inbox, offline verifier (§6.4), subscribing and cancelling with the accounts (§9.4), remote access through the cloud and the VPN address (§9.5), the cloud's web finding its master (§9.7) | XL | a week-long soak with scripted outages and no divergence |
| 7 | Hardening | passphrase unlock UI polish, external security review (incl. LAN pentest), performance with 50 clients | M | review findings closed |

`local` can be released after phase 5, without the cloud. `hybrid` needs phase 6. Every build already
offers `local` (2026-10-01, the owner's call: one build, no flag), so until phase 5 a store build's sign in
offers a master that has no backups.

---

## 12. Rules to add to CLAUDE.md when phase 1 lands

The first two are in CLAUDE.md since phase 1, the next two since phase 2, the last one since phase 3.
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
| D9 | How a device gets its mode (2026-10-01) | Never chosen up front. The mode follows the company: no computer = `cloud`; a computer = a master per site, `local` without a subscription and `hybrid` with one. A device is in LAN mode while it holds a pairing (§7.4). |
| D10 | Accounts when subscribing (2026-10-01) | The backend creates a cloud account for each local user. An e-mail that already has a cloud account is settled with the administrator, never merged automatically (§9.4). |
| D11 | Sites with a subscription and after it (2026-10-01) | Each site has its own master. Cancelling keeps every site's data on its master, each working on its own; in the cloud the main site stays and the others become inactive (§9.4). |
| D12 | Remote access (2026-10-01) | Through the cloud with a subscription; without one, the owner's own VPN. The master never opens a port; our relay only if asked for (§9.5). |
| D13 | Entering the LAN without a pairing (2026-10-01) | The sign in follows the network: the cloud's while the backend answers; otherwise a master found on the LAN, whose sign in pairs the device with the account's password (SPAKE2, no code: any active account adds its own devices, the admin sees and revokes them); with neither, "create master server" where the engine runs, the e-mail and password becoming the owner (§7.4). |
| D14 | One session (2026-10-01) | Signing in online on a device with a master opens the master's session too: a backend-signed grant the master checks offline; until it exists, the master's password (reused, or asked once) (§9.6). |
| D15 | Where the data lives (2026-10-01) | In the cloud and on the master while within the free allowance or subscribed; past it, on the master only, with sign in and the account still served by the cloud (§9.6). |
| D16 | Server section online (2026-10-01) | Shown in the cloud on a computer; a master made from there takes the account as owner and the cloud company's profile (§9.6). |
| D17 | Nothing disappears (2026-10-01) | Areas the network or the master can't serve are locked, never hidden (§2). |
| D18 | Linking a master to its cloud company (2026-10-01) | Asked once to the owner at the first online sign in on its devices, in plain words that say what joining does (no promise about the data: that is the privacy policy's); also from the server section (§9.6, `business.md` B-30). With no cloud company to join, one is made from the master's profile and linked, nothing asked (2026-10-04). |
| D19 | The cloud's web finding a master (2026-10-03) | The enrolled master reports its `.local` name and addresses to the cloud; the web probes them and accepts only the `instance` the cloud named; it offers the master's page, never redirects; the first probe only on the person's request or when the internet goes. The name claim waits, repeats and watches for conflicts (§5.2, §9.7). |

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
- **Pairing crypto** (`protocol-v1.md` §3): SPAKE2 (RFC 9382) in pure Dart over `pointycastle`,
  checked against the RFC's vectors, not constant time; a browser's device identity is a WebCrypto
  key that clearing the site data destroys (that browser pairs again). Both are retested in the
  phase 7 review.
- **LAN environments** (client isolation on Wi-Fi, blocked mDNS, captive firewalls). Mitigated
  by the manual address, QR fallback and the diagnostics screen.

---

## Appendix A. Release log

What each release built and left for later, oldest first. The status table at the top says where
things stand.

- **Phases 0 to 3** (2026-09-30 on). Product decisions settled the same day (§13). Phase 0 closed (specs and
  protocol draft in `docs/offline/`; the EULA waits for a lawyer). Phase 1 done: the data-source seam,
  `DeploymentMode` and `CapabilityService` are in the app, with only `cloud` reachable. Phase 2 done:
  `lyra_protocol` and `lyra_node` exist (encrypted store, keyring, oplog, audit, owner account, detached
  process), and the app drives the engine through `LocalServerService`. Phase 3 done on one computer:
  the engine serves the LAN (TLS 1.3 only, installation CA, SPAKE2 pairing by code or QR, mutual TLS,
  revocation, events, files, the web build, mDNS), and the app has the setup, pairing and LAN pages
  (in every build since 2026-10-01, no build flag; nothing is asked up front since the same day (D9): a
  device is in LAN mode while it holds a pairing; the sign in follows the network (D13): the cloud's while the
  backend answers, a master's found by mDNS otherwise, whose e-mail and password pair the device, and with
  neither "create master server" on a computer that can be one; a browser offers the LAN only on the page a master serves, which carries
  `WebBundle.marker`): phones scan the QR, desktops type the code, and the web build the master
  serves pairs, keeps a WebCrypto key and proves itself (checked in a real Chrome,
  `lyra_node/test/browser_e2e_test.dart`). A paired native device installs the browsers' root (Windows,
  macOS) or saves it for another computer. The web build is made with
  `flutter build web --release --no-web-resources-cdn`, the same as the cloud's, and served from
  `lyra_node/web` next to the engine (`LYRA_WEB` while developing); shipping it is phase 5. Still open from
  phase 3: the exit check on real hardware (a second PC, a phone, a browser; a LAN MITM attempt), which
  also covers what no test here can reach: the camera, the OS trust-store dialogs (`certutil`, `security`),
  and Firefox, which may keep its own store.
- Phase 4, first release (business): setup makes only the owner, and the owner creates the company
  from the welcome (`business.create`, as in the cloud); the engine serves `session.bootstrap`,
  the company, its site and the catalogues (`business.md`); the app reads them through
  `SessionLanSource` and `BusinessLanSource`, opens the home once signed in on the LAN, and moves the
  server's devices to a `local_server` home section. Areas whose release hasn't come stay hidden on a
  master's devices (`CapabilityService._builtOnMaster`). Left for later in this domain: a site form (no
  screen writes the location today), the time zone database, and live events in the app.
- Phase 4, second release (inventory and stock): the engine serves tables (templates, the primary flag),
  fields, records (checked cells, SKUs, counters, accent-free text search), product images with a
  320 px thumbnail, and the stock ledger (`stock.move`, holds, history, summary) (`inventory.md`,
  `stock.md`); the app reads them through `InventoryLanSource` and `StockLanSource`, and draws every
  image with `mediaImage`, which on a master downloads it over the pinned channel with the session's
  token (`LanFileImage`), so the company logo works there too. Left for later: I-4 and ST-14 (with the
  POS), and uploading a photo or a logo from the web build (the app hands it to its sources as a
  `dart:io` file, which a browser has none of; native devices upload, every client draws).
- Phase 4, third release (spreadsheet import): the engine reads `.xlsx` and `.csv` (I-40, I-41), types
  the columns by rules instead of a model (I-43), writes a stock column as opening balances (I-44), and
  re-types the columns nobody typed by hand (`inventory.tables.normalize`, I-47); the app's
  `InventoryLanSource` uploads the file for each step, and the app now follows the master's events
  (`LanService` subscribes, `ConnectionService.on` hands them to the same handlers as the cloud's
  socket), which is what ends an import's wait. Importing from the web build has the same `dart:io`
  gap as photos. No screen yet follows `table/changed` or `stock/changed` live on its own.
- Phase 4, fourth release (POS): the engine serves the counter's catalogue (read by field type, priced
  net of its discount), the settlement kinds (`Settlements` in `lyra_protocol`, without credit), and
  the ticket: per-device codes, lines that hold stock, money computed in minor units, close and
  cancel (`pos.md` POS-1 to POS-45), with the ticket holds of `stock.md` and I-4; "today" is computed
  with the IANA zone database the engine now carries. The app reads it through `PosLanSource`, and a
  product whose table counts no stock is sold without holds and shows no count (POS-6). Left for
  later: the POS outbox and ST-14 (plan phase 5).
- Phase 4, fifth release (sales): the engine measures each POS invoice into the cloud's stages
  (`SaleStages` and `Handover` in `lyra_protocol`, named in the company's language), pages the board by
  section with attention first, answers a sale's detail, and records the handover (`sales.md` SA-1 to
  SA-35); `sale/progress` is emitted by every POS write that moves a row and by the handover, only to
  the seller's sessions and those with `sales.view_all`. The app reads it through `SalesLanSource`;
  approving a payment stays cloud only, since a master has no conversations.
- Phase 4, sixth release (finance, first part): the engine records and voids payments by hand
  (`MoneyConcepts` in `lyra_protocol`, the concept deciding the direction), pages them with the
  filter's totals, answers the summary beside the register's closed tickets, the receivables (empty
  while credit is deferred) and the exchange currencies with custom rates (`money.md` M-1 to M-53).
  The app reads it through `MoneyLanSource`; finance's tabs now follow the running mode, and the
  bot cost isn't drawn in `local`.
- Phase 4, seventh release (finance, accounts): the sealed keys of §6.3 (`lyra_node` `SealedKeys`: an
  X25519 pair per account sealed by its password, each scope's key wrapped to its holders and to the
  recovery key, a session's keys sealed by its refresh token so a restart doesn't lock them), and the
  company's payment accounts on them (`money.md` M-40 to M-46): the rails, sheets and bank, document
  and network lists as a snapshot of the cloud's catalogue, holder, document and number sealed and
  never in clear at rest (rows, oplog, the `commandId` ledger), their reads audited. A session
  without the key answers `sealed_locked` and the app tells the person to sign in again. The
  methods tab, with the exchange currencies, now shows on a master. The eighth release (finance,
  export) adds the accounting export (`money.md` M-60 to M-65): sales, their lines, payments,
  receivables and stock movements for a window of calendar days, as CSV in a zip or one XLSX
  workbook, kept for the asker for an hour and audited; the overview tab offers it beside the range
  picker. Finance is complete on a master.
- Phase 4, ninth release (employees): the engine serves the staff (`employees.md`): the list shaped
  by permission, the former list, the detail with the E-4 measures, job edits, and the person's
  private profile and the job's pay sealed one value per row, to `hr` and to the person (§6.3), so
  the person reads and writes their own without holding `hr`. Inviting someone unknown makes a
  `pending` account whose activation code is answered once; the person types it with a new password
  on the LAN sign in (`auth.activate`, `session.md` S-8), which also accepts the invitation. The app
  reads it through `EmployeesLanSource`; the invite form shows the code, and the address search and
  the branch picker (cloud only) are off on a master. Left for later: re-issuing a code from the app
  (`employees.reissueActivation` is served, no button calls it), the pre-start task for a rehire
  (`employees.accept` is served), leaves and job endings. Permissions for other people arrived
  with the cloud's model on 2026-10-04 (see the permissions release).
- Phase 4b, one app (§9.6, D14 to D18, from 2026-10-01). E1: nothing disappears (locked areas and
  tabs), a network failure keeps the session. E2: `hybrid` (`HybridService`: the master's session
  opened by the online sign in, the password reused or asked once; the boot resumes it), the internet
  watched (sections lock and open in place; the cloud socket connecting opens them at once), "work
  offline", the server section online (create the server there, from the cloud company, linked), the
  link (`business.link`, asked once). A session on the master alone watches the backend and offers the
  same person's online sign in once, which joins it as `hybrid` in place (2026-10-03). The sign in page
  follows the internet both ways over the backend's `/presence` socket (2026-10-04).
- Phase 6, the engine's half of the sync (the owner's call of 2026-10-01): §9 rewritten for D15 and D18, the backend's
  handover `docs/task-edge-sync-backend.md`, and `EdgeSync` in `lyra_node`, run every minute while
  enrolled and tested against an in-memory backend (`test/support/edge_cloud.dart`): enrolment with an
  Ed25519 key, the first link both ways, push and pull, field stamps and the conflicts inbox, retries,
  refusals, revocation, the allowance.
- Permissions, the cloud's model on the master (2026-10-04, the owner's call: "the local permissions
  must be the backend's, never a second set"). The engine dropped its area-id grants and wildcards
  for the backend's per-person document (`all`, catalog `sections`, `template`, `custom`); every op
  checks the catalog key of its cloud route; the bootstrap answers the cloud's `/init` tree plus
  `owned`; templates (the seven global ones and the company's), members (assign, revoke, self, owner
  and escalation rules) and requests are the cloud's endpoints as ops. A job admits with nothing
  granted. `employees` holds the `hr` key and `money` the `payments` one, shared from the assigner's
  session or the next holder's and unwrapped when taken away. `lyra_protocol` carries the copy of
  the backend's catalog, areas and presets, tested against `pnpm permissions:export`; the backend's
  catalog gained `server` (the master's devices, backups, stop) and `money.export`. Consequences of
  matching the cloud: no "own sales only" (SA-11), no separate personal-data permission (E-3), a
  typed charge and a changed rate are `pos.sell`. Migration 12 moves an existing master over.
