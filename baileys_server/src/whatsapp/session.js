const { EventEmitter } = require("events");
const fs = require("fs");
const { Boom } = require("@hapi/boom");
const QRCode = require("qrcode");
const {
  default: makeWASocket,
  useMultiFileAuthState,
  DisconnectReason,
  fetchLatestBaileysVersion
} = require("@whiskeysockets/baileys");

const { authDir } = require("../store/paths");
const { DEVICE_BROWSER, ensurePairedAsCurrentDevice } = require("./device");
const { SessionState, buildStatus } = require("./status");
const { mapMessage } = require("./message-mapper");
const Backoff = require("../util/backoff");

/// WhatsApp's own delivery states, in the vocabulary the backend records them
/// under (`status/post.js`). Both spellings are accepted because the value is
/// a numeric enum on the wire and its name in some of Baileys' own paths, and
/// a receipt read as neither is a tick nobody ever sees.
const RECEIPT_STATUS = {
  0: "failed",
  2: "sent",
  3: "delivered",
  4: "read",
  // "Played" is a voice note that was listened to — read, as far as any
  // conversation history is concerned.
  5: "read",
  ERROR: "failed",
  SERVER_ACK: "sent",
  DELIVERY_ACK: "delivered",
  READ: "read",
  PLAYED: "read"
};

/// How old a message delivered as `append` may be and still be relayed, in
/// seconds. `notify` is WhatsApp saying "this just arrived"; `append` is
/// everything else it puts in a chat — a history sync on reconnect, a copy of
/// something sent from another device, and, occasionally, a live message that
/// simply did not come through the notification path. Only the last of those
/// is a customer waiting for an answer, and time is what tells it from a
/// two-week-old chat being replayed after a relink.
///
/// Relaying it is safe against the obvious objection: the backend keys
/// deduplication on WhatsApp's own message id (`Turns.duplicated`), so a
/// message that arrives both ways is stored, answered and billed once.
const APPEND_MAX_AGE_SECONDS = 120;

/// A bare number to the address WhatsApp routes by. Accepts a JID unchanged,
/// so a caller that already has one never builds `x@s.whatsapp.net@s.whatsapp.net`.
function toJid(to) {
  return `${to}`.includes("@") ? `${to}` : `${to}@s.whatsapp.net`;
}

/// One WhatsApp linked device, wrapping exactly one Baileys socket.
///
/// Emits four events upward, which is all `SessionManager` and the backend
/// link need: `status` (any time the reported state changes — QR issued,
/// connected, dropped, ...), `message` (a normalized inbound message, already
/// mapped, ready to forward as-is), `receipts` (what happened to messages this
/// number sent) and `presence` (the other end is typing).
///
/// Reconnection is handled here, not by the caller: an unexpected drop
/// retries with backoff on its own, because that is what "stays available
/// even if nobody is watching" requires. A `stop()` or `logout()` is the
/// only thing that turns retries off, via `_manualStop` — otherwise a
/// deliberate stop would look identical to a dropped connection and reconnect
/// itself right back up.
class WhatsappSession extends EventEmitter {
  constructor(id, logger) {
    super();
    this.id = id;
    this._logger = logger.child({ sessionId: id });
    this._sock = null;
    this._manualStop = false;
    this._backoff = new Backoff({ baseMs: 2000, maxMs: 60000 });
    this._reconnectTimer = null;
    this._status = buildStatus(id, { state: SessionState.STOPPED });
    /// Chats WhatsApp has actually reported presence for, so the first report of
    /// each can be logged once. It answers the one question nothing else here
    /// can: whether the subscription works at all. A contact whose privacy
    /// settings hide "last seen and online" from numbers they have not saved is
    /// reported as `unavailable` and never as `composing`, and a subscription
    /// that was never accepted is reported as nothing whatsoever — silence that
    /// is otherwise indistinguishable from a customer who does not type.
    this._presenceSeen = new Set();
  }

  get status() {
    return this._status;
  }

  async start() {
    this._manualStop = false;
    clearTimeout(this._reconnectTimer);

    // A socket left over from a previous `start()` has to go before another
    // one opens: WhatsApp allows a single live connection per set of
    // credentials, so a second one makes it close the first with
    // `conflict: replaced` — which the first socket's own handlers would then
    // read as an unexpected drop and answer by reconnecting, replacing the
    // new socket in turn. That is an endless connect/replace loop, so the old
    // socket is dropped here and its events ignored from this point on.
    this._discardSocket();

    this._setStatus({ state: SessionState.STARTING, lastError: null });

    const dir = authDir(this.id);
    fs.mkdirSync(dir, { recursive: true });
    ensurePairedAsCurrentDevice(dir, this._logger);

    const { state, saveCreds } = await useMultiFileAuthState(dir);

    // Kept on the instance because `_announceAvailable` writes to the credentials
    // (see the note there) and runs later, from the connection handler.
    this._saveCreds = saveCreds;
    const { version } = await fetchLatestBaileysVersion();

    const sock = makeWASocket({
      version,
      auth: state,
      logger: this._logger.child({ lib: "baileys" }),
      printQRInTerminal: false,
      syncFullHistory: false,
      // What the phone's "Linked devices" list shows for this session; see
      // `device.js` for why changing it forces a re-pair.
      browser: DEVICE_BROWSER
    });

    this._sock = sock;

    // Every handler ignores the socket it belongs to once it is no longer the
    // current one — Baileys keeps emitting on a closing socket, and acting on
    // that is what turns one replaced connection into a loop.
    const isCurrent = () => this._sock === sock;

    sock.ev.on("creds.update", () => isCurrent() && saveCreds());
    sock.ev.on("connection.update", (update) => {
      if (isCurrent()) this._onConnectionUpdate(update);
    });
    sock.ev.on("messages.upsert", (payload) => {
      if (isCurrent()) this._onMessagesUpsert(payload);
    });
    sock.ev.on("messages.update", (updates) => {
      if (isCurrent()) this._onMessagesUpdate(updates);
    });
    sock.ev.on("presence.update", (update) => {
      if (isCurrent()) this._onPresenceUpdate(update);
    });
  }

  /// Detaches the current socket: it stops being `this._sock` first, so
  /// anything it still emits while closing is ignored, and only then is it
  /// closed. Status and the reconnect timer are the caller's business.
  _discardSocket() {
    const sock = this._sock;
    if (!sock) return;

    // Subscriptions do not survive a socket, so neither does what was heard on
    // one: the next connection has to prove for itself that presence arrives.
    this._presenceSeen.clear();

    this._sock = null;

    try {
      sock.end(undefined);
    } catch (error) {
      this._logger.warn({ err: error }, "Failed to close the previous socket");
    }
  }

  /// Soft stop: closes the socket but keeps the auth folder, so `start()`
  /// later reconnects without a new QR. Used for "pause this connection"
  /// from the app.
  async stop() {
    this._manualStop = true;
    clearTimeout(this._reconnectTimer);
    this._discardSocket();
    this._setStatus({ state: SessionState.STOPPED });
  }

  /// Hard stop: unlinks the device on WhatsApp's side and deletes the local
  /// auth folder. There is no way back except a fresh QR.
  async logout() {
    this._manualStop = true;
    clearTimeout(this._reconnectTimer);

    try {
      await this._sock?.logout();
    } catch (error) {
      this._logger.warn({ err: error }, "logout() on an already-dead socket");
    }

    this._discardSocket();
    fs.rmSync(authDir(this.id), { recursive: true, force: true });
    this._setStatus({ state: SessionState.LOGGED_OUT });
  }

  /// `content` is passed straight through to Baileys' `sendMessage` (e.g.
  /// `{ text: "hi" }`, `{ image: { url }, caption }`) — this stays a thin
  /// pass-through on purpose so every content type Baileys supports keeps
  /// working without this file tracking Baileys' own schema.
  async sendMessage(to, content) {
    if (!this._sock || this._status.state !== SessionState.CONNECTED) {
      throw new Error(`Session "${this.id}" is not connected`);
    }

    const jid = toJid(to);
    const result = await this._sock.sendMessage(jid, content);
    return result?.key?.id ?? null;
  }

  /// Marks messages as read, which is what puts the blue ticks on the
  /// customer's side.
  ///
  /// **It takes the whole burst, and that is not a convenience.** A read
  /// receipt here is not a watermark: `readMessages` marks exactly the keys it
  /// is handed and says nothing about what came before them, unlike the Cloud
  /// API, where naming the newest marks the rest of the chat. Naming one of a
  /// burst of four is three grey ticks and one blue — the customer split one
  /// thought across four bubbles and watched us read the last of them.
  async readMessages(to, messageIds) {
    if (!this._sock) throw new Error(`Session "${this.id}" is not connected`);

    const jid = toJid(to);

    // `fromMe: false` because this is only ever used on what the customer
    // sent: reading one's own message means nothing.
    const keys = [...new Set((Array.isArray(messageIds) ? messageIds : [messageIds]).filter(Boolean).map(id => `${id}`))]
      .map(id => ({ remoteJid: jid, id, fromMe: false }));

    if (!keys.length) return;

    // One call for the lot: Baileys sends them as a single receipt, so a burst
    // turns blue at once rather than ticking over one bubble at a time.
    await this._sock.readMessages(keys);
  }

  /// "escribiendo…", or the account showing as online. `to` is required for
  /// the per-chat states and ignored by the account-wide ones.
  async sendPresence(state, to = null) {
    if (!this._sock) throw new Error(`Session "${this.id}" is not connected`);

    await this._sock.sendPresenceUpdate(state, to ? toJid(to) : undefined);
  }

  /// Asks WhatsApp to report when this contact starts and stops typing.
  ///
  /// Nothing is delivered without it — presence is a subscription, not a
  /// broadcast — and the backend has an endpoint that exists purely to be told
  /// about it (`presence/post.js`), so this is what makes that endpoint
  /// reachable at all. Best-effort: a failed subscription costs a signal, not
  /// a message.
  async subscribeToPresence(jid) {
    try {
      await this._sock?.presenceSubscribe(jid);
    } catch (error) {
      this._logger.debug({ err: error, jid }, "Could not subscribe to presence");
    }
  }


  /// **Declares this account available, which is what makes typing signals
  /// arrive at all.**
  ///
  /// WhatsApp does not push presence to a client that has not said it is
  /// there: `presenceSubscribe` alone subscribes to nothing. Baileys sends that
  /// `available` itself on connect (`markOnlineOnConnect`) — and refuses to when
  /// the account carries no name, which is not an edge case: a companion device
  /// paired from a phone that never set a WhatsApp profile name has
  /// `creds.me.name` empty, and the only trace is one line in the library's own
  /// log:
  ///
  ///     no name present, ignoring presence update request...
  ///
  /// Everything downstream then fails silently and identically to a customer who
  /// simply does not type: no `presence.update` ever fires, `POST /presence`
  /// is never called, and the backend closes every burst on the silence window
  /// alone — so an answer that took forty seconds to write goes out on top of
  /// somebody halfway through their next message.
  ///
  /// The name is filled in from what WhatsApp itself already knows, and only
  /// when it is missing. It travels in the presence node and is the pushName a
  /// contact who has not saved this number would see, so the fallback is the
  /// number: exactly what such a contact sees when there is no pushName at all.
  ///
  /// Best-effort throughout — a session that cannot announce itself still
  /// relays messages, just without knowing when the other end is writing.
  async _announceAvailable(phone) {
    const sock = this._sock;
    if (!sock) return;

    try {
      const me = sock.authState?.creds?.me;

      if (me && !me.name) {
        me.name = me.verifiedName || me.notify || phone || this.id;
        await this._saveCreds?.();
        this._logger.info({ name: me.name }, "Account had no name; filled it in so presence can be reported");
      }

      // Sent again from here rather than relied upon: Baileys' own attempt runs
      // during the initial queries, which is before (or racing) the name above.
      await sock.sendPresenceUpdate("available");
      this._logger.info("Marked available — the customer's typing state will be reported");
    } catch (error) {
      this._logger.warn({ err: error.message }, "Could not mark the account available; typing signals will not arrive");
    }
  }

  async _onConnectionUpdate(update) {
    const { connection, lastDisconnect, qr } = update;

    if (qr) {
      const qrImage = await QRCode.toDataURL(qr).catch(() => null);
      this._setStatus({ state: SessionState.QR_PENDING, qr, qrImage, lastError: null });
      return;
    }

    if (connection === "open") {
      this._backoff.reset();
      const rawJid = this._sock?.user?.id ?? null;
      const phone = rawJid ? rawJid.split(":")[0].split("@")[0] : null;
      this._setStatus({ state: SessionState.CONNECTED, phone, lastError: null });
      await this._announceAvailable(phone);
      return;
    }

    if (connection === "close") {
      const statusCode = lastDisconnect?.error instanceof Boom
        ? lastDisconnect.error.output?.statusCode
        : null;

      if (this._manualStop) return;

      // Something else opened a connection with these same credentials.
      // Reconnecting would take the session back and kick that one out, which
      // it would answer in kind — so this stops instead of starting a tug of
      // war, and says why. Only a deliberate `start()` brings it back.
      if (statusCode === DisconnectReason.connectionReplaced) {
        this._discardSocket();
        this._setStatus({
          state: SessionState.ERROR,
          lastError: "Another connection took over this session"
        });
        return;
      }

      if (statusCode === DisconnectReason.loggedOut) {
        fs.rmSync(authDir(this.id), { recursive: true, force: true });
        this._setStatus({
          state: SessionState.LOGGED_OUT,
          lastError: "Device was unlinked from WhatsApp"
        });
        return;
      }

      this._setStatus({
        state: SessionState.RECONNECTING,
        lastError: lastDisconnect?.error?.message ?? null
      });

      const delay = this._backoff.next();
      this._reconnectTimer = setTimeout(() => {
        this.start().catch((error) => {
          this._logger.error({ err: error }, "Reconnect attempt failed");
          this._setStatus({ state: SessionState.ERROR, lastError: error.message });
        });
      }, delay);
    }
  }

  /// **Every message this account receives passes through here, and until now
  /// two of them could leave without a trace.** Both skips below used to be a
  /// bare `return`/`continue`, which is the worst shape a drop can have on this
  /// path: WhatsApp has the message, the customer can see it on their screen,
  /// and this process — the only thing that can see WhatsApp at all — says
  /// nothing. Measured on a real conversation: "No, mejor una de 34$" written
  /// between a question and its answer, never logged here, never relayed, never
  /// answered, and no line anywhere in the platform to point at (04/09/2026).
  async _onMessagesUpsert({ messages, type }) {
    // `notify` is the ordinary live delivery. Anything else is WhatsApp filling
    // a chat in for some other reason, and it is dropped by default because
    // most of it is a history sync — but a RECENT one is not, and dropping that
    // is a customer who was never answered. See `APPEND_MAX_AGE_SECONDS`.
    if (type !== "notify") {
      const now = Math.floor(Date.now() / 1000);
      const fresh = (messages ?? []).filter((raw) => {
        const at = Number(raw?.messageTimestamp) || 0;

        return raw?.message && !raw.key?.fromMe && at > 0 && (now - at) <= APPEND_MAX_AGE_SECONDS;
      });

      if (fresh.length === 0) {
        this._logger.debug(
          { type, count: messages?.length ?? 0 },
          "Messages that are not a live delivery — not relayed"
        );

        return;
      }

      this._logger.warn(
        { type, count: fresh.length, ids: fresh.map((raw) => raw.key?.id ?? null) },
        "Message(s) delivered as something other than a live notification but written just now — relayed anyway"
      );

      messages = fresh;
    }

    for (const raw of messages) {
      // No content to read. Usually a protocol message with nothing in it for a
      // person, but it is also what a message that could NOT BE DECRYPTED looks
      // like from here — and that one is a customer's sentence this device is
      // holding and cannot read. Baileys retries the decryption and the retry
      // arrives as its own upsert, so there is nothing to relay right now;
      // what there is, is a line saying a message came in unreadable, so a
      // conversation that goes quiet has something to point at.
      if (!raw.message) {
        this._logger.warn(
          { messageId: raw.key?.id ?? null, from: raw.key?.senderPn || raw.key?.remoteJid || null, fromMe: Boolean(raw.key?.fromMe) },
          "Message arrived with no readable content (undecrypted or protocol-only) — not relayed"
        );

        continue;
      }

      // Subscribed from the raw key, before the message is even mapped:
      // somebody who just wrote is somebody who may write again in a second, and
      // mapping a photo means downloading it — seconds in which the second
      // message is typed with nothing subscribed to hear it.
      if (!raw.key?.fromMe && raw.key?.remoteJid) {
        this.subscribeToPresence(raw.key.remoteJid);
      }

      try {
        const mapped = await mapMessage(this._sock, raw, this._logger);

        this._logger.info(
          { from: mapped.from, type: mapped.type, text: mapped.text },
          "Message received"
        );

        this.emit("message", mapped);
      } catch (error) {
        this._logger.error({ err: error }, "Failed to map incoming message");
      }
    }
  }

  /// What happened to messages **this** number sent: the second tick, the blue
  /// ticks, a failure. Only the phone can see any of it — it is the thing that
  /// sent the message — which is why the backend has an endpoint waiting for
  /// it and no way to find out on its own.
  _onMessagesUpdate(updates) {
    const receipts = [];

    for (const { key, update } of updates ?? []) {
      // An update on a message somebody else sent is not a receipt; it is an
      // edit, a revoke or a reaction, none of which this reports.
      if (!key?.fromMe || !key.id) continue;

      const status = RECEIPT_STATUS[update?.status];
      if (!status) continue;

      receipts.push({
        id: key.id,
        to: key.remoteJid ? key.remoteJid.split("@")[0].split(":")[0] : null,
        status,
        timestamp: Math.floor(Date.now() / 1000)
      });
    }

    if (receipts.length > 0) this.emit("receipts", receipts);
  }

  /// Somebody on the other end started or stopped typing. Only arrives for
  /// chats this session subscribed to (`subscribeToPresence`) **and** only
  /// while this account is itself available (`_announceAvailable`).
  ///
  /// The state is read off whichever participant the node carries rather than
  /// off the chat id: Baileys keys the map by `participant || from`, and the two
  /// are not the same string on a chat addressed by LID — a lookup by chat id
  /// alone comes back undefined there and the signal is dropped in silence,
  /// which is the same nothing as never having subscribed.
  ///
  /// `paused` never reaches here as itself: Baileys rewrites it to `available`
  /// (`handlePresenceUpdate`), so "they stopped typing" and "they are online"
  /// are the same word by the time this runs. Telling them apart needs to know
  /// what this chat was doing a moment ago, which is the relay's business
  /// (`BackendLink.onPresence`), not this one's — everything WhatsApp said is
  /// passed up unchanged.
  _onPresenceUpdate({ id, presences }) {
    if (!id || !presences) return;

    const state = presences[id]?.lastKnownPresence
      ?? Object.values(presences)[0]?.lastKnownPresence;

    if (!state) return;

    if (!this._presenceSeen.has(id)) {
      this._presenceSeen.add(id);
      this._logger.info({ chat: id, state }, "WhatsApp is reporting presence for this chat");
    }

    this.emit("presence", { from: id.split("@")[0].split(":")[0], chat: id, state });
  }

  _setStatus(patch) {
    // The QR is only meaningful while waiting to be scanned: carrying a
    // stale one into every later state (connected, reconnecting, ...) would
    // have the app keep showing a dead QR code.
    const clearQr = patch.state !== SessionState.QR_PENDING
      ? { qr: null, qrImage: null }
      : {};

    this._status = buildStatus(this.id, {
      ...this._status,
      ...clearQr,
      ...patch
    });
    this.emit("status", this._status);
  }
}

module.exports = WhatsappSession;
