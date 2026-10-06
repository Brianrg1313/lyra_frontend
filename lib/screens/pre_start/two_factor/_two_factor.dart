import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'desktop/_body.dart';

/// The second factor a new session owes (`security.two_factor`): the last step of signing in on
/// an account that has one. Until it passes, the backend opens nothing else.
class TwoFactorCheck extends PageBuilder {
  const TwoFactorCheck({super.key});

  static const routeKey = "two_factor";
  static const path = "/two_factor";

  @override
  Widget build(BuildContext context) => const DesktopBody();
}
