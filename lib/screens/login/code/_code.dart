import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/sign_in/sign_in_service.dart';

// WIDGETS
import 'desktop/_body.dart';

/// Segundo paso del login cuando el metodo de la cuenta es el codigo por
/// correo. Se llega desde `Login`, que ya provoco el envio del codigo al
/// resolver el metodo.
class SignInCode extends PageBuilder {
  const SignInCode({super.key});

  @override
  Widget build(BuildContext context) => Provider(
    create: (_) => SignInService(),
    child: const DesktopBody()
  );
}
