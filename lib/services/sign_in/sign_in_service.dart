import 'package:app/toolkit/api.dart';
import 'package:flutter/widgets.dart' show BuildContext;

// SERVICES
import 'package:app/services/database/database_service.dart';
import 'package:app/services/sign_in/login_method.dart';

/// Service for the sign-in flow.
///
/// It is not global: provided by the `Login` and `SignInCode` screens. Each one
/// creates its own instance, which is safe because the flow's pending state
/// —the email waiting for the code— lives in secure storage and not in the
/// service.
///
/// The flow is two steps: [resolveMethod] sends the email and the backend
/// responds with which [LoginMethod] applies; only afterwards is it completed
/// with [signInWithPassword] or [signInWithCode].
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

  /// First step: sends only the email and returns the method with which to
  /// continue, or `null` if the backend answered with one this version does not
  /// know.
  ///
  /// When it is [LoginMethod.code] the same endpoint already sent the code to
  /// the email; here it is only stored which account it belongs to.
  Future<LoginMethod?> resolveMethod(BuildContext context, String email) async {
    final method = await _post(context, "/authentication/sign_in/email/", {"EMAIL": email});

    if (method == null) throw "";

    final resolved = LoginMethod.from(method);

    // The code screen is another route, with its own instance of this service:
    // without leaving the email stored it would not know which account the
    // written code belongs to.
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

  /// Resends the code by repeating the first step with the pending email: the
  /// backend sends a new one every time it resolves the `code` method, so a
  /// dedicated endpoint is not needed.
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
