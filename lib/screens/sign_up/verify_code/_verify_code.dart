import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/sign_up/sign_up_service.dart';

// WIDGETS
import 'desktop/_body.dart';

class VerifyCode extends PageBuilder {
  const VerifyCode({super.key});

  @override
  Widget build(BuildContext context) => Provider(
    create: (_) => SignUpService(),
    child: const DesktopBody()
  );
}
