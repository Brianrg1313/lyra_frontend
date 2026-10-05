import 'package:flutter_test/flutter_test.dart';
import 'package:lyra_protocol/lyra_protocol.dart';

import 'package:app/services/business/business_employee_detail_model.dart';
import 'package:app/services/business/business_employee_model.dart';
import 'package:app/services/business/sources/employees_lan_source.dart';
import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/services/lan/lan_service.dart';
import 'package:app/toolkit/deployment.dart';

/// The employees release of plan phase 4 on the app's side: what the master answers
/// (`docs/offline/specs/employees.md`, as `lyra_node` sends it) reaches the models the cloud's
/// rows do, and the screens' writes reach the master with the cloud's keys. The engine's side is
/// `lyra_node/test/employees_test.dart`.
void main() {
  late _Master master;
  late EmployeesLanSource source;

  setUp(() {
    master = _Master();
    source = EmployeesLanSource(master);
  });

  test('the list: the viewer\'s unfiled card first, an invitation with its e-mail, the active count (E-1)', () async {
    master.answers[Ops.employeesList.name] = {
      "employees": [_card, {..._unfiled}],
      "total": 0,
    };

    final (rows, total) = await source.current();

    expect(rows.map((row) => row.key), [BusinessEmployeeModel.meKey, "e-1"]);
    expect(rows.first.me, isTrue);
    expect(rows[1].fullName, "Grace Hopper");
    expect(rows[1].email, "grace@example.com");
    expect(rows[1].jobTitle, "Barista");
    expect(rows[1].state, EmployeeState.invited);
    expect(rows[1].workStatus, isNull);
    expect(total, 0);
  });

  test('a detail with the full profile: the person, the job, the measures (E-3, E-4)', () async {
    master.answers[Ops.employeesDetail.name] = _detail;

    final detail = await source.detail("e-1");

    expect(master.calls.single.$1, "employees.detail");
    expect(master.calls.single.$2, {"id": "e-1"});
    expect(detail.fullProfile, isTrue);
    expect(detail.profileEditable, isTrue);
    expect(detail.contractStatus, EmployeeContractStatus.expiring);
    expect(detail.workStatus?.kind, EmployeeWorkKind.working);
    expect(detail.person.fullName, "Grace Hopper");
    expect(detail.person.phone, "+58 412 7654321");
    expect(detail.person.emergencyName, "Ada");
    expect(detail.job.title, "Barista");
    expect(detail.job.branchName, "Lovelace Café");
    expect(detail.job.manager?.fullName, "Bob Boss");
    expect(detail.job.salary, 1500.5);
    expect(detail.job.payPeriod, EmployeePayPeriod.month);
    expect(detail.job.notes, "Trusted");
    expect(detail.tenure.totalDays, 400);
    expect(detail.companyDays, 400);
    expect(detail.companySince, DateTime(2025, 8, 27));
  });

  test('a withheld profile is not an empty one: the keys are absent and fullProfile false', () async {
    master.answers[Ops.employeesDetail.name] = {
      ..._detail,
      "fullProfile": false,
      "person": {"username": "grace", "name": "Grace", "lastName": "Hopper", "picture": null},
      "job": {"title": "Barista"},
    };

    final detail = await source.detail("e-1");

    expect(detail.fullProfile, isFalse);
    expect(detail.sealedLocked, isFalse);
    expect(detail.person.phone, "");
    expect(detail.job.salary, isNull);
  });

  test("a profile a cloud grant's session can't open says so, for the password to open it (S-13)", () async {
    master.answers[Ops.employeesDetail.name] = {
      ..._detail,
      "fullProfile": false,
      "sealedLocked": true,
      "person": {"username": "grace", "name": "Grace", "lastName": "Hopper", "picture": null},
    };

    final detail = await source.detail("e-1");

    expect((detail.fullProfile, detail.sealedLocked), (false, true));
  });

  test('inviting answers the activation code a master made (E-10)', () async {
    master.answers[Ops.employeesInvite.name] = {
      "id": "e-9",
      "activation": {"code": "12345678", "expires": "2026-10-04T12:00:00.000Z"},
    };

    final sent = await source.invite(email: "rosa@mail.com", jobTitle: "Cashier");

    expect(master.calls.single.$1, "employees.invite");
    expect(master.calls.single.$2, {"email": "rosa@mail.com", "jobTitle": "Cashier"});
    expect(sent.id, "e-9");
    expect(sent.activation?.code, "12345678");
    expect(sent.activation?.expires, DateTime.utc(2026, 10, 4, 12).toLocal());

    master.answers[Ops.employeesInvite.name] = {"id": "e-10", "activation": null};
    expect((await source.invite(email: "x@mail.com", jobTitle: "Cook")).activation, isNull);
  });

  test('edits travel with the cloud\'s keys: the company\'s on the job, one\'s own as a profile (E-12, E-13)', () async {
    await source.edit("e-1", {"JOB_TITLE": "Head barista", "SALARY": "1600"});
    await source.editOwn({"PHONE": "+58 414 0000001"});

    expect([for (final call in master.calls) call.$1], ["employees.edit", "profile.edit"]);
    expect(master.calls[0].$2, {"JOB_TITLE": "Head barista", "SALARY": "1600", "id": "e-1"});
    expect(master.calls[1].$2, {"PHONE": "+58 414 0000001"});
  });

  test('on a master the address search is the cloud\'s, and the site is no branch to pick', () {
    Deployment.use(DeploymentMode.local, role: DeploymentRole.client);
    addTearDown(() => Deployment.use(DeploymentMode.cloud));

    expect(CapabilityService().cloudServices, isFalse);
    expect(CapabilityService().shows("business.branches"), isFalse);
  });
}

const _card = {
  "id": "e-1", "accountId": "a-1", "me": false, "username": "grace", "name": "Grace", "lastName": "Hopper",
  "email": "grace@example.com", "picture": null, "headline": null, "jobTitle": "Barista", "department": null,
  "branchId": "s-1", "contract": null, "state": "invited", "workStatus": null, "startDate": null, "endedDate": null,
};

const _unfiled = {
  "id": null, "accountId": "a-0", "me": true, "username": "ada.owner", "name": "Ada", "lastName": "Owner",
  "email": null, "picture": null, "headline": null, "jobTitle": null, "department": null, "branchId": "s-1",
  "contract": null, "state": null, "workStatus": null, "startDate": null, "endedDate": null,
};

const _detail = {
  "id": "e-1", "accountId": "a-1", "state": "active", "contractStatus": "expiring", "workStatus": "working",
  "fullProfile": true, "profileEditable": true,
  "person": {
    "username": "grace", "name": "Grace", "lastName": "Hopper", "picture": null, "headline": null,
    "email": "grace@example.com", "phone": "+58 412 7654321", "sex": "female", "birthday": "1990-12-09",
    "about": null, "documentType": null, "documentNumber": "V-99887766", "nationality": "VE", "country": "VE",
    "address": null, "city": "Caracas", "region": null, "postalCode": null, "emergencyName": "Ada",
    "emergencyPhone": null, "emergencyRelation": "Friend",
  },
  "job": {
    "title": "Barista", "department": "Floor", "code": "B-7", "branchId": "s-1", "branchName": "Lovelace Café",
    "manager": {"id": "e-0", "username": "bob", "name": "Bob", "lastName": "Boss", "jobTitle": "Manager"},
    "contract": "fixed_term", "workday": "part_time", "startDate": "2025-08-27", "endDate": "2026-10-11",
    "workEmail": null, "workPhone": null, "salary": 1500.5, "salaryCurrency": "USD", "payPeriod": "month",
    "notes": "Trusted",
  },
  "tenure": {"years": 1, "months": 1, "days": 4, "totalDays": 400},
  "companySince": "2025-08-27", "companyDays": 400, "leave": null, "upcomingLeaves": [], "ended": null,
  "invited": "2025-08-20T12:00:00.000Z", "responded": "2025-08-21T12:00:00.000Z",
};

/// The master as a LAN source sees it: [LanService.call] answering what `lyra_node` would.
class _Master extends LanService {
  final Map<String, Object?> answers = {};
  final List<(String, Map<String, Object?>)> calls = [];

  @override
  Future<Object?> call(Op op, {Map<String, Object?> args = const {}}) async {
    calls.add((op.name, args));

    return answers[op.name];
  }
}
