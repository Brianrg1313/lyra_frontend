const config = require("../config");
const credentials = require("./credentials");
const { BackendClient, BackendError } = require("./client");
const BackendSocket = require("./socket");
const Backoff = require("../util/backoff");

/// Most messages folded into one `POST /messages`. Only ever reached by a
/// phone that was offline and came back with a burst — the ordinary case sends
/// one message the moment it arrives.
const MAX_BATCH = 25;

/// Bytes of JSON one delivery may add up to. The backend parses at most 1 MB
/// of body, so this leaves room for the envelope around the payload; a batch
/// that would cross it is split rather than rejected whole.
const MAX_BATCH_BYTES = 800 * 1024;

/// Most inbound messages one number may have waiting for a backend that is not
/// taking them. Deliberately larger than any real burst: this is the ceiling
/// that stops a leak, not a rate limit.
const MAX_QUEUE = 500;

/// Contacts whose WhatsApp address is remembered per number. A conversation
/// nobody has written to in this long has no answer in flight either, and the
/// next message they send files them again before a reply is composed.
const ADDRESS_MEMORY = 2000;

/// Tickets remembered per number, to tell an answer that was already sent from
/// one that was not. Bounded because it is a leak otherwise, and generous
/// enough to cover a reconnection's whole replay several times over.
const TICKET_MEMORY = 500;

/// How often an announced number re-reads its queue over HTTP **while the
/// socket is down**. The socket is the fast path and this is the safety net;
/// polling on top of a healthy socket would only fetch answers it already got.
const OUTBOX_POLL_MS = 60000;

/// How long downloading one product photo from the backend may take before
/// the send fails (and is acked as failed). The answer's parts are sent in
/// order, so a photo that hangs holds up everything after it.
const DOWNLOAD_TIMEOUT_MS = 20000;

/// Least time between two "the customer is typing" reports for the same chat.
/// WhatsApp emits presence continuously while somebody types, and the backend
/// only needs to know that it is happening — the endpoint stores nothing, so
/// the second report in the same second buys nothing and costs a request.
const PRESENCE_THROTTLE_MS = 5000;

/// JID suffixes of a one-to-one chat with a person. Everything else WhatsApp
/// addresses — groups (`@g.us`), status broadcasts, newsletters — is not a
/// customer conversation and has no place in a pipeline built to answer one.
///
/// `@lid` is the second one and it is not an edge case: WhatsApp now addresses
/// an ordinary chat by a "linked id" that hides the number, and a guard written
/// for `@s.whatsapp.net` alone drops those messages **silently** — the phone
/// logs the message, the backend never hears about it, and nothing anywhere
/// says why. Measured: a real "prueba" received and never relayed.
const PERSON_SUFFIXES = ["@s.whatsapp.net", "@lid"];

/// **The relay itself**: WhatsApp on one side, the company's backend on the
/// other, and the translation between two models of the same conversation.
///
/// The two sides do not agree on what a session is, which is most of what this
/// class does. Locally a session is whatever id the app assigned — a channel
/// id it never explains. To the backend the identity is the **number**, and
/// nothing else: `Personal.resolve` reads the company off the session and the
/// conversation off the phone number, so an event this server cannot name a
/// number for is an event it cannot send at all. A session therefore only
/// exists to the backend once it reaches `connected` and WhatsApp says which
/// number was linked.
///
/// Nothing here is best-effort by accident. Inbound messages are queued and
/// retried, because a message lost is a customer who was never answered.
/// Statuses and typing signals are not, because both are claims about a moment
/// that has passed by the time a retry would land. Answers going out are
/// serialized per number and deduplicated by ticket, because the one failure
/// worse than a slow reply is the same reply sent twice, or its second half
/// sent first.
class BackendLink {
  constructor({ sessionManager, logger }) {
    this._sessions = sessionManager;
    this._logger = logger.child({ component: "backend-link" });
    this._client = new BackendClient(logger);
    this._socket = new BackendSocket(logger);

    /// One entry per local session, whether or not it has a number yet.
    this._entries = new Map();

    /// Reverse of the above, for routing what the backend sends: it addresses
    /// a number, and this server holds sessions.
    this._byPhone = new Map();

    this._stopped = false;

    /// Whether the "no session was pushed" warning has already been said. It
    /// is true once per process on purpose: it fires on every connected
    /// number, and repeating it says nothing new.
    this._warned = false;

    this._socket.on("send", (payload) => this._onSend(payload));
    this._socket.on("signal", (payload) => this._onSignal(payload));
    this._socket.on("connected", () => this._onSocketUp());

    // A new sign-in, or a different active business. The socket is rebuilt
    // (its room was decided at handshake time) and every number is announced
    // again, because the holder the backend has on file is the old session and
    // every answer would be emitted at a room nobody is in.
    credentials.on("change", () => this._onCredentialsChanged());
  }

  get isConnected() {
    return this._socket.isConnected;
  }

  get isConfigured() {
    return credentials.isSet;
  }

  /// Numbers this server has announced, for `/health` and the app's own view
  /// of whether the relay is really working.
  get linked() {
    return [...this._entries.values()]
      .filter((entry) => entry.phone)
      .map((entry) => ({
        session_id: entry.sessionId,
        phone: entry.phone,
        announced: entry.announced
      }));
  }

  start() {
    this._stopped = false;
    this._socket.connect();
  }

  stop() {
    this._stopped = true;

    for (const entry of this._entries.values()) {
      clearTimeout(entry.flushTimer);
      clearTimeout(entry.announceTimer);
      clearInterval(entry.pollTimer);
    }

    this._socket.close();
  }

  // #region WhatsApp -> backend

  /// A session changed state. Only two transitions mean anything to the
  /// backend: a number came on the air, and a number stopped being held.
  ///
  /// `reconnecting` and `error` are deliberately silent. There is no endpoint
  /// for them and no use for one — a phone that is struggling simply stops
  /// acking, and the backend already treats that as what it is.
  onStatus(status) {
    if (!status?.id) return;

    if (status.state === "connected" && status.phone) {
      this._announce(status.id, status.phone);
      return;
    }

    if (status.state === "stopped" || status.state === "logged_out") {
      this._release(status.id);
    }
  }

  /// One inbound WhatsApp message, already normalized. Queued rather than
  /// sent, so a backend that is down for a minute costs latency instead of
  /// conversations.
  onMessage(sessionId, message) {
    const entry = this._entries.get(sessionId);

    if (!entry?.phone) {
      // The number is unknown until the session connects, and there is no
      // endpoint that takes a message without one. This is normal exactly once
      // per session (a message racing the `connected` status) and a bug if it
      // keeps happening, which is why it is logged rather than dropped in
      // silence.
      this._logger.warn(
        { sessionId, messageId: message?.id },
        "Message arrived before the session reported its number — not relayed"
      );
      return;
    }

    if (!this._isCustomerMessage(message)) return;

    // How to write back to this person. The backend answers `to` with whatever
    // identity came in — digits, because that is what it keys a conversation by
    // — and on a chat WhatsApp addresses by LID those digits are not a phone
    // number: sending to them would build `<lid>@s.whatsapp.net`, which is
    // nobody. So the address WhatsApp actually used is kept beside the identity
    // and put back when the answer goes out.
    this._remember(entry, message);

    entry.inbox.push(this._toDelivery(message));

    // A queue with no ceiling is a memory leak with a company's name on it:
    // nothing drains while the backend is unreachable or no session has been
    // pushed yet, and WhatsApp keeps delivering regardless. The oldest goes,
    // because a customer's most recent message is the one still worth
    // answering.
    if (entry.inbox.length > MAX_QUEUE) {
      const dropped = entry.inbox.splice(0, entry.inbox.length - MAX_QUEUE);
      this._logger.error(
        { phone: entry.phone, dropped: dropped.length },
        "Inbound queue is full — the oldest messages were dropped unanswered"
      );
    }

    this._scheduleFlush(entry);
  }

  /// The ticks on messages this number sent. Best-effort by design: a status
  /// is a fact about a message the backend already has, and one that never
  /// arrives leaves the history readable with only its ticks unknown.
  onReceipts(sessionId, receipts) {
    const entry = this._entries.get(sessionId);

    if (!entry?.phone || !credentials.isSet || !receipts?.length) return;

    const updates = receipts.map((receipt) => ({
      MESSAGE_ID: receipt.id,
      STATUS: receipt.status,
      TIMESTAMP: receipt.timestamp
    }));

    this._client.statuses(entry.phone, updates).catch((error) => {
      this._logger.warn({ err: error.message, phone: entry.phone }, "Could not report statuses");
    });
  }

  /// The customer is typing — or has just stopped. Never queued and never
  /// retried: the endpoint holds a burst open on the strength of it being true
  /// *now*, and a report that arrives after a retry is a claim about attention
  /// that has already moved on.
  ///
  /// **Reported under the identity, not the address.** The signal arrives keyed
  /// the way WhatsApp addresses the chat, which on a LID chat is not the number
  /// the conversation is keyed by — reported as it comes in, it names a
  /// conversation the backend has never seen and holds nothing, silently.
  ///
  /// **"Stopped" is inferred, because WhatsApp does not say it.** Baileys
  /// rewrites `paused` to `available` before this sees it, so what comes back
  /// when somebody stops typing is indistinguishable from them merely being
  /// online. What tells the two apart is whether this contact was reported
  /// typing a moment ago: if it was, the state ending is the pause; if it was
  /// not, an `available` is somebody opening WhatsApp and means nothing here.
  /// Reporting it wrong in that direction would lift a hold the customer never
  /// released, so the doubt is resolved by saying nothing.
  onPresence(sessionId, presence) {
    const entry = this._entries.get(sessionId);

    if (!entry?.phone || !credentials.isSet || !presence?.state) return;

    const chat = `${presence.chat ?? ""}`;
    const from = entry.identities.get(chat) ?? presence.from;

    if (!from) return;

    // A LID chat this server has seen no message from yet has no number behind it, and the
    // LID's own digits are not one: reported, they name a conversation the backend has never
    // opened, hold nothing, and read in a log as if the signal were working. Silence is the
    // honest answer until the first message files the pairing (`_remember`), which is also
    // the first moment there is a burst to hold.
    if (chat.endsWith("@lid") && !entry.identities.has(chat)) return;

    const typing = presence.state === "composing" || presence.state === "recording";
    const now = Date.now();
    const last = entry.presence.get(from) ?? 0;

    if (typing) {
      // WhatsApp re-asserts this every few seconds while somebody keeps typing,
      // and the backend believes one report for longer than that — so the
      // throttle drops what is genuinely redundant and never the report that
      // extends the hold.
      if (now - last < PRESENCE_THROTTLE_MS) return;

      // One line per typing episode, not per report: the interesting event is
      // that the customer picked the keyboard up, and it is the only way to tell
      // "they never type" from "WhatsApp never told us" — which look identical
      // everywhere else, all the way to a backend that answers half a question.
      if (last === 0) {
        this._logger.info({ from, phone: entry.phone }, "Customer started typing");
      }

      entry.presence.set(from, now);
      this._report(entry, from, "composing");

      return;
    }

    // Not typing, and never was as far as this knows: an online blip, nothing
    // to report. (A contact whose typing was throttled away entirely still has
    // its mark, so the pause is never lost to the throttle.)
    if (last === 0) return;

    entry.presence.delete(from);
    this._logger.info({ from, phone: entry.phone }, "Customer stopped typing");
    this._report(entry, from, "paused");
  }

  /// One presence report, out and forgotten. Failing is a debug line on purpose:
  /// the pipeline is written to work without any of these arriving, just less
  /// well, and a company whose relay cannot reach the backend has louder things
  /// to read than this.
  _report(entry, from, state) {
    this._client
      .presence({ phone: entry.phone, from, state })
      .catch((error) => {
        this._logger.debug({ err: error.message, from, state }, "Could not report presence");
      });
  }

  // #region Linking

  /// Announces a number and drains whatever it was owed while nothing held it.
  ///
  /// Re-announcing an already-announced number is not skipped: this runs on
  /// every reconnection precisely because that is the only moment the backend
  /// can hand back a backlog, and because the room an answer is emitted to is
  /// the announcing session's — which changed if the app signed in again.
  async _announce(sessionId, phone) {
    const entry = this._entry(sessionId);

    if (entry.phone && entry.phone !== phone) {
      // The same local session, now holding a different number: the auth
      // folder was wiped and a different phone scanned the new QR. The old
      // number is no longer held by anything here.
      this._byPhone.delete(entry.phone);
      await this._unlink(entry.phone);
    }

    entry.phone = phone;
    this._byPhone.set(phone, sessionId);

    if (!credentials.isSet) {
      this._warnUnconfigured();
      return;
    }

    if (entry.announcing) return;

    entry.announcing = true;
    clearTimeout(entry.announceTimer);

    try {
      const answer = await this._client.announce({
        phone,
        language: credentials.value?.language ?? undefined
      });

      entry.announced = true;
      entry.backoff.reset();

      this._logger.info(
        { phone, created: answer?.created === true, pending: answer?.pending ?? 0 },
        "Number announced to the backend"
      );

      this._startPolling(entry);

      // The backend re-emits the backlog over the socket as part of
      // announcing, which only reaches a socket that is up. Reading the queue
      // back covers the case where it is not — and costs nothing when it is,
      // since a ticket already handled is skipped below.
      await this._drainOutbox(entry);

      // Anything that piled up while this number had no identity yet.
      this._scheduleFlush(entry);
    } catch (error) {
      entry.announced = false;

      if (error instanceof BackendError && !error.retryable) {
        // A number another company registered, a session the backend no longer
        // accepts: none of that is fixed by asking again. WhatsApp stays
        // connected — the phone is still linked, it just is not on the air —
        // and the next reconnection, or the next credentials the app pushes,
        // tries again.
        this._logger.error(
          { err: error.message, phone, status: error.status },
          "Backend refused this number — it is connected but not relaying"
        );
        return;
      }

      const delay = entry.backoff.next();
      this._logger.warn({ err: error.message, phone, delayMs: delay }, "Could not announce, retrying");

      entry.announceTimer = setTimeout(() => {
        if (!this._stopped) this._announce(sessionId, phone);
      }, delay);
    } finally {
      entry.announcing = false;
    }
  }

  /// The phone let go of the number, on purpose (`stop`) or because WhatsApp
  /// unlinked the device (`logged_out`).
  async _release(sessionId) {
    const entry = this._entries.get(sessionId);

    if (!entry?.phone) return;

    const phone = entry.phone;

    clearInterval(entry.pollTimer);
    clearTimeout(entry.announceTimer);
    entry.pollTimer = null;
    entry.announceTimer = null;
    entry.announced = false;

    this._byPhone.delete(phone);

    // Forgotten here too, so nothing re-announces a number this phone is no
    // longer holding — a `start()` later reports it again with its `connected`
    // status, which is the only thing that should put it back on the air.
    entry.phone = null;

    await this._unlink(phone);
  }

  async _unlink(phone) {
    if (!credentials.isSet) return;

    try {
      await this._client.unlink(phone);
      this._logger.info({ phone }, "Number released");
    } catch (error) {
      // Not worth retrying: the backend's own contract says a phone that dies
      // without saying anything is handled the same way — it stops acking, and
      // announcing itself again is what puts it back on the air.
      this._logger.warn({ err: error.message, phone }, "Could not release the number");
    }
  }

  // #region The inbound queue

  _scheduleFlush(entry) {
    if (entry.flushTimer || entry.flushing || !entry.inbox.length) return;
    if (!entry.phone || !credentials.isSet) return;

    entry.flushTimer = setTimeout(() => {
      entry.flushTimer = null;
      this._flush(entry);
    }, entry.flushDelay);
  }

  async _flush(entry) {
    if (entry.flushing || !entry.inbox.length || this._stopped) return;
    if (!entry.phone || !credentials.isSet) return;

    entry.flushing = true;

    const batch = this._takeBatch(entry.inbox);

    try {
      const answer = await this._client.messages(entry.phone, batch);

      entry.inbox.splice(0, batch.length);
      entry.backoff.reset();
      entry.flushDelay = 0;

      this._logger.info(
        { phone: entry.phone, accepted: answer?.accepted ?? batch.length, rejected: answer?.rejected ?? 0 },
        "Messages delivered to the backend"
      );
    } catch (error) {
      if (error instanceof BackendError && !error.retryable) {
        // The backend read the request and said no. Retrying sends the same
        // bytes to the same answer, so this batch is dropped — loudly, because
        // a customer wrote something nobody will ever answer.
        this._logger.error(
          { err: error.message, phone: entry.phone, count: batch.length, status: error.status },
          "Backend rejected these messages — they are lost"
        );
        entry.inbox.splice(0, batch.length);
      } else {
        entry.flushDelay = entry.backoff.next();
        this._logger.warn(
          { err: error.message, phone: entry.phone, queued: entry.inbox.length, delayMs: entry.flushDelay },
          "Could not deliver messages, retrying"
        );
      }
    } finally {
      entry.flushing = false;
      this._scheduleFlush(entry);
    }
  }

  /// As many queued messages as fit in one request. Size, not just count: one
  /// message carrying a photo is most of a body on its own, and a batch that
  /// crosses the backend's parser limit is rejected before any handler sees
  /// it — a 400 that says nothing about which message was the problem.
  _takeBatch(inbox) {
    const batch = [];
    let bytes = 0;

    for (const message of inbox) {
      const size = message.MEDIA ? message.MEDIA.length + 512 : JSON.stringify(message).length;

      if (batch.length > 0 && (bytes + size > MAX_BATCH_BYTES || batch.length >= MAX_BATCH)) {
        break;
      }

      batch.push(message);
      bytes += size;
    }

    return batch;
  }

  // #region backend -> WhatsApp

  /// One bubble of an answer. Serialized per number: the backend cuts a reply
  /// into parts and states plainly that they have to arrive in the order they
  /// were written, which a handler that awaits `sendMessage` concurrently
  /// cannot promise.
  _onSend(payload) {
    const phone = `${payload?.channel ?? ""}`;
    const sessionId = this._byPhone.get(phone);
    const entry = sessionId ? this._entries.get(sessionId) : null;

    if (!entry) {
      this._logger.warn({ phone, ticket: payload?.ticket }, "Answer for a number this server does not hold");
      return;
    }

    const ticket = `${payload?.ticket ?? ""}`;

    if (!ticket) return;

    // The same ticket reaches this server twice by design — the socket emits
    // it and the outbox still lists it until it is acked. Sending it twice is
    // a customer reading the same sentence twice, so the ticket, not the
    // transport, decides.
    if (entry.tickets.has(ticket)) return;
    entry.tickets.add(ticket);

    if (entry.tickets.size > TICKET_MEMORY) {
      entry.tickets.delete(entry.tickets.values().next().value);
    }

    entry.chain = entry.chain.then(() => this._deliver(entry, payload)).catch((error) => {
      this._logger.error({ err: error, ticket }, "Send chain broke");
    });
  }

  async _deliver(entry, payload) {
    const ticket = `${payload.ticket}`;
    const to = `${payload.to ?? ""}`;
    const text = `${payload.text ?? ""}`;

    /** @type {{ TICKET: String, TO: String, MESSAGE_ID?: String, ERROR?: String }} */
    const ack = { TICKET: ticket, TO: to };

    try {
      const messageId = await this._sessions.sendMessage(entry.sessionId, this._address(entry, to), await this._content(payload, text));

      ack.MESSAGE_ID = messageId ?? undefined;

      this._logger.info(
        { phone: entry.phone, to, part: payload.part, parts: payload.parts, replayed: payload.replayed === true },
        "Answer sent"
      );
    } catch (error) {
      ack.ERROR = error.message;

      // Forgotten locally so a later replay of the same ticket is attempted
      // again — the ack below takes it out of the backend's queue either way,
      // but a session that was merely between sockets deserves the retry the
      // next reconnection brings.
      entry.tickets.delete(ticket);

      this._logger.error({ err: error.message, phone: entry.phone, ticket }, "Could not send the answer");
    }

    try {
      await this._client.ack(entry.phone, [ack]);
    } catch (error) {
      // The message is on its way to the customer and the backend does not
      // know what WhatsApp called it. The conversation reads correctly; only
      // this message's ticks are unknowable from here on, which is exactly
      // what the backend's own note about an un-acked answer describes.
      this._logger.warn({ err: error.message, ticket }, "Could not acknowledge the answer");
    }
  }

  /// What Baileys is handed for one action. `kind` is "text", "location"
  /// (the company's pin, sent after an answer about where it is) or "image" (a
  /// product photo the customer asked to see); a payload with no `kind`
  /// predates the field and is text.
  async _content(payload, text) {
    const location = payload?.location;

    if (payload?.kind === "image" && payload?.image?.path) {
      return { image: await this._download(payload.image.path), mimetype: "image/jpeg", ...(payload.image.caption ? { caption: payload.image.caption } : {}) };
    }

    if (payload?.kind === "location" && Number.isFinite(location?.latitude) && Number.isFinite(location?.longitude)) {
      return {
        location: {
          degreesLatitude: location.latitude,
          degreesLongitude: location.longitude,
          ...(location.name ? { name: location.name } : {}),
          ...(location.address ? { address: location.address } : {})
        }
      };
    }

    return { text };
  }

  /// The photo's bytes, from the backend this phone already talks to: the path
  /// (`/rigel/media/<id>.jpg`) is relative on purpose, because this side knows
  /// the backend's address and the backend may not know its own public one.
  /// Public and unauthenticated, like every `/rigel` file. A failure throws,
  /// which acks the ticket with the error like any other send that failed.
  async _download(path) {
    const base = credentials.value?.url;

    if (!base) throw new Error("No backend URL to download the photo from");

    const response = await fetch(`${base}${path}`, { signal: AbortSignal.timeout(DOWNLOAD_TIMEOUT_MS) });

    if (!response.ok) throw new Error(`Photo download answered ${response.status}`);

    return Buffer.from(await response.arrayBuffer());
  }

  /// Blue ticks, "escribiendo…", the account showing as online. Emitted and
  /// forgotten by the backend, and treated the same way here: a signal that
  /// fails is a claim about this instant that is no longer worth making.
  async _onSignal(payload) {
    const phone = `${payload?.channel ?? ""}`;
    const sessionId = this._byPhone.get(phone);

    if (!sessionId) return;

    const entry = this._entries.get(sessionId);
    const to = payload?.to ? this._address(entry, payload.to) : null;
    const on = payload?.on !== false;

    try {
      switch (payload?.state) {
        case "read": {
          // The whole burst, oldest first — `messages` is what the backend
          // sends and `message` (its newest) is the compatibility field it
          // kept for builds that predate the list. Marking that one alone is
          // what left a burst of four with three grey ticks and one blue:
          // a receipt here names keys, it is not a watermark over the chat.
          const ids = Array.isArray(payload.messages) && payload.messages.length
            ? payload.messages
            : (payload.message ? [payload.message] : []);

          if (to && ids.length) {
            await this._sessions.readMessages(sessionId, to, ids);
          }

          break;
        }

        case "typing":
          if (to) await this._sessions.sendPresence(sessionId, on ? "composing" : "paused", to);
          break;

        case "online":
          await this._sessions.sendPresence(sessionId, on ? "available" : "unavailable", to);
          break;

        default:
          this._logger.debug({ state: payload?.state }, "Unknown signal");
      }
    } catch (error) {
      this._logger.debug({ err: error.message, state: payload?.state }, "Could not show the signal");
    }
  }

  /// Reads the queue back over HTTP and plays it through the same path a
  /// socket emit takes, ticket dedupe included.
  async _drainOutbox(entry) {
    if (!entry.phone || !credentials.isSet) return;

    let actions;

    try {
      actions = await this._client.outbox(entry.phone);
    } catch (error) {
      this._logger.warn({ err: error.message, phone: entry.phone }, "Could not read the outbox");
      return;
    }

    if (!actions.length) return;

    this._logger.info({ phone: entry.phone, count: actions.length }, "Draining the outbox");

    for (const action of actions) {
      this._onSend({ ...action, channel: entry.phone, replayed: true });
    }
  }

  /// The safety net, and only that: it runs while the socket is down and stops
  /// the moment it is back, so a healthy link never pays for it.
  _startPolling(entry) {
    if (entry.pollTimer) return;

    entry.pollTimer = setInterval(() => {
      if (this._stopped || this._socket.isConnected || !entry.announced) return;
      this._drainOutbox(entry);
    }, OUTBOX_POLL_MS);
  }

  // #region Reacting to the link itself

  /// The socket came back. Anything queued while it was gone was queued on the
  /// backend's side, so this is the moment to collect it.
  _onSocketUp() {
    for (const entry of this._entries.values()) {
      if (entry.announced) this._drainOutbox(entry);
    }
  }

  _onCredentialsChanged() {
    if (this._stopped) return;

    this._socket.connect();

    if (!credentials.isSet) return;

    // Every held number is announced again under the new session: the backend
    // remembers *which device* holds a number, and answers go to that device's
    // room. Left alone, they would be emitted at the room of a session that no
    // longer exists.
    for (const entry of this._entries.values()) {
      if (!entry.phone) continue;

      entry.announced = false;
      this._announce(entry.sessionId, entry.phone);
    }
  }

  // #region Plumbing

  _entry(sessionId) {
    let entry = this._entries.get(sessionId);

    if (entry) return entry;

    entry = {
      sessionId,
      phone: null,
      announced: false,
      announcing: false,
      announceTimer: null,
      /// Inbound messages waiting for the backend to take them.
      inbox: [],
      flushing: false,
      flushTimer: null,
      flushDelay: 0,
      /// Serializes answers going out, so the parts of one reply keep their
      /// order.
      chain: Promise.resolve(),
      tickets: new Set(),
      /// Identity the backend uses -> JID WhatsApp addresses them by.
      addresses: new Map(),
      /// The same pair read the other way, because a typing signal arrives
      /// addressed the way WhatsApp addresses the chat and has to be reported
      /// under the identity the conversation is keyed by.
      identities: new Map(),
      /// Contact -> when it was last reported typing, which is both the throttle
      /// and the memory that lets "stopped typing" be told from "came online".
      presence: new Map(),
      pollTimer: null,
      backoff: new Backoff({ baseMs: 2000, maxMs: 60000 })
    };

    this._entries.set(sessionId, entry);

    return entry;
  }

  /// Files how WhatsApp addresses this contact, under the identity the backend
  /// will use for them. The two are the same string on a chat addressed by
  /// number and are not on one addressed by LID, which is the whole reason this
  /// exists.
  ///
  /// Bounded, because it is a map that only ever grows otherwise: a number that
  /// has not written in a long time is one whose answer is not in flight either,
  /// and the next message it sends files it again before any reply is composed.
  _remember(entry, message) {
    const chat = `${message.chat ?? ""}`;

    if (!message.from || !chat) return;

    // Re-inserted rather than left alone, so the map iterates oldest-first and
    // the eviction below drops the contact nobody has heard from in longest.
    entry.addresses.delete(message.from);
    entry.addresses.set(message.from, chat);
    entry.identities.set(chat, message.from);

    if (entry.addresses.size > ADDRESS_MEMORY) {
      const oldest = entry.addresses.keys().next().value;

      entry.identities.delete(entry.addresses.get(oldest));
      entry.addresses.delete(oldest);
    }
  }

  /// The JID to write to, for an identity the backend handed back. Falls back to
  /// the identity itself, which is right for every chat addressed by number and
  /// is all there is for one this server has not seen a message from — a reply
  /// to a conversation it never relayed, which cannot happen through the
  /// pipeline and should still be attempted rather than dropped.
  _address(entry, to) {
    return entry?.addresses.get(`${to}`) ?? `${to}`;
  }

  /// Whether this is a message from a customer, which is the only kind the
  /// pipeline has any answer for.
  _isCustomerMessage(message) {
    // The last silent drop on the inbound path. A mapped message with no id or
    // no number behind it cannot be relayed — the backend keys deduplication on
    // the one and the conversation on the other — but it is still a customer's
    // message going nowhere, and saying so is the difference between a bug with
    // a line to grep for and a conversation that simply stops.
    if (!message?.id || !message.from) {
      this._logger.error(
        { messageId: message?.id ?? null, chat: message?.chat ?? null, type: message?.type ?? null },
        "Message has no id or no number behind it — cannot be relayed, not answered"
      );

      return false;
    }

    // WhatsApp echoes back everything this account sends, including what this
    // very server just sent. Forwarding those would have the assistant read
    // its own replies as customer messages and answer them.
    if (message.fromMe) return false;

    const chat = `${message.chat ?? ""}`;

    if (chat && !PERSON_SUFFIXES.some((suffix) => chat.endsWith(suffix))) {
      // A group, a status broadcast, a newsletter. Not refused for being
      // uninteresting: `Personal.number` would reduce a group's id to digits
      // and the backend would open a conversation keyed by something that is
      // not a phone number.
      this._logger.debug({ chat, messageId: message.id }, "Not a one-to-one chat — not relayed");
      return false;
    }

    return true;
  }

  /// The mapper's shape, in the backend's vocabulary. Two things are not a
  /// rename: media is dropped above the size the backend can parse (with the
  /// message still sent, because a customer who asked about a picture is
  /// better answered about a picture nobody could see than not at all), and
  /// the timestamp stays in seconds, which is the unit the whole pipeline
  /// dates conversations by.
  _toDelivery(message) {
    const media = message.media;
    const base64 = media?.base64 ?? null;

    // Base64 carries three bytes in every four characters, so the decoded size
    // is what the backend's own limit is written against — and what it will
    // measure once it decodes this.
    const bytes = base64 ? Math.floor((base64.length * 3) / 4) : 0;
    const fits = base64 !== null && bytes <= config.backendMediaMaxBytes;

    if (base64 && !fits) {
      this._logger.info(
        { messageId: message.id, bytes },
        "Attachment too large for the backend — forwarding the message without it"
      );
    }

    return {
      ID: message.id,
      FROM: message.from,
      NAME: message.pushName ?? undefined,
      TYPE: message.type,
      TEXT: message.text ?? undefined,
      TIMESTAMP: message.timestamp,
      MEDIA: fits ? base64 : undefined,
      MIME: fits && media?.mimetype ? media.mimetype : undefined,
      // The flat shape the backend's `messages/post.js` reads first. Without
      // these a pin arrives as text and no delivery area can be asked about it.
      LATITUDE: message.location?.latitude ?? undefined,
      LONGITUDE: message.location?.longitude ?? undefined,
      LABEL: message.location?.name ?? undefined,
      ADDRESS: message.location?.address ?? undefined,
      // The message this one replies to (WhatsApp's "reply"): its id, which
      // the backend resolves against what it stored, and its text as a
      // fallback for a message it never stored.
      QUOTED_ID: message.quoted?.id ?? undefined,
      QUOTED_TEXT: message.quoted?.text ?? undefined
    };
  }

  _warnUnconfigured() {
    if (this._warned) return;
    this._warned = true;

    this._logger.warn(
      "A number is connected but no backend session was pushed yet: nothing " +
        "is being relayed (the app sets this with PUT /backend)"
    );
  }
}

module.exports = BackendLink;
