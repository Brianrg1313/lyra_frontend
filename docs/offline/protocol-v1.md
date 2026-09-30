# Lyra LAN protocol, v1 (draft)

**Plan** §5. **Shared code** `lyra_protocol` (op names, DTOs, error codes, `protocolVersion = 1`)
is generated from, and must match, this file.

It's the only way into the master: the app on the master itself uses it too (plan §3). It
**isn't** the backend's REST contract: op names are domain verbs, ids are the engine's, and
nothing here says how the cloud is built (plan principle 1).

---

## 1. Endpoints

One TCP port (default `4780`), **TLS 1.3 only**. There is no plaintext listener.

| Path | Method | What | Auth |
|---|---|---|---|
| `/rpc` | WebSocket upgrade | every op and every event | mutual TLS (native) or CA-trusted TLS + pairing (web) |
| `/pair` | WebSocket upgrade | pairing handshake (§3) | TLS with the installation certificate; no client cert yet |
| `/f/<fileId>` | `GET` | download a file (range support) | session token in `Authorization: Bearer` |
| `/f` | `PUT` | upload a file (§6) | session token |
| `/` and `/app/**` | `GET` | the web build (plan §3) | none (static files) |

Response headers on every HTTPS answer: `Strict-Transport-Security: max-age=31536000`,
`Cache-Control: no-store` (except hashed web build assets), `X-Content-Type-Options: nosniff`,
a restrictive `Content-Security-Policy` for the web build.

---

## 2. Frames

JSON text frames, UTF-8, at most **1 MiB** each (`frame_too_large`). Anything bigger is a file.

**Request** (client → master)

```json
{ "id": 17, "op": "pos.invoices.line", "args": { … }, "commandId": "0192…" }
```

- `id`: an integer chosen by the client, unique per connection, echoed back.
- `commandId`: **required on every write** (README, writes), a UUIDv7. Reads don't carry it.

**Response** (master → client)

```json
{ "id": 17, "ok": true, "data": { … } }
{ "id": 17, "ok": false, "error": { "code": "insufficient_stock", "message": "…", "action": null, "data": { "productId": "…", "available": 2 } } }
```

- `error.message` is written in the **company language**, ready to show (`FloatFlag.showFromError`).
- `error.action` is a route key when the client must go somewhere (`"login"`), as today.
- `error.data` carries the fields a spec names for that code (for example `available`).

**Event** (master → client, after `events.subscribe`)

```json
{ "event": "stock/changed", "seq": 88213, "data": { … } }
```

Requests may be pipelined; answers may come out of order (match by `id`). Writes are applied in
the order the master **receives** them, one at a time (one writer, plan principle 4).

---

## 3. Pairing (`/pair`)

Plan §5.3. The device has no certificate yet; the master shows a QR or an 8-digit code
(`session.md`, `pairing.start`).

**With the QR** (it holds `{addresses, port, instanceId, caFingerprint, pairingToken}`):
1. The client connects to `/pair` and checks that the server certificate chains to a CA whose
   SHA-256 fingerprint is `caFingerprint`. Otherwise it stops.
2. It sends `{pairingToken, csr, device: {name, platform, appVersion}}`. The CSR is for a key the
   device just created and keeps in its OS key store.
3. The master answers `{certificate, caCertificate, deviceId, deviceCode, instanceId}`.

**With the code** (no camera):
1. The client connects to `/pair` **without** trusting the certificate yet.
2. Both sides run **CPace** over the connection with the 8-digit code as the password and
   `instanceId ‖ transcript` as the context. The code itself never travels.
3. With the key CPace agreed, the master sends the CA certificate and its fingerprint,
   authenticated (HMAC). The client checks it matches the server certificate it saw.
4. Then steps 2–3 of the QR flow, inside the authenticated channel.
- A failed CPace ends the connection and counts one failure. Three failures void the code
  (S-40).

After pairing, every `/rpc` connection uses **mutual TLS**: the client presents its device
certificate, and it pins the installation CA. A revoked certificate is refused during the TLS
handshake.

**Web** clients pair from the browser with the code flow, run in the page (the CA is already
trusted by the OS, plan §5.3). The "device certificate" of a browser is a **non-extractable
WebCrypto key** registered at pairing; each `/rpc` connection starts by signing a
master-provided challenge with it (`device.prove`), since browsers can't present client
certificates reliably.

---

## 4. Handshake and session

1. The first frame on `/rpc` must be `hello`:
   ```json
   {"id": 1, "op": "hello", "args": {"protocol": 1, "app": "0.0.7", "platform": "windows"}}
   ```
   Answer: `{protocol, engine, minApp, instanceId, state}`. `state` is `ready` or `locked`
   (passphrase mode, plan §6.2).
   - A protocol the master doesn't speak → `version_mismatch` with `action: "update"`, and the
     connection closes.
   - `app < minApp` → `update_required` with `action: "update"`.
2. While `locked`, only `hello` and (from the master's own device) `engine.unlock` are
   accepted; everything else answers `locked`.
3. `auth.*` ops (`session.md`) give tokens. Then `session.bind {accessToken}` ties the
   connection to that session. Every later frame runs as that account on that device.
4. Before the access token expires, the client calls `auth.refresh` and `session.bind` again on
   the same connection. A frame that arrives with an expired binding answers `session_expired`
   (`action: "login"` only when the refresh also fails).

Keepalive: WebSocket ping every 20 s; 3 missed pongs close the connection.

---

## 5. Events

- `events.subscribe {since?: seq}`: the master first replays every event after `since` that the
  session may see, then streams live ones. Without `since`, only live ones.
- `seq` is a single, increasing counter over the master's whole event stream. The client stores
  the last one it processed.
- Replay covers the last **7 days or 100 000 events**. Asking for an older `since` answers
  `resync_required`: the client re-reads what it shows, which is the `ConnectionService.onRestored`
  path the services already have.
- **Events are filtered per session** by permission (each spec says who receives what), and by
  data scope (`sales.view_all`, own-account events). A client never receives an event about data
  it can't read.
- Event names and payloads are the ones the app already parses (`stock/changed`,
  `invoice/*`, `sale/progress`, `table/*`), plus `business/changed`, `permissions/changed` and
  `table/changed`. The `XLanSource` feeds them to the same `receive(...)` seams.

---

## 6. Files

- **Upload** `PUT /f` with `Content-Type` and `X-Lyra-Purpose` (`logo`, `product_image`,
  `import`, `picture`). Limits per purpose: 5 MB, 10 MB, 20 MB, 5 MB. The master checks the real
  type from the bytes, not the header (`invalid_file`). Answer: `{fileId}`. An uploaded file
  that no op references within 1 hour is deleted.
- **Download** `GET /f/<fileId>[?size=<n>]`: `size` picks a stored thumbnail (images only).
  Permission: the one that reads the record the file belongs to. Export files (`export.*`) are
  readable only by the account that asked for them, for 1 hour.
- Files are stored encrypted (plan §6.2) and decrypted while streaming over TLS.

---

## 7. Paging, limits, idempotence

- Page lists: `{items, page, size, total}`; cursor lists: `{items, cursor, more}` (README).
  Where the app already reads another shape (for example `{keys, values}`), the op answers that
  shape; each spec says so.
- Per session: 50 requests per second, bursts of 200 (`rate_limited`, with `retryAfter`).
- `commandId` results are kept for **30 days**. A repeated `commandId` with **different** args
  answers `command_reused`.
- A POS outbox entry (`pos.md`, `pos.outbox.sale`) is additionally **signed** with the device
  key (Ed25519 over the canonical JSON of the entry), so an entry is accepted only from the
  device that wrote it, even when replayed later over another session.

---

## 8. Error codes

Common codes (any op may answer them):

| Code | Meaning | App behaviour |
|---|---|---|
| `bad_request` | args don't match the op's shape | bug: report |
| `unknown_op` | op doesn't exist in this protocol version | bug: report |
| `invalid_field` | a field fails its rule; `data.field` names it | show message |
| `required` | a required field is missing; `data.field` | show message |
| `not_found` | the addressed record doesn't exist (or isn't visible) | show message, re-read |
| `forbidden` | the session lacks the permission | show message |
| `session_expired` | token expired and not refreshed | `action: "login"` → `onSessionRejected` |
| `session_revoked`, `device_revoked` | ended by an admin | same, plus a `session_expired`-style flag |
| `locked` | engine locked (passphrase mode) | "server locked" screen |
| `rate_limited` | too many requests; `data.retryAfter` | back off |
| `version_mismatch`, `update_required` | client too old or too new | "update" screen |
| `command_reused` | same `commandId`, different args | bug: report |
| `resync_required` | event replay window passed | re-read |
| `needs_internet` | op exists but needs the cloud (hybrid, offline) | `SectionMessage` |
| `internal` | anything unexpected; details only in the master's log | show generic message |

Domain codes are listed in each spec next to the op that answers them.

---

## 9. Op catalogue (v1)

Grouped by spec. Arguments, answers and errors are in the spec files.

| Spec | Ops |
|---|---|
| protocol | `hello`, `engine.unlock`, `session.bind`, `device.prove`, `events.subscribe`, `events.unsubscribe` |
| session | `auth.identify`, `auth.signIn`, `auth.signInPin`, `auth.activate`, `auth.refresh`, `auth.signOut`, `account.changePassword`, `account.setPin`, `session.bootstrap`, `permissions.of`, `permissions.set`, `permissions.requests.list`, `permissions.requests.create`, `permissions.requests.inbox`, `permissions.requests.answer`, `devices.list`, `devices.rename`, `devices.revoke`, `pairing.start` |
| business | `business.profile`, `business.edit`, `business.setLogo`, `business.site.get`, `business.site.edit`, `catalog.get` |
| inventory | `inventory.tables.list`, `inventory.tables.create`, `inventory.tables.edit`, `inventory.tables.delete`, `inventory.tables.structure`, `inventory.tables.details`, `inventory.tables.normalize`, `inventory.fields.create`, `inventory.fields.edit`, `inventory.fields.delete`, `inventory.records.list`, `inventory.records.create`, `inventory.records.edit`, `inventory.records.delete`, `inventory.images.add`, `inventory.images.remove`, `inventory.import.structure`, `inventory.import.records` |
| stock | `stock.move`, `stock.history`, `stock.summary` |
| pos | `pos.summary`, `pos.catalog`, `pos.methods`, `pos.invoices.open`, `pos.invoices.line`, `pos.invoices.close`, `pos.invoices.cancel`, `pos.invoices.list`, `pos.outbox.sale`, `pos.snapshot` |
| sales | `sales.list`, `sales.catalog`, `sales.detail`, `sales.fulfil` |
| money | `money.catalog`, `money.summary`, `money.payments.record`, `money.payments.void`, `money.payments.search`, `money.receivables`, `money.methods.list`, `money.methods.rails`, `money.methods.create`, `money.methods.edit`, `money.methods.remove`, `money.currencies.get`, `money.currencies.save`, `money.currencies.remove`, `export.accounting` |
| employees | `employees.list`, `employees.former`, `employees.detail`, `employees.invite`, `employees.reissueActivation`, `employees.edit`, `employees.accept`, `profile.edit` |
| deliveries | `delivery.get`, `delivery.set`, `delivery.options.create`, `delivery.options.edit`, `delivery.options.remove`, `delivery.providers`, `delivery.areas.list`, `delivery.areas.create`, `delivery.areas.edit`, `delivery.areas.remove` |

Admin ops of the master (backups, key rotation, stop, diagnostics, audit export) belong to
phase 5 and get their own spec then (`specs/operations.md`).

---

## 10. Versioning

- `protocol` is an integer. Adding an op, an optional argument, an answer field or an event
  **doesn't** change it. Removing or changing the meaning of anything does, and the master then
  speaks both versions for at least one release.
- `minApp` is raised by the master when it needs a client feature. Clients are updated before
  the master refuses them (plan §10.2: the master is always at least as new as its clients).

## Open questions

Both are moved to the plan's risks (§15) and decided in phase 3.

1. CPace or SPAKE2 for the code pairing? Proposed: **CPace** (simpler, one round trip, IETF
   draft with test vectors). Either needs a vetted Dart implementation or a small FFI binding;
   that choice is made in phase 3, with a security review.
2. Is a WebCrypto non-extractable key strong enough as a browser's device identity (§3)? It
   survives until the site data is cleared; clearing it means pairing that browser again.
