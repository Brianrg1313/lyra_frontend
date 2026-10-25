import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/toolkit/backend/api.dart';

import './two_factor_model.dart';

enum AccountSecurityStatus { idle, loading, ready, error }

/// The signed-in person's own security: their second factor and their password.
///
/// It is the account's, not a company's: no `business_id` matters and no administrator reaches
/// it. Cloud only (the master keeps its own accounts and has no second factor), so it calls
/// `api` itself, like the sign up. Owned by the employees section (`EmployeesSection`), not app-wide.
///
/// Every write rethrows the backend's `{message, code}` for the caller to show; the state it
/// holds is only what the backend answered.
class AccountSecurityService extends ChangeNotifier {
  AccountSecurityStatus _status = AccountSecurityStatus.idle;
  AccountSecurityStatus get status => _status;

  TwoFactorStatus _twoFactor = const TwoFactorStatus();
  TwoFactorStatus get twoFactor => _twoFactor;

  /// Whether the account is known to have a password. The backend says it only by refusing a
  /// second one (`password_already_set`), so `false` means "not known to", until then.
  bool _hasPassword = false;
  bool get hasPassword => _hasPassword;

  bool _disposed = false;

  Future<void> load() async {
    _status = AccountSecurityStatus.loading;
    _notify();

    try {
      _twoFactor = TwoFactorStatus.fromJson(await api.get(path: "/authentication/two_factor/", version: "v1"));
      _status = AccountSecurityStatus.ready;
    } catch (_) {
      _status = AccountSecurityStatus.error;
    }

    _notify();
  }

  /// Stages a new authenticator app: nothing changes until [enableApp] brings its first code.
  /// Calling it again replaces the secret.
  Future<TwoFactorEnrollment> stageApp() async {
    final enrollment = TwoFactorEnrollment.fromJson(
      await api.post(path: "/authentication/two_factor/app/", version: "v1", data: const {})
    );

    if (enrollment == null) throw {"message": null};
    return enrollment;
  }

  /// The staged app's first [code]; [proof] of the factor in force when there is one. Answers
  /// the ten recovery codes, shown once.
  Future<List<String>> enableApp(String code, {TwoFactorProof? proof}) async {
    final codes = recoveryCodesFrom(await api.put(
      path: "/authentication/two_factor/app/",
      version: "v1",
      data: {"CODE": code, ...?proof?.body(codeKey: "CURRENT_CODE")}
    ));

    await load();
    return codes;
  }

  /// Mails the code that turns the email factor on.
  Future<void> stageEmail() =>
    api.post(path: "/authentication/two_factor/email/", version: "v1", data: const {});

  /// The mailed [code]; switching from the app proves it with [proof]. The app and its recovery
  /// codes go.
  Future<void> enableEmail(String code, {TwoFactorProof? proof}) async {
    await api.put(
      path: "/authentication/two_factor/email/",
      version: "v1",
      data: {"CODE": code, ...?proof?.body(codeKey: "CURRENT_CODE")}
    );

    await load();
  }

  /// Mails a code of the email factor: what proves it before a change, or what a sign in owes
  /// when the first one expired. Refused (409 `two_factor_no_code`) when the factor is the app.
  static Future<void> sendCode() =>
    api.post(path: "/authentication/two_factor/code/", version: "v1", data: const {});

  Future<void> disable(TwoFactorProof proof) async {
    await api.delete(path: "/authentication/two_factor/", version: "v1", data: proof.body());
    await load();
  }

  /// A new set of recovery codes; the old set stops working.
  Future<List<String>> regenerate(TwoFactorProof proof) async {
    final codes = recoveryCodesFrom(
      await api.post(path: "/authentication/two_factor/recovery/", version: "v1", data: proof.body())
    );

    await load();
    return codes;
  }

  /// Passes the second factor this session owes (the sign in's `security.two_factor` task).
  static Future<void> verify(TwoFactorProof proof) =>
    api.post(path: "/authentication/two_factor/verify/", version: "v1", data: proof.body());

  /// The account's first password; from then on it signs in with it instead of a mailed code.
  /// A refusal because one exists already is remembered ([hasPassword]) and rethrown.
  Future<void> createPassword(String password) async {
    try {
      await api.post(path: "/authentication/email/sign_up/password/", version: "v1", data: {"PASSWORD": password});
    } catch (error) {
      if (error is Map && error["code"] == 409) {
        _hasPassword = true;
        _notify();
      }
      rethrow;
    }

    _hasPassword = true;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
