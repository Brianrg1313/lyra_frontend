const http = require("http");

const config = require("./config");
const logger = require("./logger");
const pidFile = require("./util/pid-file");
const SessionManager = require("./whatsapp/session-manager");
const BackendLink = require("./backend/link");
const buildControlApp = require("./control/app");
const EventHub = require("./control/events");
const { SESSION_STATUS, MESSAGE_RECEIVED } = EventHub;

async function main() {
  pidFile.claimOrExit(logger);

  const sessionManager = new SessionManager(logger);
  const eventHub = new EventHub(logger);
  const backendLink = new BackendLink({ sessionManager, logger });

  // WhatsApp -> backend. Four things happen on a linked number and all four
  // have somewhere to go: a number coming on the air is announced, what it
  // receives is forwarded, what it sent is reported back with its ticks, and a
  // customer who is typing is a burst the backend holds open instead of
  // answering half a thought.
  //
  // The link decides what is worth queueing and what is not; nothing here
  // waits on it, because a message that arrives during a backend outage is the
  // exact case it was built to survive.
  sessionManager.on("status", (status) => {
    backendLink.onStatus(status);
    eventHub.broadcast(SESSION_STATUS, { session_id: status.id, status });
  });

  sessionManager.on("message", (sessionId, message) => {
    backendLink.onMessage(sessionId, message);
    eventHub.broadcast(MESSAGE_RECEIVED, { session_id: sessionId, message });
  });

  sessionManager.on("receipts", (sessionId, receipts) => {
    backendLink.onReceipts(sessionId, receipts);
  });

  sessionManager.on("presence", (sessionId, presence) => {
    backendLink.onPresence(sessionId, presence);
  });

  // backend -> WhatsApp travels the other way down the same link, over the
  // socket it opens; `BackendLink` owns both directions, so there is nothing
  // to wire here.
  backendLink.start();

  await sessionManager.restoreAll();

  let shuttingDown = false;
  const shutdown = async (reason) => {
    if (shuttingDown) return;
    shuttingDown = true;

    logger.info({ reason }, "Shutting down");
    await sessionManager.stopAll();
    backendLink.stop();
    eventHub.close();
    pidFile.release();
    process.exit(0);
  };

  const app = buildControlApp({
    sessionManager,
    backendLink,
    logger,
    onShutdown: () => shutdown("control_api")
  });

  const server = http.createServer(app);
  eventHub.attach(server);

  server.listen(config.port, config.host, () => {
    logger.info(
      { host: config.host, port: config.port },
      "Control API listening"
    );
  });

  process.on("SIGINT", () => shutdown("SIGINT"));
  process.on("SIGTERM", () => shutdown("SIGTERM"));

  process.on("uncaughtException", (error) => {
    logger.fatal({ err: error }, "Uncaught exception");
    shutdown("uncaught_exception");
  });

  process.on("unhandledRejection", (reason) => {
    logger.error({ err: reason }, "Unhandled rejection");
  });
}

main().catch((error) => {
  logger.fatal({ err: error }, "Fatal startup error");
  pidFile.release();
  process.exit(1);
});
