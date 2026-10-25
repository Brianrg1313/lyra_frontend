import 'package:app/toolkit/backend/api.dart';
import 'package:app/toolkit/backend/deployment.dart';
import 'package:flutter/widgets.dart' show BuildContext;

// SERVICES
import 'package:app/services/client/sources/session_source.dart';
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
  SignInService({SessionSource? source}) : _injected = source;

  final SessionSource? _injected;

  SessionSource get _source => _injected ?? Sources.session;

  static const _pendingEmailKey = "SIGN_IN_EMAIL";
  static const _pendingAccountKey = "SIGN_IN_ACCOUNT";

  final _database = DatabaseService();

  /// Shows a refusal and answers null for it, except one with an `action`,
  /// which is thrown for the page to follow. A [quiet] one shows nothing.
  Future<T?> _guard<T>(BuildContext context, Future<T> call, {bool quiet = false}) =>
    call.then<T?>((answer) => answer).catchError((E) {
      if (E is Map) {
        if (!context.mounted) return null;

        if (E["action"] != null) throw E["action"];

        if (!quiet) FloatFlag.of(context).fromError(E);
      }

      return null;
    });

  /// First step: sends only the email. The backend answers whether it has an
  /// account and the [LoginMethod] to continue with (`null` if this version
  /// does not know it).
  ///
  /// When a code follows —sign in by code, or any email without an account—
  /// the same endpoint already sent it; here it is only stored which email it
  /// belongs to.
  ///
  /// A [quiet] check shows no refusal: one nobody asked for (the home offering the online sign in).
  Future<({bool account, LoginMethod? method})> verifyEmail(BuildContext context, String email, {bool quiet = false}) async {
    final answer = await _guard(context, _source.identify(email), quiet: quiet);

    if (answer == null) throw "";

    final (:account, :method) = answer;

    // The code screen is another route, with its own service instance:
    // without leaving these stored it would not know which account the
    // written code belongs to, nor whether it signs in or signs up.
    if (!account || method == LoginMethod.code) {
      await _database.toSecure(_pendingEmailKey, email);
      await _database.toSecure(_pendingAccountKey, account.toString());
    }

    return (account: account, method: method);
  }

  Future<void> signInWithPassword(BuildContext context, String email, String password) async {
    await openSession(await _guard<Object?>(context, _source.signInWithPassword(email, password)));
  }

  Future<void> signInWithCode(BuildContext context, String code) async {
    final email = await _database.fromSecure<String>(_pendingEmailKey);
    if (email == null) throw "";
    if (!context.mounted) throw "";

    await openSession(await _guard<Object?>(context, _source.signInWithCode(email, code)));
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

    final answer = await _guard(context, _source.identify(email));

    if (answer == null) throw "";
  }
}
