import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'desktop/_body.dart';

/// Makes this computer the master (plan §7.4): the owner, the unlock mode, the licence, then
/// the recovery key, shown once.
class MasterSetup extends PageBuilder {
  const MasterSetup({super.key});

  static const routeKey = "deployment_master";
  static const path = "/deployment/master";

  @override
  Widget build(BuildContext context) => const DesktopBody();
}
