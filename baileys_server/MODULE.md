# baileys_server — WhatsApp sidecar

Standalone Node.js process (not Flutter) run as a local sidecar by the desktop app. Wraps
[Baileys](https://github.com/WhiskeySockets/Baileys) (unofficial, QR-linked WhatsApp Web
multi-device) and only **relays** between WhatsApp numbers and the backend — it never
interprets or answers messages. Separate npm project: `flutter analyze`/`flutter test` do not
cover it.

Why it exists: the `connections` section models WhatsApp through Meta's Cloud API. Baileys
(no app review, no per-message cost, QR login) needs a long-running process to hold the
WhatsApp Web session, which cannot live inside the Flutter app.

## Architecture

```
WhatsApp <---> Baileys socket <---> this server ---> backend  (HTTP, outbound)
                                         ^     <--- backend  (socket.io, outbound)
                                         | localhost HTTP (control API)
                                    Lyra desktop app
```

- **Detached**: the app spawns it once; closing the app does not stop it — only
  `POST /control/shutdown` does.
- **Multi-session**: many numbers per process, each keyed by a session id the app supplies
  (its channel id; opaque here).
- **Outbound only** (the machine is behind NAT): reports go out over HTTP, answers come in on a
  socket.io connection this server opened.
- **Backend identity = the desktop app's own user session**, pushed via `PUT /backend`. No
  server API key. `CONTROL_API_KEY` gates only the local control API.

## Files

- `package.json` — deps (`@whiskeysockets/baileys` `express` `ws` `socket.io-client` `pino` `qrcode` `dotenv` `@hapi/boom`); `npm start` / `npm run dev`.
- `.env.example` — every env var; `src/config.js` is the only reader of `process.env`.
- `src/config.js` — env loading and validation.
- `src/logger.js` — `pino`, console + `data/server.log`.
- `src/index.js` — entry: wires `SessionManager` ↔ `BackendLink` ↔ control API, restores sessions, graceful shutdown.
- `src/util/pid-file.js` — single-instance guard (`data/baileys_server.pid`).
- `src/util/backoff.js` — exponential backoff (WhatsApp reconnects, backend link).
- `src/store/paths.js` — one session's auth folder layout.
- `src/store/registry.js` — persisted session ids (`data/registry.json`), reconnected on boot.
- `src/whatsapp/device.js` — linked-device identity (`Browsers.windows("Lyra")`) + `ensurePairedAsCurrentDevice`.
- `src/whatsapp/status.js` — `SessionState` enum and the status shape.
- `src/whatsapp/message-mapper.js` — `WAMessage` → flat message; inlines media as base64 up to `MEDIA_INLINE_MAX_BYTES`.
- `src/whatsapp/session.js` — `WhatsappSession`: one socket + reconnect loop; `start stop logout sendMessage readMessages sendPresence subscribeToPresence _announceAvailable`; emits `status message receipts presence`.
- `src/whatsapp/session-manager.js` — `SessionManager`: all sessions by id, re-emits events, registry.
- `src/backend/credentials.js` — the borrowed app session (url, token, device, business, language) in `data/backend.json`.
- `src/backend/client.js` — `BackendClient`/`BackendError`: the `cygnus/v1/whatsapp_personal` HTTP routes.
- `src/backend/socket.js` — `BackendSocket`: socket.io, authenticated with the same session.
- `src/backend/link.js` — `BackendLink`: session id ↔ number map, announce/release, inbound queue + retry, serialized/deduped answers, acks.
- `src/control/app.js` — Express app. `src/control/auth-middleware.js` — `x-api-key` check.
- `src/control/events.js` — `EventHub`: the `/events` WebSocket broadcast.
- `src/control/routes/health.js` · `sessions.js` · `backend.js` · `control.js` — see the API table.

## Control API (for the desktop app)

Base `http://<HOST>:<PORT>` (default `127.0.0.1:4001`). All routes except `GET /health` need
`x-api-key: <CONTROL_API_KEY>`.

| Method & path | Purpose |
|---|---|
| `GET /health` | `{ ok, pid, startedAt, uptimeSeconds, backendConfigured, backendLinkConnected, linkedNumbers }`. No key (tells "down" from "unauthorized"). `startedAt` lets the app spot stale code. |
| `GET /sessions` | Every session's status. |
| `POST /sessions` `{id}` | Create if new and start. Idempotent. |
| `GET /sessions/:id` | `{id, state, phone, qr, qrImage, lastError, updatedAt}`. |
| `POST /sessions/:id/start` | (Re)start a stopped/errored session. |
| `POST /sessions/:id/stop` | Soft stop, keeps auth. |
| `POST /sessions/:id/logout` | Hard stop: unlink device, delete auth (new QR needed). |
| `DELETE /sessions/:id` | Stop + wipe auth + forget. |
| `POST /sessions/:id/send` `{to, message}` | Manual send for testing; `message` passed straight to Baileys. |
| `GET /backend` | `{ configured, url, device, business, language, connected, sessions }`. Never the token. |
| `PUT /backend` `{url, token, device, business, language?}` | Hand over the app session; reconnects the socket and re-announces every number. |
| `DELETE /backend` | Stop relaying (sign-out). WhatsApp sessions untouched. |
| `POST /control/shutdown` | Graceful process shutdown — the only way to stop it. |
| `GET /events` (WebSocket, `?key=`) | Live `session.status` / `message.received`. Broadcast only, no replay. |

`state`: `starting qr_pending connected reconnecting stopped logged_out error`. App indicator:
**active** = any `connected`; **inactive** = `/health` fails or all `stopped`/`logged_out`;
**error** = a session in `error`, or `backendConfigured && !backendLinkConnected` for a sustained period.

## Backend link

Optional: with no credentials pushed (and no `BACKEND_URL`), sessions, QR and control API work;
only the relay is off (one warning).

**Out — HTTP under `/cygnus/v1/whatsapp_personal`**, keyed by **phone number**, never session id.
Headers on every call: `Authorization: Bearer <token>`, `device`, `business_id`.

| When | Call |
|---|---|
| session reaches `connected` (every reconnect) | `POST /session` `{PHONE, LANGUAGE}` — announce + drain backlog |
| customer writes | `POST /messages` `{PHONE, MESSAGES[]}` |
| sent message gets ticks | `POST /status` `{PHONE, STATUSES[]}` |
| customer starts/stops typing | `POST /presence` `{PHONE, FROM, STATE}` |
| after announcing, or while socket is down (every 60 s) | `POST /outbox` `{PHONE}` (non-destructive) |
| answer sent (or failed) | `POST /outbox/ack` `{PHONE, ACKS[]}` |
| session stops / logs out | `DELETE /session/:PHONE` |

**In — socket.io**, `auth: {device, token, business_id}`; the handshake itself joins the room
(`session:<uid>:<did>`), so a stale token = answers emitted to nobody. Credential changes rebuild
the socket and re-announce.
- `whatsapp_personal/send` `{channel, ticket, to, text, part, parts, replayed?}` — one bubble; acked.
- `whatsapp_personal/signal` `{channel, to, state, on, messages, message}` — `read` / `typing` /
  `online`. `read` acts on the whole `messages` burst; `message` only as fallback.

## Rules that bite

- **One socket per session.** A second connection closes the first with `conflict: replaced`.
  `ensureStarted` never restarts a live session; `start()` detaches the old socket and handlers
  ignore stale sockets; `conflict: replaced` is **not** retried (→ `error`).
- **Device identity is frozen at QR scan.** `device.json` records what a session paired as; a
  mismatch wipes auth so the next start issues a QR. Changing `DEVICE_BROWSER` re-pairs everyone.
- **Typing needs three things**, each silently losable: the account announced available
  (`_announceAvailable` sets a name — Baileys refuses presence without one); a per-chat
  `presenceSubscribe` issued from the raw key before mapping (re-done after reconnect); the
  contact's privacy allowing it. Logs: first presence per chat (`session.js`), each typing
  episode (`link.js`). `paused` arrives as `available` — reported only if the contact was typing;
  throttled to one per contact per 5 s, never retried.
- **Retries**: inbound messages queued + retried with backoff, batched under the backend's 1 MB
  limit, 4xx dropped and logged. Statuses and typing never retried. Answers serialized per
  number and deduped by **ticket** (socket and outbox deliver the same ticket).
- **Not forwarded**: groups, status broadcasts, newsletters, own echoes — filtered by JID suffix.
  One-to-one is `@s.whatsapp.net` **or `@lid`**.
- **Number vs LID**: identity is the phone (`key.senderPn` on LID chats); the LID address is filed
  (`_remember`) and restored when replying or relaying a signal. No `senderPn` → the LID is the identity.

## Running it

```
cd baileys_server
npm install
cp .env.example .env    # set CONTROL_API_KEY (BACKEND_URL only if driving it by hand)
npm start               # or: npm run dev
```

Node 20+. Data (auth folders, `registry.json`, `backend.json`, `server.log`, pid) under
`DATA_DIR` (default `./data`, gitignored). Backend credentials never go in `.env`: the app
pushes them (`PUT /backend`).

## Flutter side

`lib/services/baileys` (see `lib/services/MODULE.md`) and the channels section
(`BaileysChannelSwitch`, `BaileysPairingModal`). **Launch is dev-time only**: `BaileysLauncher`
runs `node src/index.js` found by walking up from `Directory.current`. Shipping needs a packaged
server (bundled Node or `pkg`/`nexe`) resolved next to the app executable — a release-pipeline
decision, not solved here.
