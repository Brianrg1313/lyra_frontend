import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'desktop/_body.dart';

/// Landing of a person with no company and no invitation (`business.none`):
/// the dashboard has nothing to show them until they have one.
class Welcome extends PageBuilder {
  const Welcome({super.key});

  static const routeKey = "welcome";
  static const path = "/welcome";

  @override
  Widget build(BuildContext context) => const DesktopBody();
}
