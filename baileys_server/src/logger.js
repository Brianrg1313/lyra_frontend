const fs = require("fs");
const pino = require("pino");
const config = require("./config");

fs.mkdirSync(config.dataDir, { recursive: true });

/// Single logger for the whole process: console (pretty, human) plus a
/// rolling-free append file, since this runs headless and nobody is
/// watching a terminal once the app that launched it is closed.
const logger = pino(
  { level: config.logLevel },
  pino.multistream([
    { stream: process.stdout },
    { stream: fs.createWriteStream(config.logFile, { flags: "a" }) }
  ])
);

module.exports = logger;
