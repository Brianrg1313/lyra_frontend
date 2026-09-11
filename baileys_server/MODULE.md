# baileys_server — WhatsApp sidecar

Standalone Node.js process (not part of the Flutter app), managed as a local sidecar by
the desktop app. Wraps [Baileys](https://github.com/WhiskeySockets/Baileys) (unofficial,
QR-linked WhatsApp Web multi-device client) and does nothing else: it is a relay between
one WhatsApp number and the business backend, never a place where messages are
interpreted or answered on its own.

This module is a separate npm project. `flutter analyze` / `flutter test` do not cover
it; see [Commands](#commands) below for its own toolchain.

## Why this exists

The existing `connections` section (`lib/screens/home/sections/connections`) models
WhatsApp through Meta's official Cloud API (`access_token`, `phone_number_id`, ...),
configured entirely from the backend's provider catalog. Baileys is a different,
unofficial integration path — no Meta app review, no per-message cost, login by
scanning a QR code — and needed its own server because it has to hold a persistent
WhatsApp Web session, which only makes sense as a long-running process, not inside the
Flutter app itself.

## Architecture

```
WhatsApp <---> Baileys socket <---> this server ---> backend  (HTTP, outbound)
                                         ^     <--- backend  (socket.io, outbound)
                                         | localhost HTTP (control API)
                                         |
                                    Lyra desktop app
```

- **Runs detached from the app.** The app starts it once (as a detached OS process, not
  a child tied to the app's lifetime) and from then on manages it purely through the
  control API. Closing the app does not stop it; only `POST /control/shutdown` (or
  killing the machine) does.
- **Multi-session.** One process holds many WhatsApp numbers at once, each identified by
  a `session id` the app supplies (its own connection id — this server has no opinion on
  what the id means).
- **No inbound connectivity required.** The desktop machine this runs on is typically
  behind NAT, so the backend never calls this server directly. Everything this server
  reports goes out as an HTTP request; everything the backend sends back arrives on a
  socket.io connection this server opened. Both directions are described under
  [Backend link](#backend-link).
- **The backend identifies this server by the desktop app's own user session.** There
  is no API key for it and nothing to configure: the app pushes its session token,
  device and business id in over the control API (`PUT /backend`), and every backend
  call carries them. `CONTROL_API_KEY` is unrelated — it gates the local HTTP API only —
  and so are a WhatsApp session's own credentials.

## Files

- `package.json` — dependencies (`@whiskeysockets/baileys`, `express`, `ws`,
  `socket.io-client`, `pino`, `qrcode`, `dotenv`, `@hapi/boom`) and `npm start` /
  `npm run dev`.
- `.env.example` — every environment variable the server reads (`src/config.js` is the
  single place that touches `process.env`); copy to `.env` before running.
- `src/config.js` — env loading and validation.
- `src/logger.js` — process-wide `pino` logger, console + `data/server.log`.
- `src/index.js` — entry point: wires `SessionManager` ↔ `BackendLink` ↔ the control API,
  restores sessions from the registry on boot, handles graceful shutdown.
- `src/util/pid-file.js` — single-instance guard (`data/baileys_server.pid`).
- `src/util/backoff.js` — shared exponential-backoff helper (WhatsApp reconnects and the
  backend link both use it).
- `src/store/paths.js` — filesystem layout for one session's Baileys auth folder.
- `src/whatsapp/device.js` — the linked-device identity WhatsApp shows (`Windows`, not
  Baileys' default `Ubuntu`) and the check that wipes an auth folder paired under a
  different one, since that identity is frozen at QR-scan time.
- `src/store/registry.js` — persisted list of session ids (`data/registry.json`), read on
  boot so a restart reconnects every previously configured number on its own.
- `src/whatsapp/status.js` — `SessionState` enum and the status object shape every
  consumer (control API, backend link) reads.
- `src/whatsapp/message-mapper.js` — raw Baileys `WAMessage` → the flat message shape
  sent to the backend; inlines small media as base64, sends metadata-only above
  `MEDIA_INLINE_MAX_BYTES`.
- `src/whatsapp/session.js` — `WhatsappSession`: one Baileys socket, its own reconnect
  loop with backoff, `start` / `stop` / `logout` / `sendMessage` / `readMessages` /
  `sendPresence` / `subscribeToPresence` / `_announceAvailable`; emits `status`, `message`,
  `receipts` (delivery ticks on what this number sent) and `presence` (the other end is
  typing — see [The customer is typing](#the-customer-is-typing)).
- `src/whatsapp/session-manager.js` — `SessionManager`: owns every `WhatsappSession` by
  id, re-emits their events, persists/restores the registry.
- `src/backend/credentials.js` — the desktop app's session as this server borrows it
  (url, token, device, business, language), persisted to `data/backend.json` because the
  process outlives the app that pushed it.
- `src/backend/client.js` — `BackendClient` / `BackendError`: the six
  `cygnus/v1/whatsapp_personal` routes over HTTP, with the app's session on every call.
- `src/backend/socket.js` — `BackendSocket`: the socket.io connection answers arrive on.
  Authenticates with the same session, which is also what puts it in the room the backend
  emits to.
- `src/backend/link.js` — `BackendLink`: the relay itself. Maps a local session id to the
  number the backend keys everything by, announces and releases numbers, queues and
  retries inbound messages, serializes and deduplicates answers going out, and acks them.
- `src/control/app.js` — the Express app for the local control API.
- `src/control/events.js` — `EventHub`: the `ws://.../events` broadcast the desktop app
  subscribes to for live status changes and inbound messages.
- `src/control/auth-middleware.js` — `x-api-key` check against `CONTROL_API_KEY`.
- `src/control/routes/health.js` — `GET /health` (no API key — liveness must be
  distinguishable from "running but rejecting me").
- `src/control/routes/sessions.js` — session CRUD + status + manual `send` for testing.
- `src/control/routes/backend.js` — `GET`/`PUT`/`DELETE /backend`: the session this server
  acts as when it talks to the backend.
- `src/control/routes/control.js` — `POST /control/shutdown`.

## Control API (for the desktop app)

Base URL `http://<HOST>:<PORT>` (default `127.0.0.1:4001`). Every route except
`GET /health` requires header `x-api-key: <CONTROL_API_KEY>`.

| Method & path | Purpose |
|---|---|
| `GET /health` | Liveness: `{ ok, pid, startedAt, uptimeSeconds, backendConfigured, backendLinkConnected, linkedNumbers }`. No key required — used to tell "not running" apart from "running but unauthorized". `startedAt` (epoch ms) is how the app spots a detached server still running pre-edit code. |
| `GET /sessions` | List every session's status. |
| `POST /sessions` `{id}` | Create (if new) and start a session. Idempotent. |
| `GET /sessions/:id` | One session's status: `{id, state, phone, qr, qrImage, lastError, updatedAt}`. |
| `POST /sessions/:id/start` | (Re)start a stopped/errored session. |
| `POST /sessions/:id/stop` | Soft stop: closes the socket, keeps auth (no QR needed to resume). |
| `POST /sessions/:id/logout` | Hard stop: unlinks the device and deletes its auth — a fresh QR is required afterward. |
| `DELETE /sessions/:id` | Removes the session entirely (stop + wipe auth + forget it). |
| `POST /sessions/:id/send` `{to, message}` | Manual send for testing from the app; `message` is passed straight through to Baileys (`{text: "..."}`, `{image: {url}, caption}`, ...). |
| `GET /backend` | Which backend session this server is acting as: `{ configured, url, device, business, language, connected, sessions }`. Never the token. |
| `PUT /backend` `{url, token, device, business, language?}` | Hands over the app's session — see [Identifying itself](#identifying-itself). Reconnects the socket and re-announces every held number. |
| `DELETE /backend` | Signing out: stops relaying. WhatsApp sessions are untouched. |
| `POST /control/shutdown` | Graceful shutdown of the whole process — the only way to stop it, since the app does not hold an OS handle to a detached process. |
| `GET /events` (WebSocket) | Live feed of `session.status` and `message.received` frames, same shapes as the backend link's. Key goes in the query string (`?key=...`). Broadcast only: nothing is queued or replayed, so a client that connects late sees only what happens next. |

`state` is one of `starting`, `qr_pending`, `connected`, `reconnecting`, `stopped`,
`logged_out`, `error` (`src/whatsapp/status.js`). Suggested mapping to a three-way
indicator in the app: **active** = any session `connected`; **inactive** = process
unreachable (`/health` fails) or every session `stopped`/`logged_out`; **error** =
process reachable but a session is `error`, or `backendLinkConnected` is `false` for a
sustained period while `backendConfigured` is `true` (unconfigured is the app's own
omission, not a fault of this server).

## One socket per session

WhatsApp accepts a single live connection per set of credentials; a second one makes it
close the other with `conflict: replaced`. That is easy to trigger by accident, because
both the boot-time `restoreAll()` and the app's own switch-on call `ensureStarted` on the
same session, and a closing socket keeps emitting events for a while after it is
replaced. Three rules keep it to one socket:

- `ensureStarted` returns the current status untouched when the session is already
  starting, waiting on a QR, connected or reconnecting — it never restarts a live one.
- `start()` detaches the previous socket before opening a new one, and every handler
  ignores events from a socket that is no longer the current one.
- a `conflict: replaced` close is **not** retried; the session goes to `error` with
  `lastError: "Another connection took over this session"`. Reconnecting would take the
  session back and get replaced again, forever — the loop this rule exists to stop.

## Linked-device identity

WhatsApp's "Linked devices" list shows the `os` field of the browser tuple Baileys sends
during the companion registration. The default (`Browsers.ubuntu("Chrome")`) is why an
unconfigured Baileys session appears as an Ubuntu machine; `src/whatsapp/device.js` sets
`Browsers.windows("Lyra")` instead.

That tuple is only read at QR-scan time and is then frozen into the entry on the phone —
changing it does nothing to a session that is already paired. `ensurePairedAsCurrentDevice`
therefore records what each session was paired as (`data/sessions/<id>/device.json`) and
deletes the auth folder when it no longer matches, so the next `start()` issues a QR and
the new identity actually takes effect. Editing `DEVICE_BROWSER` is a re-pair for every
existing session, on purpose.

## Identifying itself

The backend issues this server **no credential of its own** and stores none. There is no
third party in this integration — the relay runs on the company's machine, on the
company's session — so `POST /cygnus/v1/whatsapp_personal/session` authenticates it with
the desktop app's own user session, and the app is the only thing that has it.

The app therefore pushes it in over `PUT /backend`: `url`, `token`, `device`, `business`
and an optional `language`. Every call afterwards carries the same three headers a
request from the app carries — `Authorization: Bearer <token>`, `device` and
`business_id` — which is what lets `validate_session` and `validate_business` answer the
only two questions the backend has: who is asking, and for which company.

It is stored in `data/backend.json` (user-only) because this process outlives the app: a
machine that reboots overnight has to come back up relaying without anybody opening the
app first. It is pushed again on every activation and every refresh, so a new sign-in or
a switch of company reaches it without the app tracking what changed.

**A stale token is not a slow relay, it is a silent one.** The backend emits an answer to
the room of the session that announced the number (`session:<uid>:<did>`), so credentials
that no longer match are answers emitted where nobody is listening — which is why a
credential change rebuilds the socket and re-announces every held number.

## Backend link

**Optional.** With no credentials pushed (and no `BACKEND_URL`), sessions, QR pairing and
the control API all work on their own — only the relay stays off, logged once as a
warning. This is what lets the app-side feature work against a backend that is not
configured yet.

Two channels, both opened from here, because the desktop machine is behind NAT:

**Out, over HTTP** (`src/backend/client.js`), all under
`/cygnus/v1/whatsapp_personal`. The backend keys everything by the **number**, never by
this server's session id, so a session only exists to it once WhatsApp says which number
was linked:

| When | Call |
|---|---|
| a session reaches `connected` | `POST /session` `{PHONE, LANGUAGE}` — announces the number and gets back what it is owed. Sent on every reconnection, not just the first: that is the only moment a backlog can be drained. |
| a customer writes | `POST /messages` `{PHONE, MESSAGES[]}` — one message, or a batch after an outage. |
| a sent message gets its ticks | `POST /status` `{PHONE, STATUSES[]}` |
| the customer starts or stops typing | `POST /presence` `{PHONE, FROM, STATE}` — see [The customer is typing](#the-customer-is-typing) |
| after announcing, or while the socket is down | `POST /outbox` `{PHONE}` — reads the queue back; not destructive. |
| an answer was sent (or could not be) | `POST /outbox/ack` `{PHONE, ACKS[]}` — carries the id WhatsApp gave it, which is what renames the stored copy. |
| the session stops or is logged out | `DELETE /session/:PHONE` — the channel survives; only the holding stops. |

**In, over socket.io** (`src/backend/socket.js`), on the same session. Joining the room
answers are emitted to is not something a client asks for — it happens when the handshake
authenticates — so connecting with the session that announced the number *is* the
subscription. `auth: {device, token, business_id}`, which `SocketContext` folds into
headers so the same three middlewares that guard a route guard this:

- **`whatsapp_personal/send`** — `{channel, ticket, to, text, part, parts, replayed?}`:
  one bubble of an answer. Answered with an ack, above.
- **`whatsapp_personal/signal`** — `{channel, to, state, on, messages, message}`: blue
  ticks (`read`), "escribiendo…" (`typing`), the account showing online (`online`).
  `messages` is the **whole burst**, oldest first, and it is the field `read` acts on:
  Baileys marks the keys it is handed and nothing else, so naming only the newest left a
  burst of four with three grey ticks and one blue. `message` is that newest id, kept for
  a backend that predates the list, and used only when `messages` is absent.

### The customer is typing

The one signal in this whole relay that the backend cannot infer for itself, and the one
that costs a customer a wrong answer when it goes missing: the pipeline holds an inbound
burst open while somebody is writing, so without it a question split across two messages
is answered after the first one. It is also, structurally, the easiest thing here to lose
in silence — nothing fails, nothing logs, and a relay that reports nothing looks exactly
like a customer who never types.

Three things all have to be true, and each one is a separate way to lose it:

- **This account has to be available.** WhatsApp does not push presence to a client that
  has not said it is there. Baileys sends that on connect (`markOnlineOnConnect`) — and
  **refuses to when the account has no name**, logging one line and returning:
  `no name present, ignoring presence update request...`. A companion device paired from a
  phone with no WhatsApp profile name has exactly that. `_announceAvailable` fills the name
  in from what WhatsApp already knows (falling back to the number, which is what an unsaved
  contact sees anyway) and re-sends `available` itself.
- **The chat has to be subscribed to.** Presence is a subscription, not a broadcast:
  `presenceSubscribe(jid)` per chat, issued from the raw message key before the message is
  even mapped, because mapping a photo means downloading it and the second message is typed
  during exactly those seconds. Subscriptions do not survive a socket, so a reconnected
  session re-subscribes on the next message it receives.
- **The contact has to allow it.** Somebody whose "last seen and online" privacy hides them
  from numbers they have not saved is reported as `unavailable` and never as `composing`.
  Nothing can be done about that one; what matters is being able to see it, which is what
  the log line below is for.

`WhatsappSession` logs the **first** presence report of each chat
(`WhatsApp is reporting presence for this chat`), and `BackendLink` logs each typing
**episode** (`Customer started typing` / `Customer stopped typing`) rather than each report.
Between them: no first line means the subscription or the availability is the problem, and
a first line reporting `unavailable` with nothing after it means the contact's privacy is.

Two more things this relay decides, because WhatsApp does not:

- **`paused` never arrives as itself.** Baileys rewrites it to `available`, so "stopped
  typing" and "is online" are the same word. `onPresence` tells them apart by whether the
  contact was reported typing a moment ago — and when in doubt says nothing, because
  reporting a pause that did not happen releases a hold the customer never released.
- **The identity, never the address.** A signal arrives keyed the way WhatsApp addresses the
  chat, which on a `@lid` chat is not the number the conversation is keyed by. Relayed as it
  comes in, it names a conversation the backend has never heard of and holds nothing. The
  pairing filed when a message came in (`_remember`) is read back the other way round.

Reports are throttled to one per contact per 5 s while typing continues (the backend
believes one report for longer than that) and never retried — a claim about attention that
has already moved on is worse than no claim.

### What is retried and what is not

Not a uniform policy, because the two directions fail differently:

- **Inbound messages are queued and retried** with backoff, batched by size against the
  backend's 1 MB parser limit. A message lost is a customer nobody answered. A 4xx is
  dropped rather than retried — the backend read it and said no — and logged loudly.
- **Statuses and typing signals are not.** Both are claims about a moment that has
  already passed by the time a retry would land, and the backend is written to tolerate
  losing them.
- **Answers going out are serialized per number and deduplicated by ticket.** The
  backend cuts a reply into parts that have to arrive in order, and the same ticket
  legitimately arrives twice — once over the socket, once from the outbox that still
  lists it until it is acked. The ticket decides, not the transport.
- **The outbox is polled only while the socket is down** (60 s). On a healthy link it
  would only fetch answers already delivered.

### What is not forwarded

Group chats, status broadcasts and newsletters, and this number's own outgoing messages,
which WhatsApp echoes back over the same event. A group's id reduces to digits as
convincingly as a phone number does, so the filter is on the JID suffix, not on what
`from` looks like.

A one-to-one chat is `@s.whatsapp.net` **or `@lid`**, and the second one is not an edge
case: WhatsApp now addresses ordinary conversations by a "linked id"
(`279688287117520@lid`) that hides the number. A filter written for `@s.whatsapp.net`
alone drops those in silence — the phone logs the message, the backend never hears about
it, and nothing anywhere says why.

### Numbers and LIDs

The identity everything is keyed by is the **phone number**, taken from `key.senderPn`
when WhatsApp addresses the chat by LID. It is what the backend opens a conversation
under, what a person reading that chat expects to see, and what an answer comes back
addressed to.

Which means the LID still has to be kept: an answer arrives naming the identity (digits),
and on a LID chat those digits are not a number to write to — sending to them would build
`<lid>@s.whatsapp.net`, which is nobody. So the address WhatsApp actually used is filed
beside the identity when a message comes in, and put back when the reply goes out. A
contact WhatsApp gives no `senderPn` for falls back to the LID as its identity: keyed by
something that is not a phone number, but answerable, which is the better of the two.

## Running it

```
cd baileys_server
npm install
cp .env.example .env    # fill in CONTROL_API_KEY (BACKEND_URL only if driving it by hand)
npm start                # or: npm run dev (auto-restart on file change)
```

Requires Node 20+. Data (auth folders, `registry.json`, `backend.json`, `server.log`, the
pid file) lives under `DATA_DIR` (default `./data`), gitignored.

There is nothing to put in `.env` for the backend's credentials: the app supplies them
(`PUT /backend`). Driving this server without the app means making that call by hand with
a session token taken from a logged-in app.

## Flutter-side integration

Built, under `lib/services/baileys` — see that section of `lib/services/MODULE.md` and
the channels section's `MODULE.md` (`BaileysChannelSwitch`, `BaileysPairingModal`) for how
the app launches this server, holds the control API key, pushes the session this server
relays under (`BaileysClient.setBackend`, called from `BaileysService._identify`), and
drives sessions from the "WhatsApp Personal" channel type.

**Still dev-time only.** `BaileysLauncher` finds this folder by walking up from
`Directory.current` for `baileys_server/package.json` and runs `node src/index.js` in it
directly — true while the app runs via `flutter run` from the project root. Shipping this
to a real install needs the server packaged (a bundled Node runtime, or a `pkg`/`nexe`
executable) and `BaileysLauncher`'s resolution replaced with a path next to the app's own
executable; deliberately not solved here, since it is a packaging decision for the app's
release pipeline, not something this module or its launcher can guess at.
