const { WebSocketServer } = require("ws");
const config = require("../config");

/// Frame types this feed broadcasts. Read by the Dart client
/// (`lib/services/baileys/baileys_event.dart`), which is why they are named
/// here rather than written inline at each `broadcast` call.
const SESSION_STATUS = "session.status";
const MESSAGE_RECEIVED = "message.received";

/// The local event feed the desktop app subscribes to, at
/// `ws://<HOST>:<PORT>/events` on the same port as the control API.
///
/// The control API is request/response, so the only way for the app to learn
/// that a message arrived was to poll — which it cannot do at all, since
/// messages are not part of any status. This exists so the app sees WhatsApp
/// traffic as it happens: during development that means the messages print in
/// the Flutter console instead of being buried in `data/server.log`, which the
/// developer running `flutter run` never has in front of them.
///
/// It is a broadcast, not a queue: nothing is replayed to a client that
/// connects late, and nothing is buffered while none is connected. Delivery
/// that matters is the backend link's job (`src/backend`), which queues; this
/// one is only ever a mirror for whoever is watching right now.
class EventHub {
  constructor(logger) {
    this._logger = logger;
    this._wss = new WebSocketServer({ noServer: true });
  }

  /// Takes over `upgrade` on the given HTTP server for `/events`. The API key
  /// travels in the query string rather than a header because browsers cannot
  /// set headers on a WebSocket handshake — the Dart client could, but keeping
  /// one accepted form avoids two auth paths for the same door.
  attach(server) {
    server.on("upgrade", (request, socket, head) => {
      const url = new URL(request.url, "http://localhost");

      if (url.pathname !== "/events") {
        socket.destroy();
        return;
      }

      const key = url.searchParams.get("key") ?? request.headers["x-api-key"];
      if (key !== config.controlApiKey) {
        socket.write("HTTP/1.1 401 Unauthorized\r\n\r\n");
        socket.destroy();
        return;
      }

      this._wss.handleUpgrade(request, socket, head, (client) => {
        this._logger.info("Event feed client connected");
        client.on("close", () => this._logger.info("Event feed client disconnected"));
        client.send(JSON.stringify({ type: "hello", pid: process.pid }));
      });
    });
  }

  broadcast(type, payload) {
    if (this._wss.clients.size === 0) return;

    const frame = JSON.stringify({ type, ...payload });
    for (const client of this._wss.clients) {
      if (client.readyState === client.OPEN) client.send(frame);
    }
  }

  close() {
    for (const client of this._wss.clients) client.terminate();
    this._wss.close();
  }
}

module.exports = EventHub;
module.exports.SESSION_STATUS = SESSION_STATUS;
module.exports.MESSAGE_RECEIVED = MESSAGE_RECEIVED;
