import 'package:flutter_test/flutter_test.dart';

// PACKAGES
import 'package:latlong2/latlong.dart';

// SERVICES
import 'package:app/services/business/business_branch_model.dart';
import 'package:app/services/business/business_branch_request.dart';

const _branch = BusinessBranchModel(
  id: "b1",
  name: "Downtown",
  phone: "+584121234567",
  address: "Av. Sol 12",
  latitude: 10.5,
  longitude: -66.9
);

BranchDraft _draft({
  String name = "Downtown",
  bool main = false,
  bool storefront = true,
  bool online = true,
  String phone = "+584121234567",
  String address = "Av. Sol 12",
  LatLng? point = const LatLng(10.5, -66.9)
}) => BranchDraft(
  name: name,
  main: main,
  storefront: storefront,
  online: online,
  phone: phone,
  address: address,
  point: point
);

void main() {
  group("create", () {
    test("empty texts are not sent, the flags always are", () {
      final body = createBranchRequest(const BranchDraft(name: " Warehouse  East "));

      expect(body, {"NAME": "Warehouse East", "STOREFRONT": true, "ONLINE": true});
    });

    test("the point travels as a pair with six decimals", () {
      final body = createBranchRequest(_draft());

      expect(body["LATITUDE"], "10.500000");
      expect(body["LONGITUDE"], "-66.900000");
    });
  });

  group("edit", () {
    test("nothing changed is the id alone", () {
      expect(editBranchRequest(from: _branch, draft: _draft()), {"ID": "b1"});
    });

    test("only what changed travels, an emptied text as empty", () {
      final body = editBranchRequest(
        from: _branch,
        draft: _draft(storefront: false, address: "")
      );

      expect(body, {"ID": "b1", "ADDRESS": "", "STOREFRONT": false});
    });

    test("removing the point sends both halves empty", () {
      final body = editBranchRequest(from: _branch, draft: _draft(point: null));

      expect(body["LATITUDE"], "");
      expect(body["LONGITUDE"], "");
    });

    test("main only travels as true", () {
      expect(editBranchRequest(from: _branch, draft: _draft(main: true))["MAIN"], true);
    });
  });
}
