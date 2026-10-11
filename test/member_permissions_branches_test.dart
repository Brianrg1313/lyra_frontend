import 'package:flutter_test/flutter_test.dart';
import 'package:lyra_protocol/lyra_protocol.dart';

import 'package:app/services/business/branch_service.dart';
import 'package:app/services/business/business_branch_model.dart';
import 'package:app/services/permissions/member_permissions_service.dart';
import 'package:app/services/permissions/permission_member_model.dart';
import 'package:app/services/permissions/permission_member_request.dart';
import 'package:app/services/permissions/sources/permissions_source.dart';

/// Where a person works and a branch's own structure (`sedes-frontend.md` §4): a manager in one
/// shop, a cashier in another. A branch with none opens on the base; changing something there
/// gives it its own, sent with `BRANCH`; "every branch's" takes it away (`RESET`).
void main() {
  setUp(() => BranchService().seed("b-1", [
    BusinessBranchModel.from({"id": "centro", "name": "Centro", "main": true})!,
    BusinessBranchModel.from({"id": "chacao", "name": "Chacao"})!
  ]));
  tearDown(() => BranchService().clear());

  test("the detail reads where they work and each branch's own structure", () {
    final member = PermissionMemberModel.from({
      "username": "rosa",
      "branches": ["chacao"],
      "sections": {"sales": {"access": true}},
      "by_branch": {"chacao": {"sections": {"pos": {"access": true, "sell": true}}, "template": null, "custom": true}}
    })!;

    expect(member.branches, ["chacao"]);
    expect(member.worksIn("chacao"), isTrue);
    expect(member.worksIn("centro"), isFalse);
    expect(member.byBranch["chacao"]!.grant.can("pos.sell"), isTrue);
    expect(member.byBranch["chacao"]!.custom, isTrue);
    // An empty list is every branch, as the backend reads it.
    expect(PermissionMemberModel.from({"username": "rosa", "branches": []})!.branches, isNull);
  });

  test("a branch's own structure opens in the draft and a change there is sent for that branch", () async {
    final source = _Source(_member(byBranch: {"chacao": ["pos", "pos.sell"]}));
    final service = MemberPermissionsService(username: "rosa", source: source);
    await service.load();

    expect(service.branchable, isTrue);
    expect(service.flag("sales", "access"), isTrue);

    service.editIn("chacao");
    expect(service.inherits, isFalse);
    expect(service.flag("sales", "access"), isFalse);
    expect(service.flag("pos", "sell"), isTrue);
    expect(service.dirty, isFalse);

    service.toggle("pos", "cancel");
    await service.save();

    expect(source.calls.single.branch, "chacao");
    expect(source.calls.single.permissions, {"pos": {"cancel": true}});
    expect(source.calls.single.branches, isNull);
  });

  test("a branch with none opens on the base, and changing it gives it its own", () async {
    final source = _Source(_member());
    final service = MemberPermissionsService(username: "rosa", source: source);
    await service.load();

    service.editIn("centro");
    expect(service.inherits, isTrue);
    expect(service.flag("sales", "access"), isTrue);

    service.toggle("pos", "access");
    await service.save();

    expect(source.calls.single.branch, "centro");
    expect(source.calls.single.permissions, {"pos": {"access": true}});
  });

  test("where they work is a draft: one branch off sends the others, every one on is every branch", () async {
    final source = _Source(_member());
    final service = MemberPermissionsService(username: "rosa", source: source);
    await service.load();

    service.toggleWorks("centro");
    expect(service.works, ["chacao"]);
    expect(service.dirty, isTrue);

    service.toggleWorks("centro");
    expect(service.works, isNull);
    expect(service.dirty, isFalse);

    service.toggleWorks("centro");
    await service.save();
    expect(source.calls.single.branches?.ids, ["chacao"]);
    expect(source.calls.single.branch, isNull);
  });

  test("the last branch they work in can't be taken off", () async {
    final service = MemberPermissionsService(username: "rosa", source: _Source(_member(branches: ["chacao"])));
    await service.load();

    service.toggleWorks("chacao");
    expect(service.works, ["chacao"]);
  });

  test("taking off the open branch closes its structure", () async {
    final service = MemberPermissionsService(username: "rosa", source: _Source(_member()));
    await service.load();

    service.editIn("chacao");
    service.toggleWorks("chacao");

    expect(service.branch, isNull);
  });

  test("every branch's again is a reset of that branch", () async {
    final source = _Source(_member(byBranch: {"chacao": ["pos"]}));
    final service = MemberPermissionsService(username: "rosa", source: source);
    await service.load();

    service.editIn("chacao");
    await service.resetBranch();

    expect(source.calls.single.branch, "chacao");
    expect(source.calls.single.reset, isTrue);
  });

  test("someone with everything has no structure per branch", () async {
    final service = MemberPermissionsService(username: "rosa", source: _Source(_member(all: true)));
    await service.load();

    expect(service.branchable, isFalse);

    service.editIn("chacao");
    expect(service.branch, isNull);
  });

  test("with one branch there is nothing to place", () async {
    BranchService().seed("b-1", [BusinessBranchModel.from({"id": "centro", "name": "Centro"})!]);
    final service = MemberPermissionsService(username: "rosa", source: _Source(_member()));
    await service.load();

    expect(service.placeable, isFalse);
    expect(service.branchable, isFalse);
  });

  test("the body carries BRANCHES only when given, BRANCH and RESET together", () {
    expect(assignMemberRequest(username: "rosa").keys, ["USERNAME"]);
    expect(assignMemberRequest(username: "rosa", branches: (ids: null))["BRANCHES"], isNull);
    expect(assignMemberRequest(username: "rosa", branches: (ids: null)).containsKey("BRANCHES"), isTrue);
    expect(assignMemberRequest(username: "rosa", branches: (ids: ["a"]))["BRANCHES"], ["a"]);
    expect(assignMemberRequest(username: "rosa", branch: "a", reset: true), {"USERNAME": "rosa", "BRANCH": "a", "RESET": true});
    expect(assignMemberRequest(username: "rosa", reset: true).containsKey("RESET"), isFalse);
  });
}

PermissionMemberModel _member({
  bool all = false,
  List<String>? branches,
  Map<String, List<String>> byBranch = const {}
}) => PermissionMemberModel(
  username: "rosa",
  access: true,
  grant: Grant(all: all, sections: PermissionCatalog.fromKeys(["sales"])),
  branches: branches,
  byBranch: {
    for (final MapEntry(:key, :value) in byBranch.entries)
      key: PermissionBranchGrant(grant: Grant(sections: PermissionCatalog.fromKeys(value)))
  }
);

typedef _Call = ({
  Map<String, Map<String, bool>>? permissions,
  ({List<String>? ids})? branches,
  String? branch,
  bool reset
});

class _Source implements PermissionsSource {
  _Source(this._member);

  final PermissionMemberModel _member;
  final calls = <_Call>[];

  @override
  Future<Grant> mine() async => Grant.everything();

  @override
  Future<bool> online() async => false;

  @override
  Future<List<PermissionTemplateModel>> templates() async => const [];

  @override
  Future<PermissionMemberModel> member(String username) async => _member;

  @override
  Future<void> assign(
    String username, {
    String? template,
    Map<String, Map<String, bool>>? permissions,
    ({List<String>? ids})? branches,
    String? branch,
    bool reset = false
  }) async => calls.add((permissions: permissions, branches: branches, branch: branch, reset: reset));

  @override
  Future<void> revoke(String username) async {}
}
