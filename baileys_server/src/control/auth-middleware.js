const config = require("../config");

/// Guards every control-API route with the shared secret the desktop app
/// was configured with. The server binds to 127.0.0.1 by default, but that
/// alone does not stop another local process (or another user session on
/// the same machine) from calling it, so the key still matters even
/// off-network.
function requireApiKey(req, res, next) {
  const provided = req.get("x-api-key");

  if (provided !== config.controlApiKey) {
    return res.status(401).json({ error: "invalid_api_key" });
  }

  next();
}

module.exports = requireApiKey;
