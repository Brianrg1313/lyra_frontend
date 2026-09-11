/// Exponential backoff with a cap, shared by both reconnect loops in the
/// process (a session's WhatsApp socket, and the backend WebSocket link) so
/// a flaky network does not turn into a hot retry loop hammering either
/// side.
class Backoff {
  constructor({ baseMs = 1000, maxMs = 30000 } = {}) {
    this._baseMs = baseMs;
    this._maxMs = maxMs;
    this._attempt = 0;
  }

  next() {
    const delay = Math.min(this._maxMs, this._baseMs * 2 ** this._attempt);
    this._attempt += 1;
    return delay;
  }

  reset() {
    this._attempt = 0;
  }
}

module.exports = Backoff;
