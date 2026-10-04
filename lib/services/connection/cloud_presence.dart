import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:core/socket.dart' show SocketAPI, SocketStatus;

// SERVICES
import 'package:app/toolkit/sockets.dart' show presenceSocket;

/// Whether the backend is there, said as it changes: a socket on its `/presence` namespace, open
/// without a session (`model:/bridge/presence.js`).
///
/// Connecting says it at once, and so does a drop the network reports (the backend stopped, the
/// adapter went down). A silent drop (a cable pulled further away, no FIN) is what socket.io's
/// heartbeat takes up to 45 s to notice, so `alive` is asked every [every] while connected, and
/// one unanswered within [timeout] is a drop too. Its answer coming back says it returned.
///
/// [live] is a signal, not the verdict: a backend without the namespace refuses the socket, so a
/// [NetworkScanService] still asks over HTTP when it turns false.
class CloudPresence {
  CloudPresence({
    SocketAPI? socket,
    this.every = const Duration(seconds: 2),
    this.timeout = const Duration(seconds: 2),
  }) : _socket = socket ?? presenceSocket;

  final SocketAPI _socket;
  final Duration every;
  final Duration timeout;

  final live = ValueNotifier<bool>(false);

  Timer? _timer;
  bool _asking = false;

  void start() {
    _socket.status.addListener(_status);
    _socket.connect().catchError((Object _) {});
    _timer = Timer.periodic(every, (_) => _alive());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _socket.status.removeListener(_status);
    _socket.disconnect();
    live.value = false;
  }

  void _status() => live.value = _socket.status.value == SocketStatus.connected;

  Future<void> _alive() async {
    if (_asking || _socket.status.value != SocketStatus.connected) return;
    _asking = true;

    try {
      await _socket.request("alive", timeout: timeout);
      live.value = _socket.status.value == SocketStatus.connected;
    } catch (_) {
      live.value = false;
    } finally {
      _asking = false;
    }
  }
}
