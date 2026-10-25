import 'package:flutter/foundation.dart';
import 'package:core/socket.dart' show SocketAPI, SocketStatus;

// SERVICES
import 'package:app/toolkit/backend/sockets.dart' show presenceSocket;

/// Whether the backend is there, said as it changes: a socket on its `/presence` namespace, open
/// without a session (`model:/bridge/presence.js`). It is the only way the app knows: nothing
/// asks the backend on a timer.
///
/// [live] is null until the socket's first answer (connected, or its first attempt refused or
/// timed out), true while connected, false once it drops or can't connect; socket.io keeps
/// reconnecting on its own (`presenceSocket`, every 2 s at most), so the backend's return turns it
/// true again. A drop the network reports (the backend stopped, the adapter went down) says it at
/// once; a silent one (a cable pulled further away, no FIN) waits for socket.io's own heartbeat.
///
/// The sign in and [HybridService] each hold one over the same socket, and the online sign in
/// opens over a session on the master alone: the socket opens with the first and closes with the
/// last, so one leaving doesn't blind the other.
class CloudPresence {
  CloudPresence({SocketAPI? socket}) : _socket = socket ?? presenceSocket;

  final SocketAPI _socket;

  final live = ValueNotifier<bool?>(null);

  /// How many started presences hold each socket.
  static final Map<SocketAPI, int> _holders = {};

  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;

    _socket.status.addListener(_status);
    // The first holder opens it, and its status until then is the last holder's closing (a
    // `disconnected` that says nothing of the backend): only one already open is read now.
    final holders = _holders[_socket] = (_holders[_socket] ?? 0) + 1;
    if (holders == 1) {
      _socket.connect().catchError((Object _) {});
    } else {
      _status();
    }
  }

  void stop() {
    if (!_started) return;
    _started = false;

    _socket.status.removeListener(_status);
    final holders = (_holders[_socket] ?? 1) - 1;
    if (holders <= 0) {
      _holders.remove(_socket);
      _socket.disconnect();
    } else {
      _holders[_socket] = holders;
    }
    live.value = null;
  }

  /// `connecting` (a first attempt, or a retry after a drop already said false) changes nothing.
  void _status() {
    switch (_socket.status.value) {
      case SocketStatus.connected: live.value = true;
      case SocketStatus.reconnecting || SocketStatus.disconnected: live.value = false;
      case SocketStatus.connecting || SocketStatus.idle: break;
    }
  }
}
