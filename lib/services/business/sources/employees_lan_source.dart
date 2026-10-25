// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart';

// SERVICES
import 'package:app/services/business/business_employee_detail_model.dart';
import 'package:app/services/business/business_employee_model.dart';
import 'package:app/services/business/employee_activation_model.dart';
import 'package:app/services/business/sources/business_lan_source.dart';
import 'package:app/services/business/sources/employees_source.dart';
import 'package:app/services/lan/lan_service.dart';
import 'package:app/toolkit/backend/deployment.dart';

/// [EmployeesSource] over the master (`docs/offline/specs/employees.md`).
///
/// The master answers in the spec's names (`lastName`, `contractStatus`); this lays them out as
/// the cloud's rows so the models and screens stay as they are (plan principle 8). Edits travel
/// with the cloud's keys (`JOB_TITLE`, `SALARY`), which `employees.edit` reads as they are. What a
/// session may not read never arrives (E-3): the detail's private keys are simply absent.
class EmployeesLanSource implements EmployeesSource {
  const EmployeesLanSource(this._lan);

  final LanService _lan;

  @override
  Future<(List<BusinessEmployeeModel>, int)> current() async {
    final answer = await _lan.call(Ops.employeesList);
    if (answer is! Map || answer["employees"] is! List) throw const UnreadableAnswer("employees.list");

    return (
      BusinessEmployeeModel.listFrom([for (final card in answer["employees"] as List) cardJson(card)]),
      answer["total"] is int ? answer["total"] as int : 0
    );
  }

  @override
  Future<List<BusinessEmployeeModel>> former() async {
    final answer = await _lan.call(Ops.employeesFormer);
    if (answer is! List) throw const UnreadableAnswer("employees.former");

    return BusinessEmployeeModel.listFrom([for (final card in answer) cardJson(card)], former: true);
  }

  @override
  Future<BusinessEmployeeDetail> detail(String id) async {
    final answer = await _lan.call(Ops.employeesDetail, args: {"id": id});

    return BusinessEmployeeDetail.from(answer is Map ? detailJson(answer) : null) ??
      (throw const UnreadableAnswer("employees.detail"));
  }

  /// The template is checked as `permissions.members.assign` checks it and waits with the invitation
  /// until the person activates or accepts (E-10, P-5).
  @override
  Future<EmployeeInvitationSent> invite({required String email, required String jobTitle, String? template}) async {
    final answer = await _lan.call(Ops.employeesInvite, args: {"email": email, "jobTitle": jobTitle, "template": ?template});
    if (answer is! Map) throw const UnreadableAnswer("employees.invite");

    return (id: answer["id"] is String ? answer["id"] as String : null, activation: EmployeeActivation.from(answer["activation"]));
  }

  @override
  Future<void> edit(String id, Map<String, dynamic> changes) =>
    _lan.call(Ops.employeesEdit, args: {...changes, "id": id});

  @override
  Future<void> editOwn(Map<String, dynamic> changes) => _lan.call(Ops.profileEdit, args: changes);

  /// A card of `employees.list` / `.former` in the keys [BusinessEmployeeModel.from] reads.
  static Map<String, dynamic> cardJson(Object? card) {
    if (card is! Map) return const {};

    return {
      "id": card["id"],
      "me": card["me"],
      "username": card["username"],
      "name": card["name"],
      "last_name": card["lastName"],
      "email": card["email"],
      "picture": BusinessLanSource.fileJson(card["picture"]),
      "job_title": card["jobTitle"],
      "department": card["department"],
      "branch_id": card["branchId"],
      "contract": card["contract"],
      "state": card["state"],
      "work_status": card["workStatus"],
      "start_date": card["startDate"],
      "ended_date": card["endedDate"],
    };
  }

  /// `employees.detail` in the keys [BusinessEmployeeDetail.from] reads.
  static Map<String, dynamic> detailJson(Map answer) {
    final person = answer["person"] is Map ? answer["person"] as Map : const {};
    final job = answer["job"] is Map ? answer["job"] as Map : const {};
    final manager = job["manager"];
    final tenure = answer["tenure"] is Map ? answer["tenure"] as Map : const {};
    final ended = answer["ended"];

    return {
      "id": answer["id"],
      "state": answer["state"],
      "contract_status": answer["contractStatus"],
      "work_status": answer["workStatus"],
      "visibility": answer["fullProfile"] == true ? "full" : "card",
      "sealed_locked": answer["sealedLocked"] == true,
      "profile_editable": answer["profileEditable"],
      "person": {
        "username": person["username"],
        "name": person["name"],
        "last_name": person["lastName"],
        "picture": BusinessLanSource.fileJson(person["picture"]),
        "headline": person["headline"],
        "email": person["email"],
        "phone": person["phone"],
        "sex": person["sex"],
        "birthday": person["birthday"],
        "about": person["about"],
        "document_type": person["documentType"],
        "document_number": person["documentNumber"],
        "nationality": person["nationality"],
        "address": person["address"],
        "city": person["city"],
        "region": person["region"],
        "country": person["country"],
        "postal_code": person["postalCode"],
        "emergency_contact": {
          "name": person["emergencyName"],
          "phone": person["emergencyPhone"],
          "relation": person["emergencyRelation"],
        },
      },
      "job": {
        "job_title": job["title"],
        "department": job["department"],
        "code": job["code"],
        "branch": {"id": job["branchId"], "name": job["branchName"]},
        "manager": manager is Map
          ? {
              "id": manager["id"],
              "username": manager["username"],
              "name": manager["name"],
              "last_name": manager["lastName"],
              "job_title": manager["jobTitle"],
            }
          : null,
        "contract": job["contract"],
        "workday": job["workday"],
        "start_date": job["startDate"],
        "end_date": job["endDate"],
        "salary": job["salary"],
        "salary_currency": job["salaryCurrency"],
        "pay_period": job["payPeriod"],
        "work_email": job["workEmail"],
        "work_phone": job["workPhone"],
        "notes": job["notes"],
      },
      "tenure": {
        "years": tenure["years"],
        "months": tenure["months"],
        "days": tenure["days"],
        "total_days": tenure["totalDays"],
      },
      "company_tenure": {"since": answer["companySince"], "total_days": answer["companyDays"]},
      "leave": null,
      "upcoming_leaves": const <Object?>[],
      "ended": ended is Map ? {"date": ended["date"], "reason": ended["reason"], "note": ended["note"]} : null,
      "invited_date": answer["invited"],
      "responded": answer["responded"],
    };
  }
}
