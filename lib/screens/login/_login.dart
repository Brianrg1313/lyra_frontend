import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
// import 'package:app/services/login/login_service.dart';

class Login extends PageBuilder {
  const Login({super.key});

  @override
  Widget build(BuildContext context) => Skeleton.simple(
    padding: EdgeInsets.all(AppSize.spaceM),
    body: Center(
      child: TextLarge(S.of(context).login)
    )
  );
}
