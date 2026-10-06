/// The account's second factor (backend model `authentication/two_factor.js`).
enum TwoFactorMethod {
  /// An authenticator app (TOTP, six digits every 30 s), with ten single-use recovery codes.
  app("app"),

  /// A code mailed to the login email at each sign in. No recovery codes: the inbox is the way back.
  email("email");

  const TwoFactorMethod(this.value);

  final String value;

  static TwoFactorMethod? from(dynamic raw) {
    for (final method in values) {
      if (method.value == raw) return method;
    }
    return null;
  }
}

/// `GET /authentication/two_factor`: which factor is on and, for the app, how many recovery
/// codes are left unused.
class TwoFactorStatus {
  const TwoFactorStatus({this.method, this.recoveryLeft});

  /// `null` = no second factor.
  final TwoFactorMethod? method;

  /// `null` unless [method] is the app.
  final int? recoveryLeft;

  bool get enabled => method != null;

  factory TwoFactorStatus.fromJson(dynamic json) {
    if (json is! Map) return const TwoFactorStatus();

    final left = json["recovery_codes"];

    return TwoFactorStatus(
      method: TwoFactorMethod.from(json["method"]),
      recoveryLeft: left is num ? left.toInt() : int.tryParse("${left ?? ""}")
    );
  }
}

/// `POST /authentication/two_factor/app`: the secret staged for an authenticator app, for 10
/// minutes. [uri] (`otpauth://…`) is what the QR carries; [secret] is the same key, typed by hand.
class TwoFactorEnrollment {
  const TwoFactorEnrollment({required this.secret, required this.uri});

  final String secret;
  final String uri;

  /// The secret in groups of four, as authenticator apps print it: easier to copy by eye.
  String get groupedSecret => [
    for (var i = 0; i < secret.length; i += 4)
      secret.substring(i, i + 4 > secret.length ? secret.length : i + 4)
  ].join(" ");

  static TwoFactorEnrollment? fromJson(dynamic json) {
    if (json is! Map) return null;

    final secret = json["secret"]?.toString() ?? "";
    final uri = json["uri"]?.toString() ?? "";

    return secret.isEmpty || uri.isEmpty ? null : TwoFactorEnrollment(secret: secret, uri: uri);
  }
}

/// How a change proves the factor in force: its code (the app's, or the one
/// `two_factor/code` mails) or one recovery code. One of the two travels.
class TwoFactorProof {
  const TwoFactorProof.code(String this.code) : recovery = null;
  const TwoFactorProof.recovery(String this.recovery) : code = null;

  final String? code;
  final String? recovery;

  /// [codeKey] is `CODE` where the proof is the request's only code (`DELETE two_factor`,
  /// `two_factor/recovery`, `two_factor/verify`) and `CURRENT_CODE` where the request carries
  /// the new factor's own (`PUT two_factor/app|email`).
  Map<String, dynamic> body({String codeKey = "CODE"}) => {
    if (code != null) codeKey: code,
    if (recovery != null) "RECOVERY_CODE": recovery
  };
}

/// `{ recovery_codes: [...] }` of enrolling the app or making a new set: shown this once.
List<String> recoveryCodesFrom(dynamic json) {
  final codes = json is Map ? json["recovery_codes"] : null;

  return codes is List ? [for (final code in codes) code.toString()] : const [];
}
