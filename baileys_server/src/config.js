const path = require("path");
require("dotenv").config();

/// Every setting the server needs, read once at boot. Nothing else in the
/// codebase touches `process.env` directly, so a missing or malformed value
/// fails here instead of surfacing as a confusing error three modules away.
function required(name) {
  const value = process.env[name];
  if (!value || !value.trim()) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value.trim();
}

function int(name, fallback) {
  const raw = process.env[name];
  if (!raw) return fallback;
  const value = Number.parseInt(raw, 10);
  return Number.isFinite(value) ? value : fallback;
}

const dataDir = path.resolve(process.cwd(), process.env.DATA_DIR || "./data");

module.exports = {
  host: process.env.HOST || "127.0.0.1",
  port: int("PORT", 4001),
  controlApiKey: required("CONTROL_API_KEY"),

  // Where the Lyra backend lives (scheme, host and port, no path). Only a
  // fallback: the app pushes the address along with the session it wants this
  // server to act as (`PUT /backend`), because both come from the same place
  // and a server pointing at one backend with another's credentials is worse
  // than one pointing nowhere.
  backendUrl: (process.env.BACKEND_URL || "").trim().replace(/\/+$/, ""),

  // Largest attachment forwarded to the backend, in decoded bytes. Sized
  // against what it can actually read, not what it would like: it parses at
  // most 1 MB of JSON and base64 costs a third on top of the bytes it carries,
  // so a picture much past this is a request its parser rejects before any
  // handler sees it — a 400 that says nothing about which message it was.
  // Above this the message is still forwarded, without the bytes.
  backendMediaMaxBytes: int("BACKEND_MEDIA_MAX_BYTES", 640 * 1024),

  dataDir,
  sessionsDir: path.join(dataDir, "sessions"),
  registryFile: path.join(dataDir, "registry.json"),
  credentialsFile: path.join(dataDir, "backend.json"),
  pidFile: path.join(dataDir, "baileys_server.pid"),

  logLevel: process.env.LOG_LEVEL || "info",
  logFile: path.join(dataDir, "server.log"),

  mediaInlineMaxBytes: int("MEDIA_INLINE_MAX_BYTES", 1024 * 1024)
};
