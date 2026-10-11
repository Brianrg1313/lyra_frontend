import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/business/branch_service.dart';
import 'package:app/services/business/business_branch_model.dart';
import 'package:app/services/money/money_method_model.dart';
import 'package:app/services/money/money_method_request.dart';
import 'package:app/services/money/money_methods_service.dart';

/// An account belongs to one branch or to the whole company (`sedes-frontend.md` §8). The list
/// is every branch's; a payment worked in one branch may land only in its own and the company's.
void main() {
  tearDown(() => BranchService().clear());

  test("an account names its branch, or none for the whole company", () {
    expect(MoneyMethod.fromJson({"id": "m1", "branch": "chacao"}).branch, "chacao");
    expect(MoneyMethod.fromJson({"id": "m2", "branch": null}).branch, isNull);
    expect(MoneyMethod.fromJson({"id": "m3"}).branch, isNull);
  });

  test("a payment in a branch lands in its accounts and the company's, not another's", () {
    const company = MoneyMethod(id: "m1");
    const chacao = MoneyMethod(id: "m2", branch: "chacao");

    expect(company.servesBranch("centro"), isTrue);
    expect(chacao.servesBranch("chacao"), isTrue);
    expect(chacao.servesBranch("centro"), isFalse);
    // A master works in no branch: every account is its own.
    expect(chacao.servesBranch(null), isTrue);
  });

  test("the accounts offered are the branch worked in's and the company's", () {
    BranchService().seed("b-1", [
      BusinessBranchModel.from({"id": "centro", "name": "Centro"})!,
      BusinessBranchModel.from({"id": "chacao", "name": "Chacao"})!
    ], active: "centro");

    final service = MoneyMethodsService()..seed(const [
      MoneyMethod(id: "m1"),
      MoneyMethod(id: "m2", branch: "chacao"),
      MoneyMethod(id: "m3", branch: "centro")
    ]);

    expect([for (final method in service.usable) method.id], ["m1", "m3"]);

    service.dispose();
  });

  test("BRANCH travels on a creation only when it has one, and on an edit only when moved", () {
    expect(createMoneyMethodRequest(code: "cash", branch: "chacao")["BRANCH"], "chacao");
    expect(createMoneyMethodRequest(code: "cash").containsKey("BRANCH"), isFalse);

    expect(updateMoneyMethodRequest(id: "m1").containsKey("BRANCH"), isFalse);
    expect(updateMoneyMethodRequest(id: "m1", branch: (id: "chacao"))["BRANCH"], "chacao");

    final toCompany = updateMoneyMethodRequest(id: "m1", branch: (id: null));
    expect(toCompany.containsKey("BRANCH"), isTrue);
    expect(toCompany["BRANCH"], isNull);
  });
}
