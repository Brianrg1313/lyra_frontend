const express = require("express");
const requireApiKey = require("./auth-middleware");
const healthRoutes = require("./routes/health");
const sessionRoutes = require("./routes/sessions");
const backendRoutes = require("./routes/backend");
const controlRoutes = require("./routes/control");

/// The local HTTP API the desktop app talks to. Kept deliberately small:
/// sessions, the backend session this server acts as, and process control.
/// Nothing about WhatsApp content itself — that only ever flows through the
/// backend link.
function buildApp({ sessionManager, backendLink, logger, onShutdown }) {
  const app = express();
  app.use(express.json({ limit: "2mb" }));

  app.use(healthRoutes(backendLink));

  app.use(requireApiKey);
  app.use(sessionRoutes(sessionManager));
  app.use(backendRoutes(backendLink));
  app.use(controlRoutes({ onShutdown }));

  app.use((req, res) => res.status(404).json({ error: "not_found" }));

  // eslint-disable-next-line no-unused-vars
  app.use((error, req, res, next) => {
    logger.error({ err: error }, "Unhandled control API error");
    res.status(500).json({ error: "internal_error" });
  });

  return app;
}

module.exports = buildApp;
