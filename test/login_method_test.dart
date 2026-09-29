import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/sign_in/login_method.dart';

void main() {
  group('method parsing', () {
    test('reads the text the backend returns', () {
      expect(LoginMethod.from("code"), LoginMethod.code);
      expect(LoginMethod.from("password"), LoginMethod.password);
      expect(LoginMethod.from("google"), LoginMethod.google);
      expect(LoginMethod.from("apple"), LoginMethod.apple);
      expect(LoginMethod.from("facebook"), LoginMethod.facebook);
    });

    test('an unknown method is not mistaken for a known one', () {
      expect(LoginMethod.from(null), isNull);
      expect(LoginMethod.from(""), isNull);
      expect(LoginMethod.from("sms"), isNull);
      expect(LoginMethod.from("PASSWORD"), isNull);
      expect(LoginMethod.from(2), isNull);
    });

    test('the value read is the one each method declares', () {
      for (final method in LoginMethod.values) {
        expect(LoginMethod.from(method.value), method);
      }
    });
  });

  test('only code and password can be completed today', () {
    // The OAuths are reserved by the backend but there is nothing behind them:
    // the auth page must not lead to any screen with them.
    expect(LoginMethod.code.isAvailable, isTrue);
    expect(LoginMethod.password.isAvailable, isTrue);
    expect(LoginMethod.google.isAvailable, isFalse);
    expect(LoginMethod.apple.isAvailable, isFalse);
    expect(LoginMethod.facebook.isAvailable, isFalse);
  });
}
