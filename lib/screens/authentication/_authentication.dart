import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/sign_in/sign_in_service.dart';

// WIDGETS
import 'desktop/_body.dart';

/// Single entry for signing in and signing up: the person only types the
/// email, and `email/verify` decides which of the two flows follows.
class Authentication extends PageBuilder {
  const Authentication({super.key});

  @override
  Widget build(BuildContext context) => Provider(
    create: (_) => SignInService(),
    child: const DesktopBody()
  );
}
