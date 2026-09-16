/// Where the active company is, exactly as `GET /business/location/` returns
/// it.
///
/// **Two facts, neither derived from the other**: the written address —what a
/// person reads and a courier writes on a label— and the point on the map
/// —what a phone opens—. Turning one into the other takes a geocoder, and
/// geocoders guess worst exactly where this platform sells ("Av. Principal con
/// calle 3, edificio Sol" is an address none of them places), so the backend
/// does not derive one from the other and neither does this app: an address
/// with no point is a complete answer, and so is a point with no address.
///
/// `address` and `country` are columns of `companies` that
/// `PUT /business/profile/` can also write, but this app states them **here and
/// nowhere else**: where a company is, is one form. Changing `country` also
/// moves the company's clock, its payment rails and the carriers it may deliver
/// with, which is why the backend hands that one key to the company's own
/// write.
class BusinessLocationModel {
  const BusinessLocationModel({
    this.address = "",
    this.landmark = "",
    this.city = "",
    this.region = "",
    this.postalCode = "",
    this.country = "",
    this.latitude,
    this.longitude,
    this.maps = ""
  });

  /// The street address, in one line.
  final String address;

  /// How to find the door once there ("across from the pharmacy, unit 3"). It
  /// is its own field because it is what actually gets a customer there and
  /// it is not part of what a label carries.
  final String landmark;

  final String city;

  /// State, province or department.
  final String region;

  /// Uppercased by the backend.
  final String postalCode;

  /// ISO 3166-1 alpha-2, uppercased.
  final String country;

  /// Degrees, six decimals. Null exactly when [longitude] is.
  final double? latitude;
  final double? longitude;

  /// A link that opens the point in any phone's map. Built by the backend on
  /// every read, never stored, and empty while there is no point.
  final String maps;

  bool get hasPoint => latitude != null && longitude != null;

  /// The point as it is written and pasted: `10.496112, -66.848503`. Empty
  /// while there is none.
  String get point => hasPoint
    ? "${_coordinate(latitude!)}, ${_coordinate(longitude!)}"
    : "";

  factory BusinessLocationModel.fromJson(Map json) {
    final latitude = _number(json["latitude"]);
    final longitude = _number(json["longitude"]);

    // The backend stores the pair or nothing. Half of one that arrived anyway
    // is not a place, and a map pin built from it opens in the ocean.
    final point = latitude != null && longitude != null;

    return BusinessLocationModel(
      address: _text(json["address"]),
      landmark: _text(json["landmark"]),
      city: _text(json["city"]),
      region: _text(json["region"]),
      postalCode: _text(json["postal_code"]),
      country: _text(json["country"]).toUpperCase(),
      latitude: point ? latitude : null,
      longitude: point ? longitude : null,
      maps: point ? _text(json["maps"]) : ""
    );
  }

  /// Every text is optional and arrives as `null` when it is not set; here it
  /// is empty, so the screen asks one question instead of two.
  static String _text(dynamic value) => value?.toString().trim() ?? "";

  /// DECIMAL columns reach the client as numbers or as strings, depending on
  /// the database driver behind the endpoint.
  static double? _number(dynamic value) {
    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString().trim() ?? "");
  }

  /// A coordinate with the six decimals it is stored with, without the zeros
  /// that pad it: `10.5`, not `10.500000`.
  static String _coordinate(double value) =>
    value.toStringAsFixed(6).replaceFirst(RegExp(r"\.?0+$"), "");
}
