import 'package:flutter_test/flutter_test.dart';
import 'package:lyra_protocol/lyra_protocol.dart' show Grant, PermissionCatalog;

import 'package:app/services/business/branch_service.dart';
import 'package:app/services/business/business_branch_model.dart';
import 'package:app/services/permissions/sources/permissions_source.dart';
import 'package:app/services/stock/prices/branch_price_model.dart';
import 'package:app/services/stock/prices/branch_prices_service.dart';
import 'package:app/services/stock/sources/stock_source.dart';

/// A product's own price at a branch (`sedes-frontend.md` §6): null is the catalog's, an offer
/// inherited is the product's, `false` with none is no offer there. Only the branch worked in
/// is written.
void main() {
  setUp(() => BranchService().seed("b-1", [
    BusinessBranchModel.from({"id": "centro", "name": "Centro", "main": true})!,
    BusinessBranchModel.from({"id": "chacao", "name": "Chacao"})!
  ], active: "chacao"));
  tearDown(() => BranchService().clear());

  test("a row says the price, the offer and whether the offer is the product's", () {
    final rows = BranchPrice.listFrom([
      {"product_id": "p1", "branch_id": "chacao", "branch": "Chacao", "price": 12.5, "discount": null, "inherits_discount": false},
      {"product_id": "p1", "branch_id": "centro", "price": null, "discount": null, "inherits_discount": true},
      {"product_id": "", "branch_id": "x"}
    ]);

    expect(rows, hasLength(2));
    expect(rows.first.price, 12.5);
    expect(rows.first.inheritsDiscount, isFalse);
    expect(rows.first.discount, isNull);
    expect(rows.last.price, isNull);
    expect(rows.last.inheritsDiscount, isTrue);
  });

  test("the body sends what was set; an offer of 0 or cleared takes it off here", () {
    expect(setBranchPriceRequest(productId: "p1", price: 10), {"PRODUCT_ID": "p1", "PRICE": 10.0});
    expect(setBranchPriceRequest(productId: "p1", tableId: "t", discount: 15), {"PRODUCT_ID": "p1", "TABLE_ID": "t", "DISCOUNT": 15.0});

    final cleared = setBranchPriceRequest(productId: "p1", clearDiscount: true);
    expect(cleared.containsKey("DISCOUNT"), isTrue);
    expect(cleared["DISCOUNT"], isNull);

    expect(removeBranchPriceRequest("p1"), {"PRODUCT_ID": "p1"});
  });

  test("the branch worked in reads its own row, and a write reads them all again", () async {
    final source = _Source([
      const BranchPrice(productId: "p1", branchId: "centro", price: 9)
    ]);
    final service = BranchPricesService(
      productId: "p1",
      source: source,
      permissions: _Permissions(Grant(sections: PermissionCatalog.fromKeys(["products", "products.price"])))
    );
    await service.load();

    expect(service.canPrice, isTrue);
    expect(service.here, isNull);
    expect(service.of("centro")!.price, 9);

    source.rows = [
      const BranchPrice(productId: "p1", branchId: "centro", price: 9),
      const BranchPrice(productId: "p1", branchId: "chacao", price: 11)
    ];
    await service.set(price: 11);

    expect(source.set.single, {"PRODUCT_ID": "p1", "PRICE": 11.0});
    expect(service.here!.price, 11);

    service.dispose();
  });

  test("without products.price the branch's price is only read", () async {
    final service = BranchPricesService(productId: "p1", source: _Source(const []), permissions: _Permissions(Grant(sections: PermissionCatalog.fromKeys(["products"]))));
    await service.load();

    expect(service.canPrice, isFalse);

    service.dispose();
  });
}

class _Source implements StockSource {
  _Source(this.rows);

  List<BranchPrice> rows;
  final set = <Map<String, dynamic>>[];

  @override
  Future<List<BranchPrice>> prices(List<String> products) async => rows;

  @override
  Future<void> setPrice(Map<String, dynamic> request) async => set.add(request);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Permissions implements PermissionsSource {
  _Permissions(this._grant);

  final Grant _grant;

  @override
  Future<Grant> mine() async => _grant;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
