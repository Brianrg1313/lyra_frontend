import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';

import 'package:app/toolkit/backend/api.dart';
import 'package:app/services/account/two_factor_model.dart';
import 'package:app/services/client/client_service.dart';
import 'package:app/services/client/client_task.dart';
import 'package:app/services/client/sources/session_source.dart';

/// The second factor (backend `authentication/two_factor.js`): its status reads as the security
/// panel draws it, a proof travels under the key each request names it by, and a session that
/// owes the factor stops at its page before anything of the account is seeded — `/init` holds
/// the rest back until `two_factor/verify` passes it.
void main() {
  setUpAll(() => AppController.devMode = true);
  tearDown(() => api.token = null);

  group('status', () {
    test('the app with the recovery codes it has left', () {
      final status = TwoFactorStatus.fromJson({"method": "app", "recovery_codes": 7});

      expect(status.method, TwoFactorMethod.app);
      expect(status.recoveryLeft, 7);
      expect(status.enabled, isTrue);
    });

    test('email has no recovery codes, and no method is off', () {
      expect(TwoFactorStatus.fromJson({"method": "email", "recovery_codes": null}).recoveryLeft, isNull);
      expect(TwoFactorStatus.fromJson({"method": null}).enabled, isFalse);
      expect(TwoFactorStatus.fromJson("nonsense").enabled, isFalse);
    });
  });

  group('proof', () {
    test('a code is CODE alone, or CURRENT_CODE beside a new factor\'s own', () {
      expect(const TwoFactorProof.code("123456").body(), {"CODE": "123456"});
      expect(const TwoFactorProof.code("123456").body(codeKey: "CURRENT_CODE"), {"CURRENT_CODE": "123456"});
    });

    test('a recovery code is RECOVERY_CODE whatever the request', () {
      expect(const TwoFactorProof.recovery("abcde-fghij").body(codeKey: "CURRENT_CODE"), {"RECOVERY_CODE": "abcde-fghij"});
    });
  });

  test('a staged app needs both its secret and its uri; the key is grouped by four', () {
    final enrollment = TwoFactorEnrollment.fromJson({"secret": "JBSWY3DPEHPK3PXPAB", "uri": "otpauth://totp/x"});

    expect(enrollment?.groupedSecret, "JBSW Y3DP EHPK 3PXP AB");
    expect(TwoFactorEnrollment.fromJson({"secret": "JBSWY3DP"}), isNull);
  });

  test('recovery codes are read from their answer, none from anything else', () {
    expect(recoveryCodesFrom({"recovery_codes": ["a1b2c-d3e4f", "g5h6i-j7k8l"]}), ["a1b2c-d3e4f", "g5h6i-j7k8l"]);
    expect(recoveryCodesFrom(true), isEmpty);
  });

  test('the task has a page and carries the method owed', () {
    final task = ClientTask.fromJson({"key": "security.two_factor", "data": {"method": "email"}});

    expect(task?.key.route, "/two_factor");
    expect(task?.method, "email");
  });

  test('a session that owes its factor lands on its page with nothing of the account seeded', () async {
    api.token = "owes";

    final client = ClientService(source: _Owing());
    final page = await client.resolve();

    expect(page, "/two_factor");
    expect(client.isAuthenticated, isFalse);
    expect(client.tasks.single.key, ClientTaskKey.twoFactor);
    expect(api.token, "owes");
  });
}

/// `/init` for a session that has not passed its second factor: the task and nothing else.
class _Owing implements SessionSource {
  @override
  Future<bool> hasSession() async => true;

  @override
  Future<Map<String, dynamic>> bootstrap() async => {
    "tasks": [{"key": "security.two_factor", "data": {"method": "app"}}]
  };

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}
