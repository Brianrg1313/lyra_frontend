import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/business/business_places_model.dart';

/// What the address search is allowed to put into the location form.
///
/// The search fills fields the company then saves, so what it cannot read it
/// must leave empty rather than guess: a suggestion nobody can pick is not a
/// line, half a point is not a place, and a place that answered nothing does
/// not get to wipe an address somebody typed.
void main() {
  group("a suggestion", () {
    test("is read from the compressed row", () {
      final suggestion = PlaceSuggestion.from({
        "id": "ChIJ123",
        "title": "Centro Comercial Sambil",
        "subtitle": "Av. Libertador, Caracas"
      });

      expect(suggestion, isNotNull);
      expect(suggestion!.id, "ChIJ123");
      expect(suggestion.title, "Centro Comercial Sambil");
      expect(suggestion.subtitle, "Av. Libertador, Caracas");
    });

    test("with no id is dropped: it cannot be picked", () {
      expect(
        PlaceSuggestion.from({"id": "", "title": "Somewhere"}),
        isNull
      );
    });

    test("with no name is dropped: it cannot be read", () {
      expect(
        PlaceSuggestion.from({"id": "ChIJ123", "title": null}),
        isNull
      );
    });

    test("keeps its place when it has nowhere to say", () {
      final suggestion = PlaceSuggestion.from({
        "id": "ChIJ123",
        "title": "Panadería La Espiga"
      });

      expect(suggestion?.subtitle, "");
    });
  });

  group("a picked place", () {
    test("comes back as the fields the form holds", () {
      final place = PlaceModel.fromJson({
        "address": "Av. Francisco de Miranda, Torre Sol",
        "city": "Caracas",
        "region": "Miranda",
        "postal_code": "1060",
        "country": "ve",
        "latitude": 10.496112,
        "longitude": -66.848503
      });

      expect(place.address, "Av. Francisco de Miranda, Torre Sol");
      expect(place.city, "Caracas");
      expect(place.region, "Miranda");
      // Stored uppercased on the other side; sending it any other way would be
      // a write that changes nothing.
      expect(place.postalCode, "1060");
      expect(place.country, "VE");
      expect(place.hasPoint, isTrue);
      expect(place.point?.latitude, 10.496112);
      expect(place.point?.longitude, -66.848503);
    });

    test("what Google did not say is empty, not missing", () {
      final place = PlaceModel.fromJson({
        "address": "Calle 12 #4-21",
        "city": "Bogotá",
        "region": null,
        "postal_code": null,
        "country": "CO",
        "latitude": 4.710989,
        "longitude": -74.072092
      });

      expect(place.region, "");
      expect(place.postalCode, "");
      expect(place.isEmpty, isFalse);
    });

    test("half a point is no point", () {
      final place = PlaceModel.fromJson({
        "address": "Av. Principal",
        "latitude": 10.496112,
        "longitude": null
      });

      expect(place.hasPoint, isFalse);
      expect(place.point, isNull);
    });

    test("a place that answered nothing says so, and is not written in", () {
      final place = PlaceModel.fromJson({
        "address": null,
        "city": null,
        "region": null,
        "postal_code": null,
        "country": "VE",
        "latitude": null,
        "longitude": null
      });

      // The country alone is not an address: it is only read, to warn that the
      // place is somewhere else than the business is registered.
      expect(place.isEmpty, isTrue);
      expect(place.country, "VE");
    });

    test("a coordinate that arrived as text is still a point", () {
      final place = PlaceModel.fromJson({
        "address": "Rua Augusta, 1200",
        "latitude": "-23.556000",
        "longitude": "-46.662000"
      });

      expect(place.hasPoint, isTrue);
      expect(place.point?.latitude, -23.556);
    });
  });
}
