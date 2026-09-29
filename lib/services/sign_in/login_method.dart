/// The way an account continues after `email/verify`.
///
/// The app does not choose it: the backend resolves it from the email and
/// returns it as `method`. That is why the auth page asks only for the email —
/// until the backend answers, the screen does not know whether it has to ask
/// for a password, a code or send to an OAuth.
enum LoginMethod {
  /// Verification code by email. `email/verify` already sends it when
  /// responding, so the code screen does not have to ask for it.
  code("code"),

  /// Password, completed in `email/sign_in/password`.
  password("password"),

  google("google"),
  apple("apple"),
  facebook("facebook");

  const LoginMethod(this.value);

  /// Text with which it comes from the backend.
  final String value;

  /// Whether the app can complete the method today. The three OAuths are
  /// reserved by the backend but there is nothing behind them yet: when
  /// received, the page stays where it is instead of taking to a screen that
  /// does not exist.
  bool get isAvailable => this == code || this == password;

  /// Reads the method as it comes in the response body. Returns `null` for any
  /// value this version does not know, so a new backend method is not
  /// confused with an old one.
  static LoginMethod? from(dynamic raw) {
    for (final method in values) {
      if (method.value == raw) return method;
    }
    return null;
  }
}
