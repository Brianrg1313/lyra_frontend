/// What the address search answers: the places matching what is being typed,
/// and the one that was picked, already in the shape of the location form.
///
/// The search is a **proxy on the backend** (`/business/location/search/`,
/// `/business/location/place/`) and not a call to Google from here: a Places
/// key is a billing account, and a desktop app cannot hold one that is
/// restricted to anything (model: `business/places.js`).
library;

import 'package:app/services/business/business_location_request.dart';

/// One line of the list under the search box.
class PlaceSuggestion {
  const PlaceSuggestion({
    required this.id,
    required this.title,
    this.subtitle = ""
  });

  /// Google's place id — what the pick is read with. Opaque here.
  final String id;

  /// The place itself: a business's name, or the street and number.
  final String title;

  /// Where it is, which is what tells two places with the same name apart.
  /// Empty when the search answered none.
  final String subtitle;

  /// A row of the compressed table, or `null` when it carries no place: a
  /// suggestion with no id cannot be picked, and one with no name is a line
  /// nobody can read.
  static PlaceSuggestion? from(Map<String, dynamic> row) {
    final id = _text(row["id"]);
    final title = _text(row["title"]);

    if (id.isEmpty || title.isEmpty) return null;

    return PlaceSuggestion(
      id: id,
      title: title,
      subtitle: _text(row["subtitle"])
    );
  }
}

/// A picked place, taken apart into the fields the form holds.
///
/// **Everything is optional.** What Google knows about a place is not the same
/// everywhere, and a missing postal code is an empty field and not a failed
/// read. The point is a pair or nothing, like everywhere else in this app.
class PlaceModel {
  const PlaceModel({
    this.address = "",
    this.city = "",
    this.region = "",
    this.postalCode = "",
    this.country = "",
    this.latitude,
    this.longitude
  });

  /// The street line, with the city, region, postal code and country already
  /// taken out by the backend: each of those has a field of its own, and
  /// writing them twice is what makes an address read like a machine wrote it.
  final String address;

  final String city;

  /// State, province or department.
  final String region;

  final String postalCode;

  /// ISO 3166-1 alpha-2 of the place. **Read, never written**: the company's
  /// country is edited with the profile, where changing it also moves the
  /// clock, the payment rails and the delivery carriers. It is here so the
  /// form can say when the picked place is somewhere else.
  final String country;

  final double? latitude;
  final double? longitude;

  bool get hasPoint => latitude != null && longitude != null;

  /// The point as the form's request takes it, or `null` when the place came
  /// with none.
  LocationPoint? get point =>
    hasPoint ? (latitude: latitude!, longitude: longitude!) : null;

  /// Whether there is anything to fill the form with. A place that answered
  /// nothing is not written over what the company already typed.
  bool get isEmpty =>
    address.isEmpty &&
    city.isEmpty &&
    region.isEmpty &&
    postalCode.isEmpty &&
    !hasPoint;

  factory PlaceModel.fromJson(Map json) {
    final latitude = _number(json["latitude"]);
    final longitude = _number(json["longitude"]);
    final located = latitude != null && longitude != null;

    return PlaceModel(
      address: _text(json["address"]),
      city: _text(json["city"]),
      region: _text(json["region"]),
      postalCode: _text(json["postal_code"]).toUpperCase(),
      country: _text(json["country"]).toUpperCase(),
      latitude: located ? latitude : null,
      longitude: located ? longitude : null
    );
  }
}

/// Every field is optional on the other side and arrives as `null`; here it is
/// empty, so the form asks one question instead of two.
String _text(dynamic value) => value?.toString().trim() ?? "";

double? _number(dynamic value) {
  if (value is num) return value.toDouble();

  return double.tryParse(value?.toString().trim() ?? "");
}
