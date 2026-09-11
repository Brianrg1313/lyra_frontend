const { Router } = require("express");

/// Process-level controls that are not about any one session.
module.exports = function controlRoutes({ onShutdown }) {
  const router = Router();

  /// Graceful shutdown reachable over HTTP: since the server is a detached
  /// process the app does not hold a handle to, asking it to stop has to go
  /// through the control API rather than an OS-level kill.
  ///
  /// Answers first and stops afterwards: closing the WhatsApp sockets and the
  /// backend link takes long enough that a caller waiting on the response
  /// would read the shutdown as a failed request.
  router.post("/control/shutdown", (req, res) => {
    res.json({ ok: true });
    setImmediate(onShutdown);
  });

  return router;
};
