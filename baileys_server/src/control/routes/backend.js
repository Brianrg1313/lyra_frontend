const { Router } = require("express");
const credentials = require("../../backend/credentials");

/// **How this server learns who it is.**
///
/// It holds a WhatsApp account and it knows the local API key, and neither of
/// those says anything to the backend: the credential there is the desktop
/// app's own user session, which only the app has. So the app pushes it here —
/// on start-up, and again whenever it changes (a new sign-in, a switch to
/// another company, a refreshed token).
///
/// The token is never read back. `GET` answers with everything else, which is
/// what a developer needs to tell "using the wrong session" apart from "not
/// configured" without the secret passing through a log on the way.
module.exports = function backendRoutes(link) {
  const router = Router();

  router.get("/backend", (req, res) => {
    res.json({
      ...credentials.summary,
      connected: link.isConnected,
      sessions: link.linked
    });
  });

  router.put("/backend", (req, res) => {
    const { url, token, device, business, language } = req.body ?? {};

    try {
      const changed = credentials.set({ url, token, device, business, language });
      res.json({ ...credentials.summary, changed });
    } catch (error) {
      res.status(400).json({ error: "invalid_credentials", message: error.message });
    }
  });

  /// Signing out. The WhatsApp sessions are deliberately left alone: the
  /// person did not unlink their phone, they closed an app — and a `logout`
  /// here would cost them a QR scan to undo.
  router.delete("/backend", (req, res) => {
    const cleared = credentials.clear();
    res.json({ ...credentials.summary, cleared });
  });

  return router;
};
