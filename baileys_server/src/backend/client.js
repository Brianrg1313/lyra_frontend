const credentials = require("./credentials");

/// Base every route of this integration hangs off. The backend mounts routes
/// by directory (`lib/routes/cygnus/v1/whatsapp_personal/...`), so this is the
/// path, not a name that could be configured away.
const BASE = "/cygnus/v1/whatsapp_personal";

/// How long one call may take. Generous rather than tight: the `messages`
/// endpoint answers before it does the work (it acknowledges and then runs the
/// pipeline), so a slow answer here means a slow network, and giving up early
/// on a message that did arrive only produces a duplicate on the retry.
const TIMEOUT_MS = 20000;

/// A call the backend refused, or one that never got there. `status` is null
/// for a transport failure, which is the difference that decides whether
/// retrying is worth anything at all.
class BackendError extends Error {
  constructor(message, { status = null, body = null } = {}) {
    super(message);
    this.name = "BackendError";
    this.status = status;
    this.body = body;
  }

  /// Whether trying the same call again could plausibly succeed. A 4xx is the
  /// backend saying the request itself is wrong — an unknown number, a
  /// malformed body, an expired session — and none of that changes by asking
  /// twice. 429 is the exception: it is a "not now", not a "no".
  get retryable() {
    if (this.status === null) return true;
    if (this.status === 429) return true;
    return this.status >= 500;
  }

  /// The session is gone or the company is no longer accessible. The caller
  /// stops relaying rather than retrying: only the app can fix this, by
  /// pushing fresh credentials.
  get isAuth() {
    return this.status === 401 || this.status === 403;
  }
}

/// The company's own phone talking to its backend, over plain HTTP.
///
/// Six endpoints, and the shape of all of them comes from one fact: **this
/// server is the only thing that can see WhatsApp**. The backend never calls
/// out to WhatsApp and never calls in here — it receives what this phone
/// received, and hands back what it should say. So everything below is
/// outbound, and the answers come back on the socket (`./socket.js`) or, when
/// that has failed, out of `outbox`.
///
/// Every call identifies itself with the desktop app's own session
/// (`./credentials.js`), which is why there is no token of this service's own
/// anywhere in this file.
class BackendClient {
  constructor(logger) {
    this._logger = logger.child({ component: "backend-client" });
  }

  /// **Puts a number on the air.** Called every time a session reaches
  /// `connected`, not only the first time: the backend treats a reconnection
  /// as the moment to re-emit whatever the number is owed, and answers with
  /// how much that was (`pending`).
  async announce({ phone, name, language }) {
    return this._request("POST", "/session", {
      PHONE: phone,
      NAME: name || undefined,
      LANGUAGE: language || undefined
    });
  }

  /// Takes it off the air: this phone has stopped holding the number. The
  /// channel survives — the company still owns the number, it just is not
  /// connected — so this is not a delete.
  async unlink(phone) {
    return this._request("DELETE", `/session/${encodeURIComponent(phone)}`);
  }

  /// What the phone just received. One message or a batch: a phone coming back
  /// from being offline has several, and sending them one at a time would only
  /// re-order them.
  async messages(phone, messages) {
    return this._request("POST", "/messages", { PHONE: phone, MESSAGES: messages });
  }

  /// What happened to messages this phone sent — the ticks. Keyed by
  /// WhatsApp's own id, which only exists after `ack` renamed the stored copy.
  async statuses(phone, updates) {
    return this._request("POST", "/status", { PHONE: phone, STATUSES: updates });
  }

  /// The customer is typing. The one signal a companion device can report and
  /// the Cloud API cannot; the backend uses it to hold a burst open instead of
  /// guessing from the prose whether somebody has finished.
  async presence({ phone, from, state }) {
    return this._request("POST", "/presence", { PHONE: phone, FROM: from, STATE: state });
  }

  /// What the number still owes its phone. Reading is not destructive — only
  /// `ack` takes anything out — so a service that reads this and then dies has
  /// lost nothing.
  ///
  /// Comes back compressed (`core`'s `Response`: shared `keys`, one array of
  /// `values` per row) and is expanded here, because nothing downstream should
  /// have to know how this backend saves bytes on a list.
  async outbox(phone) {
    const data = await this._request("POST", "/outbox", { PHONE: phone });

    const keys = Array.isArray(data?.keys) ? data.keys : [];
    const rows = Array.isArray(data?.values) ? data.values : [];

    return rows.map((row) => {
      const action = {};
      keys.forEach((key, index) => {
        action[key] = row[index];
      });
      return action;
    });
  }

  /// **The phone sent it, and this is what WhatsApp called it** — or could
  /// not, and this is why. Both outcomes take the action out of the queue: a
  /// message WhatsApp refused twice is not one a third attempt fixes, and a
  /// failure left queued is replayed on every reconnection forever.
  ///
  /// `TO` travels even on success because a failure with no recipient attached
  /// is a log line, and the backend uses it to name the conversation somebody
  /// now has to pick up.
  async ack(phone, acks) {
    return this._request("POST", "/outbox/ack", { PHONE: phone, ACKS: acks });
  }

  /// One call, with the app's session on it. Everything above is this.
  async _request(method, path, body) {
    const session = credentials.value;

    if (!session) {
      throw new BackendError("No backend credentials configured");
    }

    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);

    let response;

    try {
      response = await fetch(`${session.url}${BASE}${path}`, {
        method,
        signal: controller.signal,
        headers: {
          "Content-Type": "application/json",
          // The three headers that *are* the identification. `device` is
          // checked globally (`validate_device`), the bearer resolves the user
          // (`validate_session`) and `business_id` says which of that user's
          // companies this is about (`validate_business`).
          "device": session.device,
          "business_id": session.business,
          "Authorization": `Bearer ${session.token}`,
          "Accept-Language": session.language ?? "es"
        },
        body: body === undefined ? undefined : JSON.stringify(body)
      });
    } catch (error) {
      throw new BackendError(
        error.name === "AbortError" ? `${method} ${path} timed out` : error.message,
        { status: null }
      );
    } finally {
      clearTimeout(timer);
    }

    const text = await response.text().catch(() => "");

    let payload = null;
    try {
      payload = text ? JSON.parse(text) : null;
    } catch {
      // A non-JSON body from a backend that always answers JSON means
      // something in front of it answered instead (a proxy, a 502 page). The
      // status still says what to do about it, so this is not fatal here.
      payload = null;
    }

    if (!response.ok) {
      throw new BackendError(
        `${method} ${path} -> ${response.status} ${payload?.message ?? text.slice(0, 200)}`,
        { status: response.status, body: payload }
      );
    }

    return payload;
  }
}

module.exports = { BackendClient, BackendError };
