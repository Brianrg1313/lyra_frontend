import 'dart:convert';

import 'package:app/toolkit/api.dart';
import 'package:flutter/widgets.dart' show BuildContext;

// SERVICES
import 'package:app/services/database/database_service.dart';

/// Service for the sign-up flow.
///
/// It is not global: provided by the `SignUp` and `VerifyCode` screens. Each
/// one creates its own instance, which is safe because the flow's pending
/// state lives in secure storage, not in the service.
class SignUpService {
  static const _pendingUsernameKey = "SIGN_UP_USERNAME";
  static const _pendingDataKey = "SIGN_UP_DATA";

  final _database = DatabaseService();

  Future<String?> _requestCode(BuildContext context, Map<String, dynamic> data) async {
    final username = await api.post(path: "/authentication/sign_up/email/", version: "v1", data: data)
      .catchError((E) {
        if (E is Map) {
          if (!context.mounted) return;

          if (E["action"] != null) throw E["action"];

          FloatFlag.of(context).fromError(E);
        }
      });

    return username as String?;
  }

  Future<void> signUp(BuildContext context, Map<String, dynamic> data) async {
    final username = await _requestCode(context, data);

    if (username == null) throw "";

    await _database.toSecure(_pendingUsernameKey, username);
    await _database.toSecure(_pendingDataKey, jsonEncode(data));
  }

  /// Re-sends the verification code by staging the sign-up again with the
  /// same data submitted originally, since the backend has no dedicated
  /// resend endpoint. This mints a new username, so the pending one is
  /// overwritten with it.
  Future<void> resendCode(BuildContext context) async {
    final raw = await _database.fromSecure<String>(_pendingDataKey);
    if (raw == null) throw "";
    if (!context.mounted) throw "";

    final username = await _requestCode(context, jsonDecode(raw) as Map<String, dynamic>);

    if (username == null) throw "";

    await _database.toSecure(_pendingUsernameKey, username);
  }

  Future<void> verifyCode(BuildContext context, Map<String, dynamic> data) async {
    final username = await _database.fromSecure<String>(_pendingUsernameKey);
    if (username == null) throw "";

    final token = await api.post(
      path: "/authentication/sign_up/create/",
      version: "v1",
      data: {"USERNAME": username, "CODE": data["CODE"]}
    ).catchError((E) {
      if (E is Map) {
        if (!context.mounted) return;

        if (E["action"] != null) throw E["action"];

        FloatFlag.of(context).fromError(E);
      }
    });

    if (token == null) throw "";

    api.token = token;
    await _database.toSecure(api.current.tokenName, token);
    await _database.deleteSecure(_pendingUsernameKey);
    await _database.deleteSecure(_pendingDataKey);
  }
}
