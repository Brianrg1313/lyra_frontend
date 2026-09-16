/// Body of `PUT /business/location/`, and the reading of the map point the
/// location form is given.
///
/// The owning business does not go in the body: it travels in the
/// `business_id` header of every request.
library;

import 'package:app/services/business/business_location_model.dart';

/// A point on the map, in degrees.
typedef LocationPoint = ({double latitude, double longitude});

/// Builds the edit body with **only what changed** against [from], the
/// location the form opened with.
///
/// Every key is optional on the other side and only what is sent is written.
/// Sending the fields that did not change would not be harmless: `ADDRESS` and
/// `COUNTRY` are columns of `companies` that other writes can reach too (the
/// profile endpoint, an agent), and resending the value this tab read a while
/// ago would undo a correction made in between.
///
/// A field left empty travels as `null`, which erases it — never `""`, which
/// the backend's rules would refuse as too short instead of reading it as
/// "clear it".
///
/// `COUNTRY` is part of this body like any other line of the address, and the
/// backend hands that one key to the company's own write: moving a company also
/// moves its clock, its payment rails and the carriers it may deliver with.
///
/// The point is a pair: `LATITUDE` and `LONGITUDE` travel together or not at
/// all, and both `null` erase it. A [point] of `null` is "no point".
///
/// An empty map means there is nothing to save.
Map<String, dynamic> updateLocationRequest({
  required BusinessLocationModel from,
  required String address,
  required String landmark,
  required String city,
  required String region,
  required String postalCode,
  required String country,
  required LocationPoint? point
}) {
  final body = <String, dynamic>{};

  void text(String key, String value, String current) {
    final next = _clean(value);
    if (next != current) body[key] = next.isEmpty ? null : next;
  }

  text("ADDRESS", address, from.address);
  text("LANDMARK", landmark, from.landmark);
  text("CITY", city, from.city);
  text("REGION", region, from.region);
  // Stored uppercased: `1060 ab` and `1060 AB` are the same code, and sending
  // it again only because of its case would be a write that changes nothing.
  text("POSTAL_CODE", postalCode.toUpperCase(), from.postalCode);
  // Stored uppercased as well, and it is a code and not a name: what travels is
  // `VE`, which is what the catalog's options carry as their value.
  text("COUNTRY", country.toUpperCase(), from.country);

  if (point == null) {
    if (from.hasPoint) {
      body["LATITUDE"] = null;
      body["LONGITUDE"] = null;
    }
  } else if (!from.hasPoint ||
      _fixed(point.latitude) != _fixed(from.latitude!) ||
      _fixed(point.longitude) != _fixed(from.longitude!)) {
    // As text with the six decimals the column keeps: a double written by
    // Dart can come out in exponent form (`1e-7`), which the backend's
    // coordinate pattern refuses.
    body["LATITUDE"] = _fixed(point.latitude);
    body["LONGITUDE"] = _fixed(point.longitude);
  }

  return body;
}

/// Reads the map point as somebody pastes it, or `null` when it is not one.
///
/// Two shapes are accepted, which are the two things a map hands out:
///
/// - The coordinates themselves, `10.496112, -66.848503` — what Google Maps
///   copies when its numbers are clicked. The separator may be a comma, a
///   semicolon or a space, and each figure may use a decimal comma
///   (`10,4961; -66,8485`).
/// - A link to the place that carries them (`.../@10.4961,-66.8485,17z` or
///   `...?query=10.4961,-66.8485`). A short link (`maps.app.goo.gl/...`)
///   carries none and is refused: resolving it needs a request this app does
///   not make.
///
/// It is refused where the backend refuses it (`Location.point`): out of range
/// (±90, ±180), or exactly `0, 0` — in the Gulf of Guinea, and what a map
/// picker that never got a fix sends.
///
/// An empty text is **not** handled here: it means "no point", and whoever
/// calls decides that before asking.
LocationPoint? parseLocationPoint(String raw) {
  final text = _decoded(raw.trim());

  final match = text.contains("://")
    ? _linked.firstMatch(text)
    : _bare.firstMatch(text);

  if (match == null) return null;

  final latitude = double.tryParse(match.group(1)!.replaceAll(",", "."));
  final longitude = double.tryParse(match.group(2)!.replaceAll(",", "."));

  if (latitude == null || longitude == null) return null;
  if (latitude.abs() > 90 || longitude.abs() > 180) return null;
  if (latitude == 0 && longitude == 0) return null;

  return (latitude: latitude, longitude: longitude);
}

/// The whole text is two coordinates and their separator.
final RegExp _bare = RegExp(
  r"^(-?\d{1,3}(?:[.,]\d+)?)\s*(?:;|,|\s)\s*(-?\d{1,3}(?:[.,]\d+)?)$"
);

/// The first pair of dotted coordinates inside a link. Links always write them
/// with a dot, so the comma there is only ever the separator.
final RegExp _linked = RegExp(r"(-?\d{1,3}\.\d+)\s*,\s*(-?\d{1,3}\.\d+)");

/// A pasted link with its escapes undone — a map writes the comma between the
/// two figures as `%2C` — or the text as it came when it is not escaped
/// (`Uri.decodeFull` throws on a lone `%`).
String _decoded(String text) {
  try {
    return Uri.decodeFull(text).replaceAll("%2C", ",");
  } on ArgumentError {
    return text;
  }
}

/// A text as the backend stores it: trimmed, with its runs of spaces made one.
String _clean(String value) => value.replaceAll(RegExp(r"\s+"), " ").trim();

String _fixed(double value) => value.toStringAsFixed(6);
