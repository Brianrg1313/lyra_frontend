import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/sign_in/sign_in_service.dart';

// WIDGETS
import 'desktop/_body.dart';

class Login extends PageBuilder {
  const Login({super.key});

  @override
  Widget build(BuildContext context) => Provider(
    create: (_) => SignInService(),
    dispose: (_, SignInService service) => service.dispose(),
    child: const DesktopBody()
  );
}
