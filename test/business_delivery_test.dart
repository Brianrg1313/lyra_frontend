import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/business/business_delivery_model.dart';
import 'package:app/services/business/business_delivery_request.dart';

/// How the delivery answer is read and what its writes send.
///
/// Three rules carry the feature and each is easy to break by being helpful:
/// "has not said" is not "no"; an amount with a thousands separator is refused
/// instead of guessed; and on an edit the carrier travels **only when it
/// changed**, because the backend checks it against the catalog of the
/// company's country today.
void main() {
  group("reading the answer", () {
    test("the options arrive in the compressed table", () {
      final delivery = BusinessDeliveryModel.fromJson({
        "delivers": 1,
        "pickup": 0,
        "notes": "Orders before 2 pm leave the same day",
        "currency": "usd",
        "options": {
          "keys": ["id", "mode", "provider", "provider_name", "coverage", "fee", "zones"],
          "values": [
            ["a1", "own", null, null, "local", "0", [
              {"name": "Chacao", "fee": null},
              {"name": "Petare", "fee": 4}
            ]]
          ]
        }
      });

      expect(delivery.delivers, isTrue);
      expect(delivery.pickup, isFalse);
      expect(delivery.currency, "USD");
      expect(delivery.options.single.mode, DeliveryMode.own);
      expect(delivery.options.single.fee, 0);
      expect(delivery.options.single.zones.last.fee, 4);
      expect(delivery.options.single.zones.first.fee, isNull);
    });

    // A blank is what every company starts with, and an assistant that read it
    // as "no" would turn away the customers of every shop that never filled
    // this in.
    test("not having said is neither yes nor no", () {
      final delivery = BusinessDeliveryModel.fromJson({"delivers": null});

      expect(delivery.delivers, isNull);
      expect(delivery.pickup, isNull);
    });

    test("a row this app cannot place is left out", () {
      final delivery = BusinessDeliveryModel.fromJson({
        "options": {
          "keys": ["id", "mode"],
          "values": [
            ["a1", "drone"],
            ["", "own"],
            ["a2", "courier"]
          ]
        }
      });

      expect(delivery.options.single.id, "a2");
    });

    test("an option is named by the company, then by its carrier", () {
      final named = DeliveryOption.from({
        "id": "a1",
        "mode": "platform",
        "provider": "yummy",
        "provider_name": "Yummy",
        "label": "Yummy Altamira"
      })!;
      final bare = DeliveryOption.from({
        "id": "a2",
        "mode": "courier",
        "provider": "mrw",
        "provider_name": "MRW"
      })!;

      expect(named.name, "Yummy Altamira");
      expect(named.carrier, "Yummy");
      expect(bare.name, "MRW");
    });
  });

  group("the carrier catalog", () {
    final catalog = DeliveryCatalog.fromJson({
      "country": "ve",
      "modes": ["own", "courier"],
      "coverages": ["local"],
      "providers": {
        "keys": ["code", "name", "kind", "scope"],
        "values": [
          ["yummy", "Yummy", "platform", "country"],
          ["mrw", "MRW", "courier", "country"],
          ["dhl", "DHL", "courier", "global"]
        ]
      }
    });

    test("only the carriers of that kind are offered", () {
      expect(
        catalog.of(DeliveryMode.courier).map((entry) => entry.code),
        ["mrw", "dhl"]
      );
      expect(catalog.of(DeliveryMode.own), isEmpty);
    });

    test("a carrier that works everywhere says so", () {
      expect(catalog.byCode("dhl")!.global, isTrue);
      expect(catalog.byCode("mrw")!.global, isFalse);
    });

    test("what the backend did not send is not offered", () {
      expect(catalog.modes, [DeliveryMode.own, DeliveryMode.courier]);
      expect(catalog.coverages, [DeliveryCoverage.local]);
    });

    test("with no catalog every mode this app knows is offered", () {
      expect(DeliveryCatalog.fromJson({}).modes, DeliveryMode.values);
    });
  });

  group("an amount as it is typed", () {
    test("a decimal comma is an amount", () {
      expect(readDeliveryAmount("2,5").value, 2.5);
    });

    // Read as 1.5 it would quote a delivery a thousand times cheaper than the
    // company meant, so it is refused rather than guessed.
    test("a thousands separator is refused", () {
      expect(readDeliveryAmount("1,500").valid, isFalse);
      expect(readDeliveryAmount("1.234,50").valid, isFalse);
    });

    test("empty is a valid no amount", () {
      final read = readDeliveryAmount("  ");

      expect(read.valid, isTrue);
      expect(read.value, isNull);
    });

    test("more decimals than a price has are refused", () {
      expect(readDeliveryAmount("2.555").valid, isFalse);
    });
  });

  group("the create body", () {
    test("what was left empty is not sent", () {
      expect(
        createDeliveryOptionRequest(mode: DeliveryMode.own, label: "  "),
        {"MODE": "own"}
      );
    });

    // Free is a price and not the absence of one: dropped, the option would
    // read as "the price varies".
    test("a free option says zero", () {
      expect(
        createDeliveryOptionRequest(mode: DeliveryMode.own, fee: 0)["FEE"],
        0
      );
    });

    test("zones and radius only travel where they mean something", () {
      final national = createDeliveryOptionRequest(
        mode: DeliveryMode.courier,
        provider: "mrw",
        coverage: DeliveryCoverage.national,
        radius: 5,
        zones: const [DeliveryZone(name: "Chacao")]
      );

      expect(national.containsKey("RADIUS"), isFalse);
      expect(national.containsKey("ZONES"), isFalse);

      final local = createDeliveryOptionRequest(
        mode: DeliveryMode.own,
        radius: 5,
        zones: const [DeliveryZone(name: "Chacao", fee: 2)]
      );

      expect(local["RADIUS"], 5);
      expect(local["ZONES"], [{"NAME": "Chacao", "FEE": 2}]);
    });

    test("the shop's own riders name no carrier", () {
      final body = createDeliveryOptionRequest(
        mode: DeliveryMode.own,
        provider: "mrw"
      );

      expect(body.containsKey("PROVIDER"), isFalse);
    });
  });

  group("the edit body", () {
    const stored = DeliveryOption(
      id: "a1",
      mode: DeliveryMode.courier,
      provider: "mrw",
      providerName: "MRW",
      coverage: DeliveryCoverage.national,
      fee: 3
    );

    // The company may have moved since it picked that carrier: resending the
    // one it already has would have the backend refuse an edit of its price.
    test("who carries it travels only when it changed", () {
      final body = updateDeliveryOptionRequest(
        from: stored,
        mode: DeliveryMode.courier,
        provider: "mrw",
        fee: 4
      );

      expect(body.containsKey("MODE"), isFalse);
      expect(body.containsKey("PROVIDER"), isFalse);
      expect(body["FEE"], 4);
    });

    test("a changed carrier travels with its mode", () {
      final body = updateDeliveryOptionRequest(
        from: stored,
        mode: DeliveryMode.platform,
        provider: "yummy"
      );

      expect(body["MODE"], "platform");
      expect(body["PROVIDER"], "yummy");
    });

    test("a carrier named by hand clears the code", () {
      final body = updateDeliveryOptionRequest(
        from: stored,
        mode: DeliveryMode.courier,
        label: "Tealca"
      );

      expect(body["PROVIDER"], isNull);
      expect(body["LABEL"], "Tealca");
    });

    // A missing key is "leave it" on the other side, so a form that stripped
    // the empties could never erase a price.
    test("an emptied figure clears with null", () {
      final body = updateDeliveryOptionRequest(
        from: stored,
        mode: stored.mode,
        provider: stored.provider
      );

      expect(body["FEE"], isNull);
      expect(body["NOTES"], isNull);
      expect(body["ID"], "a1");
    });

    test("a local option clears its zones with an empty list", () {
      final body = updateDeliveryOptionRequest(
        from: stored,
        mode: stored.mode,
        provider: stored.provider,
        coverage: DeliveryCoverage.local
      );

      expect(body["ZONES"], isEmpty);
      expect(body["RADIUS"], isNull);
    });

    // The warehouse that hands a national courier its orders; a local option's branch is the
    // map's to decide, so it never travels there.
    test("the branch it leaves from travels off a local reach, only when it changed", () {
      final moved = updateDeliveryOptionRequest(
        from: stored, mode: stored.mode, provider: stored.provider, branch: "deposito"
      );
      final kept = updateDeliveryOptionRequest(
        from: const DeliveryOption(id: "a1", mode: DeliveryMode.courier, coverage: DeliveryCoverage.national, branch: "deposito"),
        mode: DeliveryMode.courier,
        branch: "deposito"
      );
      final cleared = updateDeliveryOptionRequest(
        from: const DeliveryOption(id: "a1", mode: DeliveryMode.courier, coverage: DeliveryCoverage.national, branch: "deposito"),
        mode: DeliveryMode.courier
      );
      final local = updateDeliveryOptionRequest(
        from: stored, mode: stored.mode, provider: stored.provider,
        coverage: DeliveryCoverage.local, branch: "deposito"
      );

      expect(moved["BRANCH"], "deposito");
      expect(kept.containsKey("BRANCH"), isFalse);
      expect(cleared["BRANCH"], "");
      expect(local.containsKey("BRANCH"), isFalse);
      expect(
        createDeliveryOptionRequest(mode: DeliveryMode.courier, coverage: DeliveryCoverage.national, branch: "deposito")["BRANCH"],
        "deposito"
      );
      expect(
        createDeliveryOptionRequest(mode: DeliveryMode.own, coverage: DeliveryCoverage.local, branch: "deposito").containsKey("BRANCH"),
        isFalse
      );
      expect(DeliveryOption.from({"id": "a1", "mode": "courier", "branch": "deposito"})!.branch, "deposito");
    });
  });

  // A parcel is paid before it ships; own riders and an app's take the accounts the company
  // checked for them, and none is paid before it goes out.
  group("paid on delivery", () {
    test("is read as the accounts listed, and never on a courier", () {
      expect(DeliveryOption.from({"id": "a1", "mode": "own"})!.onDeliveryMethods, isEmpty);
      expect(DeliveryOption.from({"id": "a1", "mode": "platform", "on_delivery_methods": ["m1", "m2"]})!.onDeliveryMethods, ["m1", "m2"]);
      expect(DeliveryOption.from({"id": "a1", "mode": "courier", "on_delivery_methods": ["m1"]})!.onDeliveryMethods, isEmpty);
    });

    test("travels when said, and never for a courier", () {
      expect(createDeliveryOptionRequest(mode: DeliveryMode.own, onDeliveryMethods: ["m1"])["ON_DELIVERY_METHODS"], ["m1"]);
      expect(createDeliveryOptionRequest(mode: DeliveryMode.own).containsKey("ON_DELIVERY_METHODS"), isFalse);
      expect(createDeliveryOptionRequest(mode: DeliveryMode.courier, onDeliveryMethods: ["m1"]).containsKey("ON_DELIVERY_METHODS"), isFalse);

      const stored = DeliveryOption(id: "a1", mode: DeliveryMode.platform);
      expect(updateDeliveryOptionRequest(from: stored, mode: DeliveryMode.platform, onDeliveryMethods: const [])["ON_DELIVERY_METHODS"], isEmpty);
    });
  });

  group("the delivery time", () {
    test("a span is read in the largest whole unit", () {
      expect(DeliveryEtaUnit.fit([1440, 4320]), DeliveryEtaUnit.days);
      expect(DeliveryEtaUnit.fit([60, 120]), DeliveryEtaUnit.hours);
    });

    test("an hour and a half is not hours", () {
      expect(DeliveryEtaUnit.fit([90]), DeliveryEtaUnit.minutes);
      expect(DeliveryEtaUnit.fit([60, 90]), DeliveryEtaUnit.minutes);
    });

    test("nothing said is minutes", () {
      expect(DeliveryEtaUnit.fit(const []), DeliveryEtaUnit.minutes);
    });
  });
}
