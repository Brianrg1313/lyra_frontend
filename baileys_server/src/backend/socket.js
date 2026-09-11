const { EventEmitter } = require("events");
const { io } = require("socket.io-client");
const credentials = require("./credentials");

/// Events the backend emits at the phone holding a number
/// (`model:/whatsapp/personal.js`). Named there, mirrored here — a second
/// spelling of either is a message nobody receives.
const SEND = "whatsapp_personal/send";
const SIGNAL = "whatsapp_personal/signal";

/// **The way back.** Everything this server sends the backend goes out over
/// HTTP; everything the backend sends this server arrives here.
///
/// It is a socket and not a webhook for the reason the whole sidecar exists:
/// the machine this runs on is a desktop behind NAT, so nothing can call in.
/// It is the *app's* socket protocol and not one of this service's own for a
/// subtler reason — the backend addresses an answer to `session:<uid>:<did>`,
/// the room of the user session that announced the number
/// (`Bridge.sessionRoom`). Joining that room is not something a client asks
/// for: it happens when the handshake authenticates, so connecting with the
/// same session the announcement was made with **is** the subscription.
///
/// The handshake carries no headers of its own on purpose. `SocketContext`
/// folds everything in `auth` into the request headers precisely so a browser
/// — which cannot set headers on a WebSocket — authenticates the same way a
/// request does, and this takes the same road: `token`, `device` and
/// `business_id` in `auth`, read by the same three middlewares that guard
/// every route.
class BackendSocket extends EventEmitter {
  constructor(logger) {
    super();
    this._logger = logger.child({ component: "backend-socket" });
    this._socket = null;
    this._authFailures = 0;
  }

  get isConnected() {
    return this._socket?.connected === true;
  }

  /// Opens the connection, replacing any existing one. Called at boot and
  /// again on every credential change — a socket is bound to one company for
  /// its whole life (rooms are joined once, at handshake time), so a new
  /// business or a new token is a new connection, never a mutated one.
  connect() {
    this.close();

    const session = credentials.value;

    if (!session) {
      this._logger.warn(
        "No backend credentials yet: WhatsApp is being held, but nothing is " +
          "relayed until the app pushes a session (PUT /backend)"
      );
      return;
    }

    this._authFailures = 0;

    this._socket = io(session.url, {
      // Polling would work, but it is a long-lived server-to-server link with
      // no browser or proxy in the way that would need the fallback.
      transports: ["websocket"],
      auth: {
        device: session.device,
        token: session.token,
        business_id: session.business
      },
      reconnection: true,
      reconnectionDelay: 1000,
      reconnectionDelayMax: 30000,
      timeout: 20000
    });

    this._socket.on("connect", () => {
      this._authFailures = 0;
      this._logger.info({ url: session.url }, "Backend socket connected");
      this.emit("connected");
    });

    this._socket.on("disconnect", (reason) => {
      this._logger.warn({ reason }, "Backend socket disconnected");
      this.emit("disconnected", reason);
    });

    this._socket.on("connect_error", (error) => {
      this._authFailures += 1;

      // socket.io retries a rejected handshake exactly as it retries an
      // unreachable host, so a stale token would otherwise fill the log with
      // one identical line per second, forever. The first few are the ones
      // that say what happened; after that it is the same fact.
      if (this._authFailures <= 3 || this._authFailures % 60 === 0) {
        this._logger.warn(
          { err: error.message, attempts: this._authFailures },
          "Backend socket could not connect"
        );
      }
    });

    this._socket.on(SEND, (payload) => this.emit("send", payload));
    this._socket.on(SIGNAL, (payload) => this.emit("signal", payload));
  }

  close() {
    if (!this._socket) return;

    this._socket.removeAllListeners();
    this._socket.disconnect();
    this._socket = null;
  }
}

module.exports = BackendSocket;
