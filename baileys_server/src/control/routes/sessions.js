const { Router } = require("express");

/// Everything the desktop app needs to manage sessions: list them, create
/// or restart one, get one's live status (state, QR, phone, last error),
/// pause it, log it out, delete it, and — mostly for manual testing from
/// the app — send a message straight through the control API instead of
/// going through the backend link.
module.exports = function sessionRoutes(sessionManager) {
  const router = Router();

  router.get("/sessions", (req, res) => {
    res.json({ sessions: sessionManager.list() });
  });

  router.post("/sessions", async (req, res) => {
    const id = req.body?.id?.toString().trim();
    if (!id) return res.status(400).json({ error: "missing_id" });

    try {
      const status = await sessionManager.ensureStarted(id);
      res.status(201).json(status);
    } catch (error) {
      res.status(500).json({ error: "start_failed", message: error.message });
    }
  });

  router.get("/sessions/:id", (req, res) => {
    const status = sessionManager.status(req.params.id);
    if (!status) return res.status(404).json({ error: "not_found" });

    res.json(status);
  });

  router.post("/sessions/:id/start", async (req, res) => {
    try {
      const status = await sessionManager.ensureStarted(req.params.id);
      res.json(status);
    } catch (error) {
      res.status(500).json({ error: "start_failed", message: error.message });
    }
  });

  router.post("/sessions/:id/stop", async (req, res) => {
    const status = await sessionManager.stop(req.params.id);
    if (!status) return res.status(404).json({ error: "not_found" });

    res.json(status);
  });

  router.post("/sessions/:id/logout", async (req, res) => {
    const status = await sessionManager.logout(req.params.id);
    if (!status) return res.status(404).json({ error: "not_found" });

    res.json(status);
  });

  router.delete("/sessions/:id", async (req, res) => {
    await sessionManager.remove(req.params.id);
    res.status(204).end();
  });

  router.post("/sessions/:id/send", async (req, res) => {
    const { to, message } = req.body ?? {};
    if (!to || !message) {
      return res.status(400).json({ error: "missing_to_or_message" });
    }

    try {
      const messageId = await sessionManager.sendMessage(req.params.id, to, message);
      res.json({ ok: true, messageId });
    } catch (error) {
      res.status(422).json({ error: "send_failed", message: error.message });
    }
  });

  return router;
};
