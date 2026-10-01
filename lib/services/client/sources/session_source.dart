// SERVICES
import 'package:app/services/permissions/permission_request_model.dart';
import 'package:app/services/sign_in/login_method.dart';

/// Session, sign in and permission requests (`docs/offline/specs/session.md`).
///
/// Every method throws the normalised error (`{message, action}`) the running
/// mode answers with, or `UnreadableAnswer` for an answer its model can't read.
abstract interface class SessionSource {
  /// Whether a session is there to resume without asking anyone to sign in.
  Future<bool> hasSession();

  /// The bootstrap answer (`/init` today): who is signed in, their companies,
  /// permissions, tasks and the platform catalogues. Handed out as it came,
  /// because each block is the `seed` payload of the service that owns it.
  Future<Map<String, dynamic>> bootstrap();

  /// Accepts an employment invitation.
  Future<void> acceptInvitation(String id);

  /// Closes the session on the server. The caller forgets the credential.
  Future<void> signOut();

  /// The first sign-in step: whether [email] has an account and how it
  /// continues. A code method has already been sent when this answers.
  Future<({bool account, LoginMethod? method})> identify(String email);

  /// The session credential, or null when none came back.
  Future<Object?> signInWithPassword(String email, String password);

  /// The session credential, or null when none came back.
  Future<Object?> signInWithCode(String email, String code);

  /// The person's own permission requests in the active company.
  Future<List<PermissionRequestModel>> permissionRequests();

  /// Asks for [permission]; answers the new request's id.
  Future<String> requestPermission(String permission, {String? reason});
}
