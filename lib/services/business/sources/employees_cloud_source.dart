// SERVICES
import 'package:app/services/business/business_employee_detail_model.dart';
import 'package:app/services/business/business_employee_model.dart';
import 'package:app/services/business/employee_activation_model.dart';
import 'package:app/services/business/sources/employees_source.dart';
import 'package:app/toolkit/api.dart';
import 'package:app/toolkit/deployment.dart';

/// [EmployeesSource] over the backend's REST api.
class EmployeesCloudSource implements EmployeesSource {
  const EmployeesCloudSource();

  @override
  Future<(List<BusinessEmployeeModel>, int)> current() async {
    final data = await api.get(path: "/business/employees/", version: "v1");
    if (data is! Map) throw const UnreadableAnswer("business/employees");

    return (
      BusinessEmployeeModel.listFrom(data["employees"]),
      int.tryParse("${data["total"]}") ?? 0
    );
  }

  @override
  Future<List<BusinessEmployeeModel>> former() async => BusinessEmployeeModel.listFrom(
    await api.get(path: "/business/employees/former/", version: "v1"),
    former: true
  );

  @override
  Future<BusinessEmployeeDetail> detail(String id) async {
    // No trailing slash: the id is a route segment (`params: ["ID"]`).
    final data = await api.get(path: "/business/employees/detail/$id", version: "v1");

    return BusinessEmployeeDetail.from(data) ??
      (throw const UnreadableAnswer("business/employees/detail"));
  }

  @override
  Future<EmployeeInvitationSent> invite({required String email, required String jobTitle}) async {
    final data = await api.post(
      path: "/business/employees/invite/",
      version: "v1",
      data: {"EMAIL": email, "JOB_TITLE": jobTitle}
    );

    // The cloud e-mails the person: there is no code to hand over.
    return (id: data is Map ? employeeText(data["id"]) : null, activation: null);
  }

  @override
  Future<void> edit(String id, Map<String, dynamic> changes) => api.put(
    path: "/business/employees/",
    version: "v1",
    data: {"ID": id, ...changes}
  );

  @override
  Future<void> editOwn(Map<String, dynamic> changes) =>
    api.put(path: "/profile/", version: "v1", data: changes);
}
