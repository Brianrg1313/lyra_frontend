import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';

import 'package:app/toolkit/api.dart';
import 'package:app/services/client/client_service.dart';
import 'package:app/services/client/sources/session_source.dart';

/// A network failure says nothing of the session (`docs/plan-offline-lan.md` §9.6): opening the
/// app without the backend lands on the sign in page with the session kept, which enters with it
/// once the backend answers, instead of asking to sign in again.
void main() {
  setUpAll(() => AppController.devMode = true);
  tearDown(() => api.token = null);

  test('no answer from the backend keeps the stored session', () async {
    api.token = "kept";

    final page = await ClientService(source: _Unreachable()).resolve();

    expect(page, "/login");
    expect(api.token, "kept");
  });
}

/// A stored session and a backend that doesn't answer: the api layer's normalised connection
/// error, which carries a `message` and no `action`.
class _Unreachable implements SessionSource {
  @override
  Future<bool> hasSession() async => true;

  @override
  Future<Map<String, dynamic>> bootstrap() async =>
    throw {"error": "Connection error", "message": "Sorry, there was a connection error, please try again"};

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}
