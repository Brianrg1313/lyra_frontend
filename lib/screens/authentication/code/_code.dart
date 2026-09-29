import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/sign_in/sign_in_service.dart';
import 'package:app/services/sign_up/sign_up_service.dart';

// WIDGETS
import 'desktop/_body.dart';

/// The email code step, for sign in and sign up alike. Reached from
/// `Authentication` once `email/verify` already sent the code; whether it
/// signs in or signs up is what that answer left in `SignInService.pending`.
class AuthCode extends PageBuilder {
  const AuthCode({super.key});

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      Provider(create: (_) => SignInService()),
      Provider(create: (_) => SignUpService())
    ],
    child: const DesktopBody()
  );
}
