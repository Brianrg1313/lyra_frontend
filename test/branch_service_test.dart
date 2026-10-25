import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/business/branch_service.dart';
import 'package:app/services/business/business_branch_model.dart';
import 'package:app/services/business/sources/business_source.dart';
import 'package:app/services/permissions/permissions_service.dart';
import 'package:app/toolkit/backend/api.dart';
import 'package:app/toolkit/settings/initial_builder.dart' show businessService;
import 'package:app/toolkit/backend/sockets.dart';

BusinessBranchModel _branch(String id, {bool main = false}) =>
  BusinessBranchModel.from({"id": id, "name": id, "main": main})!;

/// `GET /business/branches/`: only the branches the person may work in, the main one first.
class _Branches implements BusinessSource {
  _Branches(this.rows);

  List<BusinessBranchModel> rows;
  int reads = 0;

  @override
  Future<List<BusinessBranchModel>> branches() async {
    reads++;
    return rows;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final service = BranchService();

  tearDown(() {
    service.clear();
    service.source = null;
    service.applies = () => true;
    PermissionsService().clear();
  });

  test('one branch is chosen without asking, and travels on every api and the socket', () async {
    service.source = _Branches([_branch("centro", main: true)]);
    service.bind("company-1");
    await service.load();

    expect(service.activeId, "centro");
    expect(service.shouldAsk, isFalse);
    expect(api.extraHeaders["branch_id"], "centro");
    expect(aries.extraHeaders["branch_id"], "centro");
    expect(sockets.extraAuth["branch_id"], "centro");
  });

  test('several branches work in the first until the person picks, and are asked once', () async {
    service.source = _Branches([_branch("centro", main: true), _branch("chacao")]);
    service.bind("company-2");
    await service.load();

    expect(service.activeId, "centro");
    expect(service.shouldAsk, isTrue);

    service.select("chacao");

    expect(service.activeId, "chacao");
    expect(service.shouldAsk, isFalse);
    expect(api.branch, "chacao");
    expect(sockets.branch, "chacao");
  });

  test("a branch the list doesn't have can't be picked", () {
    service.seed("company-3", [_branch("centro")]);

    service.select("elsewhere");

    expect(service.activeId, "centro");
  });

  test('a refused branch reads the list again and gives way to its first, asking', () async {
    final source = _Branches([_branch("centro", main: true), _branch("chacao")]);
    service.source = source;
    service.seed("company-4", source.rows, active: "chacao");

    // The person no longer works in Chacao.
    source.rows = [_branch("centro", main: true), _branch("altamira")];
    onBranchRefused?.call();
    await pumpEventQueue();

    expect(source.reads, 1);
    expect(service.activeId, "centro");
    expect(service.shouldAsk, isTrue);
  });

  test('the screens wait for the branch only while its list is read', () async {
    service.source = _Branches([_branch("centro")]);
    service.bind("company-5");

    expect(service.settled, isFalse);

    await service.load();

    expect(service.settled, isTrue);
  });

  test("a master's devices send no branch and read none", () async {
    final source = _Branches([_branch("centro")]);
    service.source = source;
    service.applies = () => false;

    service.bind("company-6");
    await pumpEventQueue();

    expect(source.reads, 0);
    expect(service.activeId, isNull);
    expect(service.settled, isTrue);
    expect(api.extraHeaders.containsKey("branch_id"), isFalse);
  });

  test("a branch's own structure replaces the company's while it is the one worked in", () {
    businessService.seed({"keys": ["id", "name"], "values": [["b-1", "Bodega"]]});
    PermissionsService().seed(
      {"b-1": {"sales": {"view": true}}},
      branches: {"b-1": {"chacao": {"pos": {"view": true, "sell": true}}}}
    );

    service.seed("b-1", [_branch("centro"), _branch("chacao")], active: "centro");
    expect(PermissionsService().can("sales.view"), isTrue);
    expect(PermissionsService().can("pos.sell"), isFalse);

    service.select("chacao");
    expect(PermissionsService().can("sales.view"), isFalse);
    expect(PermissionsService().can("pos.sell"), isTrue);

    businessService.clear();
  });
}
