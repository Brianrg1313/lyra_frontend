import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'desktop/_body.dart';

/// Where a `local` install lands (plan §7.4): the master's engine started, the connection
/// opened, unlocked and signed in; then, until the domains arrive (plan phase 4), the server's
/// devices.
class LanHome extends PageBuilder {
  const LanHome({super.key});

  static const routeKey = "lan";
  static const path = "/lan";

  @override
  Widget build(BuildContext context) => const DesktopBody();
}
