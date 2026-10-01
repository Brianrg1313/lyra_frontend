// SERVICES
import 'package:app/services/business/business_employee_detail_model.dart';
import 'package:app/services/business/business_employee_model.dart';
import 'package:app/services/business/employee_activation_model.dart';

/// The company's staff (`docs/offline/specs/employees.md`).
///
/// Throws the normalised error (`{message, action}`), or `UnreadableAnswer` for an
/// answer its model can't read.
abstract interface class EmployeesSource {
  /// Active and invited people, the viewer first, and how many are active.
  Future<(List<BusinessEmployeeModel>, int)> current();

  /// People who left, declined or were cancelled.
  Future<List<BusinessEmployeeModel>> former();

  Future<BusinessEmployeeDetail> detail(String id);

  /// Invites [email] as [jobTitle]; answers the new employment's id, when known, and on a master
  /// the activation code of the account it made.
  Future<EmployeeInvitationSent> invite({required String email, required String jobTitle});

  /// Writes [changes] (backend-style keys) on employment [id].
  Future<void> edit(String id, Map<String, dynamic> changes);

  /// Writes the viewer's own personal data: who it is comes from the session.
  Future<void> editOwn(Map<String, dynamic> changes);
}
