const fs = require("fs");
const config = require("../config");

/// The list of session ids the server is responsible for, persisted to disk
/// so a machine restart (or a crash) reconnects every previously configured
/// WhatsApp number on its own, instead of leaving them all logged out until
/// someone reopens the app and recreates them one by one.
///
/// Deliberately tiny: just ids and when they were added. Everything else
/// about a session (auth, live status) is either Baileys' own auth folder or
/// runtime-only state in `SessionManager`.
class Registry {
  constructor(file) {
    this._file = file;
    this._ids = this._read();
  }

  list() {
    return [...this._ids];
  }

  add(sessionId) {
    if (this._ids.includes(sessionId)) return;
    this._ids.push(sessionId);
    this._write();
  }

  remove(sessionId) {
    const next = this._ids.filter((id) => id !== sessionId);
    if (next.length === this._ids.length) return;
    this._ids = next;
    this._write();
  }

  _read() {
    try {
      const raw = fs.readFileSync(this._file, "utf8");
      const parsed = JSON.parse(raw);
      return Array.isArray(parsed?.sessionIds) ? parsed.sessionIds : [];
    } catch {
      // No file yet (first boot) or corrupt: starting empty is the only
      // choice that does not risk crashing the whole server over a stray
      // registry write.
      return [];
    }
  }

  _write() {
    fs.mkdirSync(config.dataDir, { recursive: true });
    fs.writeFileSync(
      this._file,
      JSON.stringify({ sessionIds: this._ids }, null, 2)
    );
  }
}

module.exports = new Registry(config.registryFile);
