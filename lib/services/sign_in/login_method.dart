/// The way an account signs in.
///
/// The app does not choose it: the backend resolves it in `sign_in/email` from
/// the email and returns it as a number. That is why the first login step asks
/// only for the email — until the backend answers, the screen does not know
/// whether it has to ask for a password, a code or send to an OAuth.
///
/// The numbers are those of the `authentication.login_method` column and have
/// to match the backend's enum.
enum LoginMethod {
  /// Verification code by email. `sign_in/email` already sends it when
  /// responding, so the code screen does not have to ask for it: only complete
  /// it in `sign_in/code`.
  code(1),

  /// Password, completed in `sign_in/password`.
  password(2),

  google(3),
  apple(4),
  facebook(5);

  const LoginMethod(this.value);

  /// Number with which it comes from the backend.
  final int value;

  /// Whether the app can complete the method today. The three OAuths are
  /// declared because the backend already returns them, but there is nothing
  /// behind them yet: when received, the login stays where it is instead of
  /// taking to a screen that does not exist.
  bool get isAvailable => this == code || this == password;

  /// Reads the method as it comes in the response body. Returns `null` for any
  /// number this version does not know, so a new backend method is not
  /// confused with an old one.
  static LoginMethod? from(dynamic raw) => switch (
    raw is num ? raw.toInt() : int.tryParse(raw?.toString() ?? "")
  ) {
    1 => code,
    2 => password,
    3 => google,
    4 => apple,
    5 => facebook,
    _ => null
  };
}
