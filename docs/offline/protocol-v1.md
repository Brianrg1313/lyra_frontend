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
| `/` and `/app/**` | `GET` | the web build (plan §3); its HTML carries `<meta name="lyra-master" content="1">`, which tells the app (the cloud's build too) it runs from a master | none (static files) |

Response headers on every HTTPS answer: `Strict-Transport-Security: max-age=31536000`,
`Cache-Control: no-store` (except hashed web build assets), `X-Content-Type-Options: nosniff`,
a restrictive `Content-Security-Policy` for the web build.

A WebSocket upgrade (`/rpc`, `/pair`) that carries an `Origin` must come from the master's own
page: `https://` and the host and port the request was sent to. Anything else is `403` before
the upgrade, so a page of another site, open in a browser that trusts the CA, can't reach the
master (cross-site WebSocket hijacking). Native clients send no `Origin`.

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

Plan §5.3. The device has no certificate yet; the master shows a QR and an 8-digit code
(`session.md`, `pairing.start`). Code: `lyra_protocol` (`pairDevice`) on the device, `lyra_node`
(`PairingDesk`) on the master.

**Both ways run SPAKE2** (RFC 9382, P256-SHA256-HKDF-HMAC). The secret is the typed code or the
QR's `token`; it is never sent. An attacker in the middle gets one guess per exchange and nothing
to test offline; a wrong exchange counts one failure, and three void the pairing (S-40). The
device is party A (`idA = "lyra-device"`), the master party B (`idB = instanceId`), and
`w = SHA-512(len‖"lyra/pairing/v1" ‖ len‖instanceId ‖ len‖secret) mod n`, so the same code for another
master is another secret. (Chosen over CPace: RFC 9382 is final and has test vectors for this
suite, and it needs only point arithmetic; CPace needs hash-to-curve, which no vetted Dart library
offers. The exchange is retested in the phase 7 review.)

The QR is `lyra-pair:` + base64url of `{v: 1, instanceId, addresses, port, caFingerprint, token}`.
Phones scan it in the app (Android, iOS); a device tries each address in order and stops at the
first that answers, since any master that answered has spent the token. Desktops and browsers
type the code.

The device connects to `/pair` without trusting the certificate yet, and records its SHA-256.
One JSON object per frame:

```
master → device  {step: "hello", instanceId, protocol}
                 (the password way only:)
device → master  {step: "account", login}
master → device  {step: "salt", salt, m, t, p, length}
               | {step: "failed", code: "account_locked" | "bad_request"}
device → master  {step: "start", secret: "code" | "token" | "password", pA}
master → device  {step: "reply", pB}
device → master  {step: "enroll", confirm: cA, device: {name, platform, appVersion},
                  publicKey, proof, mac}
master → device  {step: "paired", confirm: cB, instanceId, caCertificate, serverFingerprint,
                  certificate, deviceId, deviceCode, mac}
               | {step: "failed", code: "pairing_failed" | "pairing_expired" | "pairing_closed" | "bad_request"}
```

- `mac` is HMAC-SHA256 over the canonical JSON of the rest of the message, with
  `HKDF(Ke, "lyra/pairing/mac")`. `publicKey` is the SPKI of a P-256 key the device just made
  and keeps in its OS key store; `proof` is its signature of `"lyra/pairing/proof/v1" ‖ cA`, so
  an enrolment can't carry somebody else's key.
- The master checks `cA` first: a wrong one is a wrong secret. Then the MAC and the proof. Then it
  issues the device certificate (none for a browser) and consumes the ticket.
- The device trusts nothing in `paired` until `cB` and the MAC check out. Then it refuses
  (`wrong_master`) when `instanceId` differs, when the CA's fingerprint differs from the QR's, or
  when `serverFingerprint` differs from the certificate TLS showed it: that last one means the TLS
  connection ends at someone in the middle, even though the code was right.
- A QR is checked before any secret is used: another `instanceId` in `hello` is `wrong_master`.

**The password way** (plan D13) is the sign in of a device that has no pairing: the secret is the
account's password, so no ticket, no code and no admin are involved. `login` is the username or
the e-mail. The master answers how that account's password is hashed (`session.md` S-3: the PHC
salt and Argon2id `m` KiB, `t`, `p`, and the digest's `length`), and the secret on both sides is
`base64(Argon2id(password, salt, m, t, p, length))`: the device derives it, the master already
holds it as the account's digest (`PasswordSalt.secretOf`; `lyra_node/test/crypto_test.dart` checks
the two Argon2 libraries agree). The digest never travels and is never logged.
- A login that can't sign in (unknown, pending, disabled) gets a decoy salt, `HMAC(key, login)`
  with a key derived from the DEK, the same on every ask, and the exchange runs against a secret
  nobody holds, so it fails like a wrong password and nothing tells whether the account exists.
- A wrong password is `pairing_failed` and counts towards that account's lockout (S-4); a locked
  account answers `account_locked` before any exchange, as its sign in does.
- The device refuses a salt that asks for more than `m` 262144, `t` 12, `p` 4 (a master in the
  middle could otherwise make it hash for minutes), before hashing anything.
- The device is enrolled with `pairedBy` = that account. It then signs in with the same password
  (§4); pairing alone opens no session.
- The digest is password-equivalent for pairing only: whoever stole it from the (encrypted) store
  could pair a device but not sign in, which still checks the password itself.

After pairing, every `/rpc` connection uses **mutual TLS**: the client presents its device
certificate and trusts only the installation CA it received. A revoked certificate still passes TLS
(it chains to the CA); the master refuses the WebSocket upgrade with `403` before any frame.

**The installation CA has two roots** of one key and one name. Native clients pin the plain one:
it never leaves Lyra's own TLS context. The one exported for web browsers carries critical name
constraints (private and link-local ranges, loopback, `.local`, the master's hostname), which
browsers and OS verifiers enforce. Dart's TLS refuses IP name constraints outright, so a native
client could not use that one.

**Web** clients pair from the browser with the code flow, run in the page (the CA is already
trusted by the OS, plan §5.3; `serverFingerprint` isn't checked there, the browser verified the
chain). The page is the master's own web build, so `/pair` and `/rpc` always go to the page's
origin. The "device certificate" of a browser is a **non-extractable WebCrypto key** (ECDSA
P-256) made for the pairing and kept in IndexedDB as a `CryptoKey`: scripts can sign with it but
never read it. Clearing the site data drops it, and that browser pairs again.

The browsers' root reaches a computer from a native device that is paired already (its channel
is pinned): `devices.browserCa` answers `{certificate, fingerprint, thumbprint, host, addresses, port}`
(`host` is the master's `.local` name, plan §5.2, which a browser opens first; `null` before its company exists),
and the app installs it in the user's trust store (Windows `certutil -user`, macOS
`security add-trusted-cert`; the OS asks first) or saves it as a `.crt` for another computer,
whose install dialog shows the SHA-1 `thumbprint` (Windows) or the SHA-256 `fingerprint` to
compare. On `/rpc` without a client certificate, the `hello` answer carries a `challenge`; the
browser signs `"lyra/device/prove/v1" ‖ 0 ‖ instanceId ‖ 0 ‖ challenge` and sends it with
`device.prove {deviceId, signature}` before anything else (`DeviceProof` in `lyra_protocol`).

---

## 4. Handshake and session

1. The first frame on `/rpc` must be `hello`:
   ```json
   {"id": 1, "op": "hello", "args": {"protocol": 1, "app": "0.0.7", "platform": "windows"}}
   ```
   Answer: `{protocol, engine, minApp, instanceId, state, challenge?}`. `state` is `ready` or
   `locked` (passphrase mode, plan §6.2). `challenge` (base64, 32 bytes) comes only on a connection
   without a client certificate: a browser signs it (`device.prove`, §3).
   - A protocol the master doesn't speak → `version_mismatch` with `action: "update"`, and the
     connection closes.
   - `app < minApp` → `update_required` with `action: "update"`.
2. While `locked`, only `hello` and (from the master's own device) `engine.unlock` are
   accepted; everything else answers `locked`.
3. `auth.*` ops (`session.md`) give tokens:
   `{accessToken, accessExpires, refreshToken, refreshExpires}` (`auth.signIn` adds `accountId` and
   `mustChangePassword`). Then `session.bind {accessToken}` ties the connection to that session
   (answer `{accountId, expires}`). Every later frame runs as that account on that device.
4. Before the access token expires, the client calls `auth.refresh` and `session.bind` again on
   the same connection. A frame that arrives with an expired binding answers `session_expired`
   (`action: "login"` only when the refresh also fails).

Keepalive: WebSocket ping every 20 s. (`dart:io` closes a connection whose pong doesn't come back
within one interval, not three; the difference is accepted.)

The master closes the connection after `version_mismatch` (close code 4002), `session_revoked`
(4003) and when the device is revoked (4001).

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
  `table/changed` (`Events` in `lyra_protocol`). The `XLanSource` feeds them to the same
  `receive(...)` seams. The engine emits `business/changed` from the business release,
  `table/changed` and `stock/changed` from the inventory release, `table/normalizing` and
  `table/ready` from the import release, `invoice/*` from the POS release, and `sale/progress` from
  the sales release.
- The app subscribes once its session is ready (`LanService`), and hands each event to the
  handlers of `ConnectionService.on`, the same ones the cloud's socket feeds. A reconnect asks for
  `since` the last seq it handed over; `resync_required` fires `ConnectionService.onRestored`.

---

## 6. Files

- **Upload** `PUT /f` with `Content-Type` and `X-Lyra-Purpose` (`logo`, `product_image`,
  `import`, `picture`). Limits per purpose: 5 MB, 10 MB, 20 MB, 5 MB. The master checks the real
  type from the bytes, not the header (`invalid_file`). Answer: `{fileId}`. An uploaded file
  that no op references within 1 hour is deleted. An `import` upload is read once, by the op it
  was made for, and deleted right after (`inventory.md` I-40).
- **Download** `GET /f/<fileId>[?size=<n>]`: `size` picks a stored thumbnail (images only). A
  master keeps one, 320 px wide (`FileSizes.thumbnail`), made at upload: `size` ≤ 320 answers it,
  a larger one or an image already that small answers the original. A JPEG thumbnail stays JPEG,
  the rest become PNG.
  Permission: the one that reads the record the file belongs to; a product image is also
  readable with `pos.view` (a till draws the pictures without seeing the inventory). Export files (`export.*`) are
  readable only by the account that asked for them, for 1 hour; they are made by the master and
  never uploaded (`export` is not an `X-Lyra-Purpose`).
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
| session | `auth.identify`, `auth.signIn`, `auth.signInPin`, `auth.activate`, `auth.refresh`, `auth.signOut`, `account.changePassword`, `account.setPin`, `session.bootstrap`, `permissions.of`, `permissions.set`, `permissions.requests.list`, `permissions.requests.create`, `permissions.requests.inbox`, `permissions.requests.answer`, `devices.list`, `devices.rename`, `devices.revoke`, `pairing.start`, `devices.browserCa` |
| business | `business.create`, `business.profile`, `business.edit`, `business.setLogo`, `business.site.get`, `business.site.edit`, `catalog.get` |
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

Both answered in phase 3:

1. ~~CPace or SPAKE2?~~ SPAKE2 (RFC 9382), for both the code and the QR (§3). Implemented in
   `lyra_protocol` over `pointycastle`, with the RFC's vectors as tests. Its EC arithmetic isn't
   constant time; with a one-use secret, three attempts and a 5-minute life, that is accepted and
   goes to the phase 7 review.
2. ~~Is a WebCrypto non-extractable key strong enough as a browser's device identity?~~ Yes, with
   the stated cost: it survives until the site data is cleared, and then that browser pairs again.
