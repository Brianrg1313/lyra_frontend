import 'package:app/toolkit/api.dart';
import 'package:flutter/widgets.dart' show PageController, BuildContext;

/// Servicio del flujo de inicio de sesion.
///
/// No es global: lo provee la pantalla `Login`, de modo que la app no lo
/// registra mientras no se este usando el flujo.
class SignInService {
  final _pageController = PageController();
  PageController get pageController => _pageController;

  void dispose() => _pageController.dispose();

  Future<void> signIn(BuildContext context, Map<String, dynamic> data) async {
    final result = await api.post(path: "/authentication/email/", version: "v1", data: data)
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

    print(result);

    if (result == null) throw "";
  }
}