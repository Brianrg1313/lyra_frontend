import 'dart:async';

import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/toolkit/api.dart';
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
/// answers ([cloudReachable]) and which masters advertise `_lyra._tcp` on the LAN
/// ([discoverMasters]), both at once. Every master answers mDNS while its engine runs, so a new
/// device finds it without being told where it is.
///
/// [watch] looks again every [every], both ways: a master switched on, the internet coming back or
/// going away changes the sign in by itself. With a [CloudPresence] the backend is followed live
/// instead of every [every]: its socket connecting is [NetworkReach.online] at once, and its drop
/// looks at once. [hold] stops all of that while the person is doing something the change would
/// interrupt.
///
/// Flow-scoped: the sign in provides it.
class NetworkScanService extends ChangeNotifier {
  NetworkScanService({
    Future<bool> Function()? cloud,
    Future<List<LanFound>> Function()? discover,
    Future<LocalServerStatus> Function()? engine,
    CloudPresence? presence,
    this.every = const Duration(seconds: 15),
  }) : _presence = presence,
       _cloud = cloud ?? cloudReachable,
       _discover = discover ?? discoverMasters,
       _engine = engine ?? _engineHere;

  final Future<bool> Function() _cloud;
  final Future<List<LanFound>> Function() _discover;
  final Future<LocalServerStatus> Function() _engine;
  final CloudPresence? _presence;
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

  bool get _live => _presence?.live.value ?? false;

  /// Looks once. The answer stays on the last one while it looks again, so the page doesn't
  /// flicker through a loader every [every].
  Future<void> scan() async {
    if (_looking) {
      _again = true;
      return;
    }
    _looking = true;
    _again = false;

    try {
      final (online, masters, engine) = await (
        _cloud(),
        _discover().catchError((Object _) => const <LanFound>[]),
        _engine().catchError((Object _) => LocalServerStatus.unavailable)
      ).wait;

      if (_disposed) return;

      _masters = masters;
      _engineStatus = engine;
      // The socket connecting while the HTTP question was out is the newer answer.
      _reach = online || _live ? NetworkReach.online : masters.isNotEmpty ? NetworkReach.master : NetworkReach.none;
      notifyListeners();
    } finally {
      _looking = false;
    }

    if (_again && !_disposed) await scan();
  }

  /// Looks now, then every [every] for as long as the page lives.
  Future<void> watch() async {
    _timer?.cancel();
    _timer = Timer.periodic(every, (_) => _tick());
    _presence?.live.addListener(_presenceChanged);
    _presence?.start();

    await scan();
  }

  /// While online only the backend is asked (no mDNS every tick); a miss looks at everything,
  /// which asks the backend once more, so one dropped request doesn't take the cloud's form away.
  Future<void> _tick() async {
    if (_held || _looking) return;
    if (_reach != NetworkReach.online) return scan();

    _looking = true;
    final bool online;
    try {
      online = await _cloud();
    } finally {
      _looking = false;
    }

    if (!online && !_held && !_disposed) await scan();
  }

  /// The socket connected: online now, the masters as last seen. It dropped: a full look now,
  /// whose HTTP question decides, since a backend without `/presence` never connects it.
  void _presenceChanged() {
    if (_held || _disposed) return;

    if (_live) {
      if (_reach == NetworkReach.online) return;
      _reach = NetworkReach.online;
      notifyListeners();
    } else if (_reach == NetworkReach.online) {
      scan();
    }
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
    _presence?.live.removeListener(_presenceChanged);
    _presence?.stop();
    super.dispose();
  }

  /// The engine on this computer: [LocalServerStatus.unavailable] where none can run.
  static Future<LocalServerStatus> _engineHere() => LocalServerService().refresh();
}
