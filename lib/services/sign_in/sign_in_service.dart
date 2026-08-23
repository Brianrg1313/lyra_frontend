import 'package:app/toolkit/api.dart';
import 'package:flutter/widgets.dart' show BuildContext;

// SERVICES
import 'package:app/services/database/database_service.dart';
import 'package:app/services/sign_in/login_method.dart';

/// Servicio del flujo de inicio de sesion.
///
/// No es global: lo proveen las pantallas `Login` y `SignInCode`. Cada una crea
/// su propia instancia, lo cual es seguro porque el estado pendiente del flujo
/// —el correo que espera el codigo— vive en el almacenamiento seguro y no en el
/// servicio.
///
/// El flujo son dos pasos: [resolveMethod] manda el correo y el backend
/// responde con que [LoginMethod] corresponde; recien despues se completa con
/// [signInWithPassword] o [signInWithCode].
class SignInService {
  static const _pendingEmailKey = "SIGN_IN_EMAIL";

  final _database = DatabaseService();

  Future<dynamic> _post(BuildContext context, String path, Map<String, dynamic> data) =>
    api.post(path: path, version: "v1", data: data)
      .catchError((E) {
        if (E is Map) {
          if (!context.mounted) return;

          if (E["action"] != null) throw E["action"];

          FloatFlag.of(context).fromError(E);
        }
      });

  /// Primer paso: manda solo el correo y devuelve el metodo con el que hay que
  /// seguir, o `null` si el backend contesto uno que esta version no conoce.
  ///
  /// Cuando es [LoginMethod.code] el mismo endpoint ya mando el codigo al
  /// correo; aca solo se guarda a que cuenta pertenece.
  Future<LoginMethod?> resolveMethod(BuildContext context, String email) async {
    final method = await _post(context, "/authentication/sign_in/email/", {"EMAIL": email});

    if (method == null) throw "";

    final resolved = LoginMethod.from(method);

    // La pantalla del codigo es otra ruta, con su propia instancia de este
    // servicio: sin dejar el correo guardado no sabria de que cuenta es el
    // codigo que se escribe.
    if (resolved == LoginMethod.code) {
      await _database.toSecure(_pendingEmailKey, email);
    }

    return resolved;
  }

  Future<void> signInWithPassword(BuildContext context, String email, String password) async {
    final token = await _post(context, "/authentication/sign_in/password/", {
      "EMAIL": email,
      "PASSWORD": password
    });

    if (token == null) throw "";

    await _openSession(token as String);
  }

  Future<void> signInWithCode(BuildContext context, String code) async {
    final email = await _database.fromSecure<String>(_pendingEmailKey);
    if (email == null) throw "";
    if (!context.mounted) throw "";

    final token = await _post(context, "/authentication/sign_in/code/", {
      "EMAIL": email,
      "CODE": code
    });

    if (token == null) throw "";

    await _openSession(token as String);
    await _database.deleteSecure(_pendingEmailKey);
  }

  /// Reenvia el codigo repitiendo el primer paso con el correo pendiente: el
  /// backend manda uno nuevo cada vez que resuelve el metodo `code`, asi que no
  /// hace falta un endpoint propio.
  Future<void> resendCode(BuildContext context) async {
    final email = await _database.fromSecure<String>(_pendingEmailKey);
    if (email == null) throw "";
    if (!context.mounted) throw "";

    final method = await _post(context, "/authentication/sign_in/email/", {"EMAIL": email});

    if (method == null) throw "";
  }

  Future<void> _openSession(String token) async {
    api.token = token;
    await _database.toSecure(api.current.tokenName, token);
  }
}
