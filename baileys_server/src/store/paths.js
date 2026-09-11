const path = require("path");
const config = require("../config");

/// Filesystem layout for one session's persisted state: only the Baileys
/// multi-file auth folder lives here. Nothing else about a session survives
/// a restart on disk — status is runtime-only and rebuilt on reconnect.
function authDir(sessionId) {
  return path.join(config.sessionsDir, sessionId, "auth");
}

module.exports = { authDir };
