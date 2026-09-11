/// Every state a session can report to the outside world (control API and
/// backend link alike). Kept as plain strings, not a class: both consumers
/// are outside this process (Dart, and the backend), so the wire shape is
/// what matters, not the JS representation.
const SessionState = Object.freeze({
  // Socket is being created / auth is being restored. Transient.
  STARTING: "starting",
  // A fresh QR is ready and waiting to be scanned.
  QR_PENDING: "qr_pending",
  // Linked and connected to WhatsApp.
  CONNECTED: "connected",
  // Was connected, dropped, and is retrying on its own.
  RECONNECTING: "reconnecting",
  // Stopped on purpose (control API `stop`); no retry until `start`.
  STOPPED: "stopped",
  // The linked device was removed on the phone, or `logout` was called.
  // Auth is gone; only a fresh QR can bring it back.
  LOGGED_OUT: "logged_out",
  // Gave up retrying, or hit an error `stop`/`logout` do not explain.
  ERROR: "error"
});

/// Builds the status object every route and event returns. One shape, one
/// place: the control API, the backend `session.status` event and the
/// in-memory cache all read this instead of poking a session's internals.
function buildStatus(sessionId, {
  state,
  phone = null,
  qr = null,
  qrImage = null,
  lastError = null
}) {
  return {
    id: sessionId,
    state,
    phone,
    qr,
    qrImage,
    lastError,
    updatedAt: new Date().toISOString()
  };
}

module.exports = { SessionState, buildStatus };
