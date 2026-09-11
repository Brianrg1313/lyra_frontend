const { EventEmitter } = require("events");
const fs = require("fs");
const WhatsappSession = require("./session");
const { authDir } = require("../store/paths");
const { SessionState } = require("./status");
const registry = require("../store/registry");

/// States in which a session already has (or is opening) its own socket, so
/// starting it again would only open a second one for the same credentials.
const LIVE_STATES = new Set([
  SessionState.STARTING,
  SessionState.QR_PENDING,
  SessionState.CONNECTED,
  SessionState.RECONNECTING
]);

/// Owns every `WhatsappSession` the server is running, keyed by the id the
/// app assigns (the connection id in the main app's own data model — this
/// server has no opinion on what the id means, it just needs it to be
/// unique).
///
/// Re-emits each session's `status` and `message` events with the session
/// already identified, which is what both the control API and the backend
/// link consume: neither needs to know a `WhatsappSession` exists, only that
/// "session X changed status" / "session X got a message" happened.
class SessionManager extends EventEmitter {
  constructor(logger) {
    super();
    this._logger = logger;
    this._sessions = new Map();
  }

  list() {
    return [...this._sessions.values()].map((session) => session.status);
  }

  get(id) {
    return this._sessions.get(id) ?? null;
  }

  status(id) {
    return this._sessions.get(id)?.status ?? null;
  }

  /// Creates the session if it does not exist yet and starts it unless it is
  /// already running — idempotent on purpose, so the app can call this
  /// without first checking whether the connection was already set up.
  ///
  /// "Already running" has to be a real no-op, not a restart: the app calls
  /// this on every switch-on, and the server restores every registered
  /// session at boot, so the two routinely land on the same session seconds
  /// apart. Restarting a live one opens a second socket for the same
  /// credentials, which WhatsApp resolves by closing one of them with
  /// `conflict: replaced` — see `session.js`.
  async ensureStarted(id) {
    let session = this._sessions.get(id);

    if (!session) {
      session = new WhatsappSession(id, this._logger);
      session.on("status", (status) => this.emit("status", status));
      session.on("message", (message) => this.emit("message", id, message));
      session.on("receipts", (receipts) => this.emit("receipts", id, receipts));
      session.on("presence", (presence) => this.emit("presence", id, presence));
      this._sessions.set(id, session);
      registry.add(id);
    } else if (LIVE_STATES.has(session.status.state)) {
      return session.status;
    }

    await session.start();
    return session.status;
  }

  async stop(id) {
    const session = this._sessions.get(id);
    if (!session) return null;

    await session.stop();
    return session.status;
  }

  async logout(id) {
    const session = this._sessions.get(id);
    if (!session) return null;

    await session.logout();
    return session.status;
  }

  /// Removes the session entirely: stops it, wipes its auth folder, and
  /// forgets it existed. Unlike `logout`, the app is not expected to bring
  /// this connection back — that would mean creating it again from scratch.
  async remove(id) {
    const session = this._sessions.get(id);
    if (session) {
      await session.stop();
      this._sessions.delete(id);
    }

    fs.rmSync(authDir(id), { recursive: true, force: true });
    registry.remove(id);
  }

  async sendMessage(id, to, content) {
    return this._require(id).sendMessage(to, content);
  }

  async readMessages(id, to, messageIds) {
    return this._require(id).readMessages(to, messageIds);
  }

  async sendPresence(id, state, to) {
    return this._require(id).sendPresence(state, to);
  }

  _require(id) {
    const session = this._sessions.get(id);
    if (!session) throw new Error(`Unknown session "${id}"`);

    return session;
  }

  /// Restarts every session the registry remembers. Called once at boot so a
  /// server restart (crash, machine reboot) reconnects on its own using the
  /// auth already on disk, instead of leaving every number logged out until
  /// someone reopens the app.
  async restoreAll() {
    for (const id of registry.list()) {
      try {
        await this.ensureStarted(id);
      } catch (error) {
        this._logger.error({ err: error, sessionId: id }, "Failed to restore session");
      }
    }
  }

  async stopAll() {
    for (const session of this._sessions.values()) {
      await session.stop();
    }
  }
}

module.exports = SessionManager;
