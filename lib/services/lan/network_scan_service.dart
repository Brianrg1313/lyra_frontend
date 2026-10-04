import 'dart:async';

import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/toolkit/lan.dart';
import 'package:app/services/connection/cloud_presence.dart';
import 'package:app/services/local_server/local_server_service.dart';

/// What a device without a pairing can reach, which decides its sign in (plan §7.4).
enum NetworkReach {
  /// The first look hasn't answered yet.
  searching,

  /// The backend answers: the cloud's sign in, whatever is on the LAN.
  online,

  /// No backend, but a master answers mDNS on the LAN: its sign in, which pairs this device.
  master,

  /// Neither: this computer can become the master, or nothing can be done yet.
  none,
}

/// Looks at the network a device without a pairing is on (plan §5.2, §7.4): whether the backend
/// is there (its [CloudPresence], the `/presence` socket: nothing asks it on a timer) and which
/// masters advertise `_lyra._tcp` on the LAN ([discoverMasters]). Every master answers mDNS while
/// its engine runs, so a new device finds it without being told where it is.
///
/// [watch] follows the presence (connected is [NetworkReach.online] at once, a drop the LAN's
/// answer at once) and looks at the LAN again every [every] while offline: a master switched on
/// changes the sign in by itself. [hold] stops all of that while the person is doing something the
/// change would interrupt.
///
/// Flow-scoped: the sign in provides it.
class NetworkScanService extends ChangeNotifier {
  NetworkScanService({
    required CloudPresence presence,
    Future<List<LanFound>> Function()? discover,
    Future<LocalServerStatus> Function()? engine,
    this.every = const Duration(seconds: 15),
  }) : _presence = presence,
       _discover = discover ?? discoverMasters,
       _engine = engine ?? _engineHere;

  final Future<List<LanFound>> Function() _discover;
  final Future<LocalServerStatus> Function() _engine;
  final CloudPresence _presence;
  final Duration every;

  NetworkReach _reach = NetworkReach.searching;
  NetworkReach get reach => _reach;

  List<LanFound> _masters = const [];

  /// The masters seen on the last look; on [NetworkReach.master], at least one.
  List<LanFound> get masters => _masters;

  LocalServerStatus _engineStatus = LocalServerStatus.unavailable;

  /// Whether this computer can become the master: a desktop with the engine, not set up yet.
  bool get canHost => _engineStatus == LocalServerStatus.notSetUp;

  /// Whether this computer is a master already, its engine set up (running or not). The app can
  /// have forgotten it (its pairing left, the key store wiped): the sign in goes to it anyway,
  /// and `/lan` certifies the app again (`LanService.enrollMaster`).
  bool get masterHere => switch (_engineStatus) {
    LocalServerStatus.stopped || LocalServerStatus.starting || LocalServerStatus.locked ||
    LocalServerStatus.ready || LocalServerStatus.stopping => true,
    _ => false
  };

  Timer? _timer;
  bool _held = false;
  bool _looking = false;
  bool _again = false;
  bool _disposed = false;

  /// Whether the LAN has been looked at once: offline, the sign in waits for it.
  bool _lanSeen = false;

  /// Looks at the LAN and this computer's engine once. The answer stays on the last one while it
  /// looks again, so the page doesn't flicker through a loader every [every].
  Future<void> scan() async {
    if (_looking) {
      _again = true;
      return;
    }
    _looking = true;
    _again = false;

    try {
      final (masters, engine) = await (
        _discover().catchError((Object _) => const <LanFound>[]),
        _engine().catchError((Object _) => LocalServerStatus.unavailable)
      ).wait;

      if (_disposed) return;

      _masters = masters;
      _engineStatus = engine;
      _lanSeen = true;
      _resolve(force: true);
    } finally {
      _looking = false;
    }

    if (_again && !_disposed) await scan();
  }

  /// The reach from the presence and the last look at the LAN: searching until the socket has
  /// answered, and offline until the LAN has too.
  void _resolve({bool force = false}) {
    final live = _presence.live.value;
    final reach = live == true
      ? NetworkReach.online
      : live == null || !_lanSeen
        ? NetworkReach.searching
        : _masters.isNotEmpty ? NetworkReach.master : NetworkReach.none;

    if (reach == _reach && !force) return;
    _reach = reach;
    notifyListeners();
  }

  /// Follows the presence and looks at the LAN now, then every [every] while offline, for as long
  /// as the page lives.
  Future<void> watch() async {
    _timer?.cancel();
    _timer = Timer.periodic(every, (_) => _tick());
    _presence.live.addListener(_presenceChanged);
    _presence.start();

    await scan();
  }

  /// Online, the LAN doesn't change the sign in: only offline is it looked at again.
  Future<void> _tick() async {
    if (_held || _looking || _reach == NetworkReach.online) return;

    await scan();
  }

  /// The socket connected: online now, the masters as last seen. It dropped: offline now from
  /// the last look at the LAN, and a new look at once, so the offline sign in it picks is current.
  void _presenceChanged() {
    if (_held || _disposed) return;

    final dropped = _reach == NetworkReach.online && _presence.live.value == false;
    _resolve();
    if (dropped) unawaited(scan());
  }

  /// Stops looking while [held]: a sign in or a setup under way keeps the page it started on.
  /// Released, what the socket said meanwhile counts at once.
  void hold(bool held) {
    _held = held;
    if (!held) _presenceChanged();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _presence.live.removeListener(_presenceChanged);
    _presence.stop();
    super.dispose();
  }

  /// The engine on this computer: [LocalServerStatus.unavailable] where none can run.
  static Future<LocalServerStatus> _engineHere() => LocalServerService().refresh();
}
