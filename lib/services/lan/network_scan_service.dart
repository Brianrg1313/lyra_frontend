import 'dart:async';

import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/toolkit/api.dart';
import 'package:app/toolkit/lan.dart';
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
/// While the answer isn't [NetworkReach.online], [watch] looks again every [every]: a master
/// switched on, or the internet coming back, changes the sign in by itself. [hold] stops that
/// while the person is doing something the change would interrupt.
///
/// Flow-scoped: the sign in provides it.
class NetworkScanService extends ChangeNotifier {
  NetworkScanService({
    Future<bool> Function()? cloud,
    Future<List<LanFound>> Function()? discover,
    Future<bool> Function()? canHost,
    this.every = const Duration(seconds: 15),
  }) : _cloud = cloud ?? cloudReachable,
       _discover = discover ?? discoverMasters,
       _canHost = canHost ?? _engineHere;

  final Future<bool> Function() _cloud;
  final Future<List<LanFound>> Function() _discover;
  final Future<bool> Function() _canHost;
  final Duration every;

  NetworkReach _reach = NetworkReach.searching;
  NetworkReach get reach => _reach;

  List<LanFound> _masters = const [];

  /// The masters seen on the last look; on [NetworkReach.master], at least one.
  List<LanFound> get masters => _masters;

  bool _canHostHere = false;

  /// Whether this computer can become the master: a desktop with the engine, not set up yet.
  bool get canHost => _canHostHere;

  Timer? _timer;
  bool _held = false;
  bool _looking = false;
  bool _disposed = false;

  /// Looks once. The answer stays on the last one while it looks again, so the page doesn't
  /// flicker through a loader every [every].
  Future<void> scan() async {
    if (_looking) return;
    _looking = true;

    try {
      final (online, masters, canHost) = await (
        _cloud(),
        _discover().catchError((Object _) => const <LanFound>[]),
        _canHost().catchError((Object _) => false)
      ).wait;

      if (_disposed) return;

      _masters = masters;
      _canHostHere = canHost;
      _reach = online ? NetworkReach.online : masters.isNotEmpty ? NetworkReach.master : NetworkReach.none;
      notifyListeners();
    } finally {
      _looking = false;
    }
  }

  /// Looks now, then every [every] until the backend answers.
  Future<void> watch() async {
    _timer?.cancel();
    _timer = Timer.periodic(every, (_) {
      if (_held) return;
      if (_reach == NetworkReach.online) return _timer?.cancel();

      scan();
    });

    await scan();
  }

  /// Stops looking while [held]: a sign in or a setup under way keeps the page it started on.
  void hold(bool held) => _held = held;

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }

  /// A computer whose engine is set up already is a master that lost its pairing: it isn't
  /// offered a second one (the setup would refuse it anyway).
  static Future<bool> _engineHere() async => await LocalServerService().refresh() == LocalServerStatus.notSetUp;
}
