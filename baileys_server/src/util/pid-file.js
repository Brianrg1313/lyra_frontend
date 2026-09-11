const fs = require("fs");
const config = require("../config");

/// Guards against two copies of the server running at once, which would
/// otherwise both try to hold the same WhatsApp sessions and fight over the
/// same auth files. `signal 0` does not send anything: Node/the OS use it
/// purely to check whether a pid is still alive, which works on Windows too.
function isRunning(pid) {
  try {
    process.kill(pid, 0);
    return true;
  } catch {
    return false;
  }
}

function claimOrExit(logger) {
  fs.mkdirSync(config.dataDir, { recursive: true });

  if (fs.existsSync(config.pidFile)) {
    const existing = Number.parseInt(fs.readFileSync(config.pidFile, "utf8"), 10);
    if (Number.isFinite(existing) && isRunning(existing)) {
      logger.error(
        { pid: existing },
        "Another baileys_server instance is already running. Exiting."
      );
      process.exit(1);
    }
  }

  fs.writeFileSync(config.pidFile, String(process.pid));
}

function release() {
  try {
    fs.unlinkSync(config.pidFile);
  } catch {
    // Already gone: nothing to clean up.
  }
}

module.exports = { claimOrExit, release };
