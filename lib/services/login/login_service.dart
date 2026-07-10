import 'package:app/toolkit/api.dart';
import 'package:flutter/widgets.dart' show PageController, BuildContext;

class LoginService {
  //SINGLETON
  static final LoginService _singleton = LoginService._internal();
  factory LoginService() => _singleton;
  LoginService._internal();

  final _pageController = PageController();
  PageController get pageController => _pageController;

  Future<void> signIn(BuildContext context, Map<String, dynamic> data) async {
    final result = await api.post(path: "/sign_in/email/", version: "v1", data: data)
      .catchError((E) {
        if(E is Map) {
          if (!context.mounted) return;

          if (E["action"] != null) {
            throw E["action"];
          } else {
            FloatFlag.of(context).fromError(E);
          }
        }
      });

    if (result == null) throw "";
  }
}