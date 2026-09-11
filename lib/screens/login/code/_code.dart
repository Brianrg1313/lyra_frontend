import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/sign_in/sign_in_service.dart';

// WIDGETS
import 'desktop/_body.dart';

/// Second step of the login when the account's method is the email code. Reached
/// from `Login`, which already triggered sending the code when it resolved the
/// method.
class SignInCode extends PageBuilder {
  const SignInCode({super.key});

  @override
  Widget build(BuildContext context) => Provider(
    create: (_) => SignInService(),
    child: const DesktopBody()
  );
}
