const { Router } = require("express");

const startedAt = Date.now();

/// Liveness only: reachable at all means the process is up. It deliberately
/// does not require the API key — the app needs to be able to tell "not
/// running" apart from "running but rejecting me", and a 401 here would
/// blur that distinction.
module.exports = function healthRoutes(backendLink) {
  const router = Router();

  router.get("/health", (req, res) => {
    res.json({
      ok: true,
      pid: process.pid,
      // Epoch ms, not just an uptime: the app compares it against the mtime
      // of this server's sources to notice it is running code older than
      // what is on disk. The process is detached and outlives the app, so
      // without that check an edit here silently never takes effect.
      startedAt,
      uptimeSeconds: Math.floor((Date.now() - startedAt) / 1000),
      // Two different failures the app has to be able to tell apart: nobody
      // gave this server a session to act as (`configured`), and it has one
      // but cannot hold the socket the answers come back on (`connected`).
      backendConfigured: backendLink.isConfigured,
      backendLinkConnected: backendLink.isConnected,
      linkedNumbers: backendLink.linked.length
    });
  });

  return router;
};
