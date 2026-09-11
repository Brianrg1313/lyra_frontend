const { EventEmitter } = require("events");
const fs = require("fs");
const path = require("path");
const config = require("../config");
const logger = require("../logger");

/// **Who this server says it is when it talks to the backend.**
///
/// The backend issues no token for this service and stores none
/// (`lib/routes/cygnus/v1/whatsapp_personal/session/post.js`): the credential
/// is the desktop app's *own user session*, handed over as-is. Every request
/// therefore carries the same three things a request from the app carries —
/// `Authorization: Bearer <session token>`, a `device` and a `business_id` —
/// and the backend answers the only two questions it has from them: who is
/// asking, and for which company.
///
/// This server cannot obtain any of that on its own, so the app pushes it in
/// over the control API (`PUT /backend`) and pushes it again whenever it
/// changes (a new sign-in, a different active business).
///
/// **Persisted to disk**, because the process is detached and outlives the app
/// that started it: a machine that reboots at 3am has to come back up talking
/// to the backend without anybody opening the app first. The file sits in
/// `DATA_DIR` next to the WhatsApp auth folders — which hold far more
/// sensitive material than a session token — and is written user-only.
class Credentials extends EventEmitter {
  constructor(file, logger) {
    super();
    this._file = file;
    this._logger = logger.child({ component: "credentials" });
    this._value = this._read();
  }

  /// Whether there is enough here to reach the backend at all. A session with
  /// no business is not usable: `validate_business` rejects the handshake and
  /// every route 400s, so it is treated as "not configured" rather than
  /// half-configured.
  get isSet() {
    const value = this._value;
    return Boolean(value?.url && value?.token && value?.device && value?.business);
  }

  get value() {
    return this._value ? { ...this._value } : null;
  }

  /// What the app is allowed to know about this without being told the token
  /// back — the control API answers with it so a developer can see *which*
  /// session the sidecar is using without it leaking into a log.
  get summary() {
    return {
      configured: this.isSet,
      url: this._value?.url ?? null,
      device: this._value?.device ?? null,
      business: this._value?.business ?? null,
      language: this._value?.language ?? null
    };
  }

  /// Replaces the credentials wholesale and reports whether anything the
  /// connections care about actually moved. Nothing here diffs field by field
  /// on purpose: a partial update — a token without the business it belongs
  /// to — is how a session ends up authenticating as one thing and
  /// authorizing as another.
  set({ url, token, device, business, language }) {
    const next = {
      // A trailing slash here becomes a double slash in every path built from
      // it, which Express does not match — one of those bugs that reads as
      // "the backend rejects everything" for an hour.
      //
      // `BACKEND_URL` stands in when the caller sends none, which is what
      // makes the env var usable for a developer driving this server by hand.
      url: (`${url ?? ""}`.trim() || config.backendUrl).replace(/\/+$/, ""),
      token: `${token ?? ""}`.trim().replace(/^Bearer\s+/i, ""),
      device: `${device ?? ""}`.trim(),
      business: `${business ?? ""}`.trim(),
      language: `${language ?? ""}`.trim() || null
    };

    if (!next.url || !next.token || !next.device || !next.business) {
      throw new Error("url, token, device and business are all required");
    }

    const changed = JSON.stringify(next) !== JSON.stringify(this._value);

    this._value = next;
    this._write();

    if (changed) {
      this._logger.info(
        { url: next.url, business: next.business },
        "Backend credentials updated"
      );
      this.emit("change", this.value);
    }

    return changed;
  }

  /// Signing out, or the app telling this server to stop acting on a session
  /// that is no longer valid. The sessions themselves are untouched: WhatsApp
  /// stays linked, and the relay resumes the moment credentials come back.
  clear() {
    if (!this._value) return false;

    this._value = null;

    try {
      fs.rmSync(this._file, { force: true });
    } catch (error) {
      this._logger.warn({ err: error }, "Could not delete the credentials file");
    }

    this._logger.info("Backend credentials cleared");
    this.emit("change", null);

    return true;
  }

  _read() {
    try {
      const parsed = JSON.parse(fs.readFileSync(this._file, "utf8"));

      if (!parsed?.url || !parsed?.token || !parsed?.device || !parsed?.business) {
        return null;
      }

      return {
        url: parsed.url,
        token: parsed.token,
        device: parsed.device,
        business: parsed.business,
        language: parsed.language ?? null
      };
    } catch {
      // No file yet, or one written by an older build. Starting unconfigured
      // is correct either way: the app pushes credentials on its next call,
      // and until then the relay is simply off.
      return null;
    }
  }

  _write() {
    try {
      fs.mkdirSync(path.dirname(this._file), { recursive: true });
      fs.writeFileSync(this._file, JSON.stringify(this._value, null, 2), { mode: 0o600 });
    } catch (error) {
      // Worth surviving: the credentials are already live in memory, so the
      // relay works for as long as this process does. Only a restart loses
      // them, and the app re-pushes on its next call anyway.
      this._logger.error({ err: error }, "Could not persist the credentials");
    }
  }
}

module.exports = new Credentials(config.credentialsFile, logger);
