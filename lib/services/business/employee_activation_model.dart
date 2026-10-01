// SERVICES
import 'package:app/services/business/business_employee_model.dart';

/// The code an invitation on a master hands over (`docs/offline/specs/employees.md` E-10,
/// `session.md` S-8): the invited person types it, with the password they choose, on their first
/// sign in. The master answers it once; the person who invited copies it from the invitation's
/// result.
class EmployeeActivation {
  const EmployeeActivation({required this.code, this.expires});

  final String code;

  /// The code stops working then (72 hours after it was made); the admin issues another.
  final DateTime? expires;

  static EmployeeActivation? from(dynamic json) {
    if (json is! Map) return null;

    final code = employeeText(json["code"]);

    if (code.isEmpty) return null;

    return EmployeeActivation(code: code, expires: DateTime.tryParse(employeeText(json["expires"]))?.toLocal());
  }
}

/// What an invitation answers: the new employment's id, when known, and the activation code
/// when it made the person's account (only on a master).
typedef EmployeeInvitationSent = ({String? id, EmployeeActivation? activation});
