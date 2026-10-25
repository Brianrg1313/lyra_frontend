import 'package:app/toolkit/backend/api.dart';
import 'package:flutter/widgets.dart' show BuildContext;

/// Service for the sign-up flow, reached when `email/verify` answers
/// `account: false` (the code is already sent by then).
///
/// It is not global: provided by the `AuthCode` screen. The pending email
/// lives in `SignInService`, which saved it.
class SignUpService {
  /// Handed by `sign_up/code` and spent by `sign_up/names`. Kept only in
  /// memory, as the backend asks: when the names step fails (e.g.
  /// `username_taken`) the retry reuses it instead of the already spent code.
  String? _ticket;

  /// Whether the code was already accepted: a failure from here on is the
  /// names', not the code's.
  bool get hasTicket => _ticket != null;

  Future<dynamic> _post(BuildContext context, String path, Map<String, dynamic> data) =>
    api.post(path: path, version: "v1", data: data)
      .catchError((E) {
        if (E is Map) {
          if (!context.mounted) return;

          if (E["action"] != null) throw E["action"];

          FloatFlag.of(context).fromError(E);
        }
      });

  /// `sign_up/code` (email + code → ticket), then `sign_up/names` (ticket +
  /// names → token). The account exists only after the second step.
  Future<void> signUp(BuildContext context, {
    required String email,
    required String code,
    required String firstName,
    required String lastName
  }) async {
    if (_ticket == null) {
      final ticket = await _post(context, "/authentication/email/sign_up/code/", {
        "EMAIL": email,
        "CODE": code
      });

      if (ticket is! String) throw "";
      _ticket = ticket;
    }

    if (!context.mounted) throw "";

    final token = await _post(context, "/authentication/email/sign_up/names/", {
      "TICKET": _ticket,
      "FIRST_NAME": firstName,
      "LAST_NAME": lastName
    });

    await openSession(token);
    _ticket = null;
  }
}
