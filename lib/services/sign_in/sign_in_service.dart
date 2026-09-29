import 'package:app/toolkit/api.dart';
import 'package:flutter/widgets.dart' show BuildContext;

// SERVICES
import 'package:app/services/database/database_service.dart';
import 'package:app/services/sign_in/login_method.dart';

/// Service for the sign-in flow.
///
/// It is not global: provided by the `Authentication` and `AuthCode` screens. Each one
/// creates its own instance, which is safe because the flow's pending state
/// —the email waiting for the code and whether it has an account— lives in
/// secure storage and not in the service.
///
/// The flow is two steps: [verifyEmail] sends the email and the backend
/// responds whether it has an account and which [LoginMethod] applies; only
/// afterwards is it completed with [signInWithPassword] or [signInWithCode].
class SignInService {
  static const _pendingEmailKey = "SIGN_IN_EMAIL";
  static const _pendingAccountKey = "SIGN_IN_ACCOUNT";

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

  /// First step: sends only the email. The backend answers whether it has an
  /// account and the [LoginMethod] to continue with (`null` if this version
  /// does not know it).
  ///
  /// When a code follows —sign in by code, or any email without an account—
  /// the same endpoint already sent it; here it is only stored which email it
  /// belongs to.
  Future<({bool account, LoginMethod? method})> verifyEmail(BuildContext context, String email) async {
    final answer = await _post(context, "/authentication/email/verify/", {"EMAIL": email});

    if (answer is! Map) throw "";

    final account = answer["account"] == true;
    final method = LoginMethod.from(answer["method"]);

    // The code screen is another route, with its own service instance:
    // without leaving these stored it would not know which account the
    // written code belongs to, nor whether it signs in or signs up.
    if (!account || method == LoginMethod.code) {
      await _database.toSecure(_pendingEmailKey, email);
      await _database.toSecure(_pendingAccountKey, account.toString());
    }

    return (account: account, method: method);
  }

  /// Answers `{token, two_factor}`. A non-null `two_factor` means the session
  /// still has to pass `two_factor/verify`; there is no screen for it yet, so
  /// the token is saved either way.
  Future<void> signInWithPassword(BuildContext context, String email, String password) async {
    final answer = await _post(context, "/authentication/email/sign_in/password/", {
      "EMAIL": email,
      "PASSWORD": password
    });

    await openSession(answer is Map ? answer["token"] : null);
  }

  /// Answers `{token, two_factor}` like the password sign in. After a code
  /// `two_factor` can only be `null` or `"app"`; the app step has no page yet,
  /// so it is ignored for now.
  Future<void> signInWithCode(BuildContext context, String code) async {
    final email = await _database.fromSecure<String>(_pendingEmailKey);
    if (email == null) throw "";
    if (!context.mounted) throw "";

    final answer = await _post(context, "/authentication/email/sign_in/code/", {
      "EMAIL": email,
      "CODE": code
    });

    await openSession(answer is Map ? answer["token"] : null);
    await clearPending();
  }

  /// Email the code was sent to and whether it has an account, saved by
  /// [verifyEmail]. `email` is `null` when the code page is opened without
  /// going through the auth page (e.g. a reload).
  Future<({String? email, bool account})> pending() async => (
    email: await _database.fromSecure<String>(_pendingEmailKey),
    account: await _database.fromSecure<bool>(_pendingAccountKey) ?? false
  );

  /// Forgets the pending email once a session is open, by sign in or sign up.
  Future<void> clearPending() async {
    await _database.deleteSecure(_pendingEmailKey);
    await _database.deleteSecure(_pendingAccountKey);
  }

  /// Resends the code by repeating `email/verify` with the pending email: it
  /// mails a new code every time and voids the previous one.
  Future<void> resendCode(BuildContext context) async {
    final email = await _database.fromSecure<String>(_pendingEmailKey);
    if (email == null) throw "";
    if (!context.mounted) throw "";

    final answer = await _post(context, "/authentication/email/verify/", {"EMAIL": email});

    if (answer == null) throw "";
  }
}
