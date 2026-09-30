import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'desktop/_body.dart';

/// First page of a fresh install that can use the local network (plan §7.4): online, this
/// computer is the server, or connect to a server.
class DeploymentChooser extends PageBuilder {
  const DeploymentChooser({super.key});

  static const routeKey = "deployment";
  static const path = "/deployment";

  @override
  Widget build(BuildContext context) => const DesktopBody();
}
