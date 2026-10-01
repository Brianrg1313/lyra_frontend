import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/toolkit/api.dart';
import 'package:app/services/sign_in/sign_in_service.dart';

// WIDGETS
import 'desktop/_body.dart';
import 'auth_offline.dart';

/// Single entry for signing in and signing up: the person only types the
/// email, and `email/verify` decides which of the two flows follows.
///
/// The form is drawn only when our backend answers ([cloudReachable]): without
/// it nothing on it can work, so [AuthOffline] takes its place.
class Authentication extends PageBuilder {
  const Authentication({super.key, this.reachable = cloudReachable});

  /// Asks whether the backend answers. Injected by the tests.
  final Future<bool> Function() reachable;

  @override
  Widget build(BuildContext context) => Provider(
    create: (_) => SignInService(),
    child: _Gate(reachable: reachable)
  );
}

class _Gate extends StatefulWidget {
  const _Gate({required this.reachable});

  final Future<bool> Function() reachable;

  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  late Future<bool> _online = widget.reachable();

  void _retry() => setState(() {
    _online = widget.reachable();
  });

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: _online,
    builder: (context, snapshot) => switch (snapshot.data) {
      null => const Center(child: Loading()),
      true => const DesktopBody(),
      false => AuthOffline(onRetry: _retry)
    }
  );
}
