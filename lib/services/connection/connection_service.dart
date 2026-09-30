import 'package:flutter/foundation.dart';
import 'package:core/socket.dart' show SocketStatus, SocketHandler;

import 'package:app/toolkit/sockets.dart';
import 'package:app/toolkit/deployment.dart';

// The status and the handler signature are part of this service's API:
// whoever consumes it shouldn't have to import the package just to name them.
export 'package:core/socket.dart' show SocketStatus, SocketHandler;

/// Overall status of the real-time connection.
///
/// It's the sole owner of the socket's lifecycle: no one else should call
/// `sockets.connect()` or `sockets.disconnect()` directly, because this
/// service is the one that knows whether an attempt is in progress and the
/// one that translates the result into something the app can show.
///
/// It's a singleton because there is only one connection and it's long-lived:
/// the session (`ClientService`) opens it and screens that come and go
/// consume it, so it can't depend on any widget's lifecycle. It's also
/// registered in `initialBuilder` with `ChangeNotifierProvider.value` so it
/// can be observed with `context.watch`, and for that same reason the
/// provider must not dispose it.
///
/// ```dart
/// // Status, to paint a connection indicator.
/// final online = context.watch<ConnectionService>().isConnected;
///
/// // Server events. `on` returns the listener's removal function.
/// final remove = ConnectionService().on("stock:update", (data) => ...);
/// ```
class ConnectionService extends ChangeNotifier {
  //SINGLETON
  static final ConnectionService _singleton = ConnectionService._internal();
  factory ConnectionService() => _singleton;

  ConnectionService._internal() {
    sockets.status.addListener(_onStatus);
  }

  /// Opening attempt in progress, so multiple calls to [open] hang off the
  /// same handshake instead of chaining retries.
  Future<void>? _opening;

  /// True from the moment it's closed on purpose until the next opening. It's
  /// there so the disconnect that [close] itself causes isn't reported as a
  /// failure.
  bool _closed = false;

  /// Whether there has already been a live connection in this run, and whether
  /// there is one now. The pair is what tells a **reconnection** from the first
  /// connection of the app: only the first can have missed anything.
  bool _everLive = false;
  bool _live = false;

  /// Who wants to know when the connection comes back — see [onRestored].
  final List<void Function()> _restored = [];

  Map<String, dynamic>? _error;

  // ─── Status ─────────────────────────────────────────────────────────────────

  SocketStatus get status => sockets.status.value;

  /// The raw status, in case it's more convenient to paint it with a
  /// `ValueListenableBuilder` instead of rebuilding with the provider.
  ValueListenable<SocketStatus> get listenable => sockets.status;

  bool get isConnected => status == SocketStatus.connected;

  /// An attempt is in progress (first try or a retry). It's not a failure: UI
  /// that warns about a drop should wait for [isDisconnected].
  bool get isConnecting =>
    status == SocketStatus.connecting || status == SocketStatus.reconnecting;

  /// The connection is unavailable and nothing is retrying it.
  bool get isDisconnected =>
    status == SocketStatus.disconnected || status == SocketStatus.idle;

  /// Last failure, already normalized to `{message, action}` so it can be
  /// passed to `FloatFlag.fromError`. Cleared on connect.
  Map<String, dynamic>? get error => _error;

  /// Id the server gave this connection. Changes on every reconnection.
  String? get id => sockets.id;

  // ─── Lifecycle ──────────────────────────────────────────────────────────────

  /// Opens the connection. This is what to call once the session is already
  /// valid.
  ///
  /// Doesn't throw: a connection failure shouldn't break the flow that opened
  /// it (app startup, entering the home screen), so the error is left in
  /// [error] and the client keeps retrying on its own. It's idempotent, it
  /// can be called every time an authenticated section is entered.
  ///
  /// Only in the cloud: on a master's devices there is no socket.io server to
  /// reach, and the master's events (`protocol-v1.md` §5) reach the services
  /// with the first domain that needs them live (plan §7.2).
  Future<void> open() async {
    if (Deployment.mode != DeploymentMode.cloud) return;
    if (isConnected) return;

    final pending = _opening;
    if (pending != null) return pending;

    final attempt = _open();
    _opening = attempt;

    try {
      await attempt;
    } finally {
      _opening = null;
    }
  }

  Future<void> _open() async {
    _closed = false;
    _fail(null);

    try {
      await sockets.connect();
    } catch (e) {
      // The disconnect was caused by a `close` that arrived while it was
      // opening: it's not a failure that needs to be shown.
      if (_closed) return;
      _fail(e is Map ? Map<String, dynamic>.from(e) : sockets.exception(e));
    }
  }

  /// Closes the connection without releasing the listeners: a later [open]
  /// goes back to receiving the same events. This is what to call when
  /// signing out.
  void close() {
    _closed = true;
    _fail(null);
    sockets.disconnect();
  }

  /// Reconnects by redoing the handshake.
  ///
  /// Needed when something that travels in it changes (a new token, a
  /// different active business): that data is read when the connection
  /// opens, so simply reconnecting without this would keep it stale.
  Future<void> refresh() async {
    _closed = false;
    _fail(null);

    try {
      await sockets.refresh();
    } catch (e) {
      if (_closed) return;
      _fail(e is Map ? Map<String, dynamic>.from(e) : sockets.exception(e));
    }
  }

  /// **Moves the connection to the business that just became the active
  /// one.** `BusinessService` calls it on every change.
  ///
  /// The server binds a socket to one business for its whole life: the rooms
  /// are joined once, in the handshake (`validate_business`), off the
  /// `business_id` it carried. `useBusiness` only changes what the *next*
  /// handshake sends, so without this a switch leaves the socket in the room
  /// of the business the app started with — the `sale/progress`,
  /// `stock/changed` and `invoice/*` of the one on screen go to a room this app
  /// is not in. A first business created after signing up is the same case
  /// from the other side: that handshake went out with no business, was
  /// refused, and socket.io does not retry a refusal on its own.
  ///
  /// Coming back up in the new room fires [onRestored], which is wanted: the
  /// sections remounted for the new business read before the socket joined
  /// it, and whatever moved in between was emitted to nobody.
  ///
  /// Does nothing while nobody asked for a connection —never opened, or closed
  /// on sign out—: the next [open] already carries the new business.
  Future<void> rebind() async {
    if (_closed || status == SocketStatus.idle) return;

    await refresh();
  }

  // ─── Events ─────────────────────────────────────────────────────────────────
  //
  // These pass straight through to the socket. They can be registered before
  // the connection is open: they're noted down and hooked up on connect, and
  // they survive a [refresh].

  /// Listens for a server event. Returns the function that removes it.
  void Function() on(String event, SocketHandler handler) =>
    sockets.on(event, handler);

  /// **Called when the connection comes back after having been down.** Returns
  /// the function that removes the handler.
  ///
  /// A live screen is only as live as the connection under it. Events are fire
  /// and forget on the server —the room is emitted to and whoever is in it is
  /// told— so what is emitted while this app is not in it is not queued
  /// anywhere: it is gone. A phone that slept, a wifi that changed, a server
  /// that restarted are all the same thing from here, and the screen that comes
  /// out the other side is a board still drawing what was true before the drop,
  /// with nothing to say it is stale.
  ///
  /// Nothing can be replayed —the server does not keep what it emitted— so the
  /// only honest answer is to read again, which is what every listener here
  /// does. It is deliberately **not** fired by the first connection of the run:
  /// nothing had been missed yet, and every screen reads when it opens.
  void Function() onRestored(void Function() handler) {
    _restored.add(handler);

    return () => _restored.remove(handler);
  }

  /// Listens for an event once.
  void once(String event, SocketHandler handler) => sockets.once(event, handler);

  /// Removes a handler, or all of the event's handlers if none is passed.
  void off(String event, [SocketHandler? handler]) => sockets.off(event, handler);

  /// The event as a `Stream`, to consume it with a `StreamBuilder`.
  Stream<dynamic> stream(String event) => sockets.stream(event);

  /// Sends an event without waiting for a response.
  void emit(String event, [dynamic data]) => sockets.emit(event, data);

  /// Sends an event and waits for the server's response, like a REST request
  /// (throws the normalized error if it fails).
  Future<dynamic> request(String event, {dynamic data, Duration? timeout}) =>
    sockets.request(event, data: data, timeout: timeout);

  // ─── Internal ───────────────────────────────────────────────────────────────

  void _onStatus() {
    // Connecting invalidates the previous failure; otherwise an indicator
    // showing `error` would stay red even after the connection was already
    // restored.
    if (isConnected) _error = null;

    _watch();

    notifyListeners();
  }

  /// Turns the status into the one question a live screen has to ask: did the
  /// connection just come back? Only the transition counts — the status is
  /// notified for reasons of its own (a retry, an error cleared) and a screen
  /// that reread on each of them would be rereading while nothing moved.
  void _watch() {
    final live = isConnected;

    if (live == _live) return;

    _live = live;

    if (!live || !_everLive) {
      _everLive = _everLive || live;
      return;
    }

    // A copy: a handler is free to take itself off the list as it runs.
    for (final handler in List<void Function()>.from(_restored)) {
      handler();
    }
  }

  void _fail(Map<String, dynamic>? value) {
    if (_error == null && value == null) return;
    _error = value;
    notifyListeners();
  }
}
