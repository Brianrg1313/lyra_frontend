// SERVICES
import 'package:app/services/client/sources/session_source.dart';
import 'package:app/services/database/database_service.dart';
import 'package:app/services/permissions/permission_request.dart';
import 'package:app/services/permissions/permission_request_model.dart';
import 'package:app/services/sign_in/login_method.dart';
import 'package:app/toolkit/api.dart';
import 'package:app/toolkit/deployment.dart';

/// [SessionSource] over the backend's REST api.
class SessionCloudSource implements SessionSource {
  const SessionCloudSource();

  /// A cookie session can't be seen from here (it is `HttpOnly`): only `/init` can tell, and
  /// a missing cookie answers 401 there.
  @override
  Future<bool> hasSession() async =>
    useCookieSession || await DatabaseService().hasInSecure(api.current.tokenName);

  @override
  String get signInRoute => "/login";

  @override
  Future<Map<String, dynamic>> bootstrap() async {
    final data = await api.get(path: "/init/", version: "v1");
    if (data is! Map) throw const UnreadableAnswer("init");

    return Map<String, dynamic>.from(data);
  }

  /// `PUT /profile/employments/`, `ACTION: accept`.
  @override
  Future<void> acceptInvitation(String id) => api.put(
    path: "/profile/employments/",
    version: "v1",
    data: {"ID": id, "ACTION": "accept"}
  );

  /// The logout route reads the token from the Authorization header, so this
  /// runs while it still exists.
  @override
  Future<void> signOut() => api.post(path: "/authentication/logout/", version: "v1");

  /// `email/verify` mails a new code every time it is called for an email
  /// that continues by code, voiding the previous one.
  @override
  Future<({bool account, LoginMethod? method})> identify(String email) async {
    final answer = await api.post(
      path: "/authentication/email/verify/",
      version: "v1",
      data: {"EMAIL": email}
    );

    if (answer is! Map) throw const UnreadableAnswer("email/verify");

    return (
      account: answer["account"] == true,
      method: LoginMethod.from(answer["method"])
    );
  }

  /// Answers `{token, two_factor}`. A non-null `two_factor` means the session
  /// still has to pass `two_factor/verify`; there is no screen for it yet, so
  /// the token is used either way.
  @override
  Future<Object?> signInWithPassword(String email, String password) async {
    final answer = await api.post(
      path: "/authentication/email/sign_in/password/",
      version: "v1",
      data: {"EMAIL": email, "PASSWORD": password}
    );

    return answer is Map ? answer["token"] : null;
  }

  /// Answers `{token, two_factor}` like the password sign in. After a code
  /// `two_factor` can only be `null` or `"app"`; the app step has no page yet,
  /// so it is ignored for now.
  @override
  Future<Object?> signInWithCode(String email, String code) async {
    final answer = await api.post(
      path: "/authentication/email/sign_in/code/",
      version: "v1",
      data: {"EMAIL": email, "CODE": code}
    );

    return answer is Map ? answer["token"] : null;
  }

  @override
  Future<List<PermissionRequestModel>> permissionRequests() async =>
    PermissionRequestModel.listFromTable(
      await api.get(path: "/permissions/requests/", version: "v1")
    );

  @override
  Future<String> requestPermission(String permission, {String? reason}) async {
    final id = await api.post(
      path: "/permissions/requests/",
      version: "v1",
      data: requestPermissionRequest(permission: permission, reason: reason)
    );

    return id?.toString() ?? "";
  }
}
