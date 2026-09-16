import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/business/business_location_model.dart';
import 'package:app/services/business/business_location_request.dart';

/// What the location is read as, how a pasted map point is understood, and
/// what an edit actually sends.
///
/// The body is the part worth pinning: `ADDRESS` and `COUNTRY` are columns of
/// `companies` that other writes can reach too, so a form that resent every
/// field would undo a correction made in between, and an emptied field has to
/// travel as `null` —never `""`, which the backend's rules refuse as too short
/// instead of reading as "clear it".
void main() {
  const stored = BusinessLocationModel(
    address: "Av. Francisco de Miranda, Torre Sol",
    landmark: "Across from the square",
    city: "Caracas",
    region: "Miranda",
    postalCode: "1060",
    country: "VE",
    latitude: 10.496112,
    longitude: -66.848503,
    maps: "https://maps.example/10.496112,-66.848503"
  );

  /// The body of an edit that changes nothing, so each test only says what it
  /// touched.
  Map<String, dynamic> body({
    String? address,
    String? landmark,
    String? city,
    String? region,
    String? postalCode,
    String? country,
    LocationPoint? point = (latitude: 10.496112, longitude: -66.848503)
  }) => updateLocationRequest(
    from: stored,
    address: address ?? stored.address,
    landmark: landmark ?? stored.landmark,
    city: city ?? stored.city,
    region: region ?? stored.region,
    postalCode: postalCode ?? stored.postalCode,
    country: country ?? stored.country,
    point: point
  );

  group("reading it", () {
    test("coordinates that arrive as text are still a point", () {
      final location = BusinessLocationModel.fromJson({
        "latitude": "10.496112",
        "longitude": "-66.848503",
        "maps": "https://maps.example/x"
      });

      expect(location.hasPoint, isTrue);
      expect(location.point, "10.496112, -66.848503");
    });

    test("half a point is no point, and carries no map link", () {
      final location = BusinessLocationModel.fromJson({
        "latitude": 10.496112,
        "longitude": null,
        "maps": "https://maps.example/x"
      });

      expect(location.hasPoint, isFalse);
      expect(location.maps, "");
    });

    test("what is not set reads as empty and not as the word null", () {
      final location = BusinessLocationModel.fromJson({"city": null});

      expect(location.city, "");
      expect(location.point, "");
    });
  });

  group("the point as somebody pastes it", () {
    test("the pair a map copies", () {
      expect(
        parseLocationPoint("10.496112, -66.848503"),
        (latitude: 10.496112, longitude: -66.848503)
      );
    });

    test("written with a decimal comma", () {
      expect(
        parseLocationPoint("10,4961; -66,8485"),
        (latitude: 10.4961, longitude: -66.8485)
      );
    });

    test("a link to the place carries it", () {
      expect(
        parseLocationPoint("https://www.google.com/maps/@10.4961,-66.8485,17z"),
        (latitude: 10.4961, longitude: -66.8485)
      );
    });

    test("a link whose comma is escaped carries it too", () {
      expect(
        parseLocationPoint("https://maps.example/?query=10.4961%2C-66.8485"),
        (latitude: 10.4961, longitude: -66.8485)
      );
    });

    // It is in the Gulf of Guinea, and it is what a map picker that never got
    // a fix sends.
    test("0, 0 is refused", () => expect(parseLocationPoint("0, 0"), isNull));

    test("out of range is refused", () {
      expect(parseLocationPoint("91, 0"), isNull);
      expect(parseLocationPoint("10, 181"), isNull);
    });

    test("a short link carries no point", () {
      expect(parseLocationPoint("https://maps.app.goo.gl/aBcD"), isNull);
    });

    // `Uri.decodeFull` throws on a lone percent, and a refused paste must be a
    // message and not a crash.
    test("a stray percent is refused, not thrown", () {
      expect(parseLocationPoint("50% off"), isNull);
    });
  });

  group("the edit body", () {
    test("nothing changed is nothing to send", () => expect(body(), isEmpty));

    test("only the field that changed travels", () {
      expect(body(city: "Valencia"), {"CITY": "Valencia"});
    });

    test("an emptied field clears with null, never with an empty text", () {
      expect(body(landmark: "  "), {"LANDMARK": null});
    });

    test("a field is compared as the backend stores it", () {
      // Trimmed, runs of spaces made one, and the postal code uppercased.
      expect(body(address: " Av. Francisco  de Miranda, Torre Sol "), isEmpty);
      expect(body(postalCode: "1060"), isEmpty);
    });

    test("the point travels as a pair, with the decimals of its column", () {
      expect(
        body(point: (latitude: 10.5, longitude: -66.8)),
        {"LATITUDE": "10.500000", "LONGITUDE": "-66.800000"}
      );
    });

    test("removing the point sends both halves as null", () {
      expect(body(point: null), {"LATITUDE": null, "LONGITUDE": null});
    });

    test("a point that did not move does not travel", () {
      expect(body(point: (latitude: 10.496112, longitude: -66.848503)), isEmpty);
    });

    // The country is one line of the address and it is saved with it. What
    // travels is the catalog's code and not the name anybody reads.
    test("a business that moved sends its new country, uppercased", () {
      expect(body(country: "co"), {"COUNTRY": "CO"});
      expect(body(country: "VE"), isEmpty);
    });

    test("a country nobody stated clears with null", () {
      expect(body(country: ""), {"COUNTRY": null});
    });
  });
}
