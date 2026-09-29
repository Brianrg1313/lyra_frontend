// SERVICES
import 'package:app/services/catalog/catalog_table.dart';

/// One place the active company works from —a store, an office, a
/// warehouse—, exactly as a row of `GET /business/branches/` returns it.
///
/// The company's country is not here: every branch shares it and it is edited
/// with the company's location, where moving it also moves the clock and the
/// payment rails.
class BusinessBranchModel {
  const BusinessBranchModel({
    required this.id,
    required this.name,
    this.main = false,
    this.storefront = true,
    this.online = true,
    this.legalName = "",
    this.taxId = "",
    this.phone = "",
    this.address = "",
    this.landmark = "",
    this.city = "",
    this.region = "",
    this.postalCode = "",
    this.latitude,
    this.longitude,
    this.maps = "",
    this.position = 0
  });

  /// Public uuid: what the `branch_id` header carries to work in it.
  final String id;

  final String name;

  /// The branch created with the company. There is exactly one, and it cannot
  /// be removed: the flag is moved to another branch instead.
  final bool main;

  /// Customers may come to it.
  final bool storefront;

  /// Orders from the company's channels may be fulfilled from it.
  final bool online;

  /// Empty when the branch invoices as the company itself.
  final String legalName;
  final String taxId;

  final String phone;
  final String address;
  final String landmark;
  final String city;
  final String region;
  final String postalCode;

  /// Degrees. Null exactly when [longitude] is.
  final double? latitude;
  final double? longitude;

  /// A link that opens the point in any phone's map, built by the backend.
  /// Empty while there is no point.
  final String maps;

  final int position;

  /// The written address in one line (`Av. Sol 12, Caracas, Miranda`), or
  /// empty when none was given.
  String get place => [address, city, region]
    .where((part) => part.isNotEmpty)
    .join(", ");

  /// The rows of the answer, compressed (`{keys, values}`) or not. A row with
  /// no id is dropped: nothing could name it back to the backend.
  static List<BusinessBranchModel> listFrom(dynamic data) =>
    [for (final row in catalogRows(data)) ?BusinessBranchModel.from(row)];

  static BusinessBranchModel? from(Map<String, dynamic> row) {
    final id = _text(row["id"]);

    if (id.isEmpty) return null;

    final latitude = _number(row["latitude"]);
    final longitude = _number(row["longitude"]);
    final point = latitude != null && longitude != null;

    return BusinessBranchModel(
      id: id,
      name: _text(row["name"]),
      main: _flag(row["main"]) ?? false,
      storefront: _flag(row["storefront"]) ?? true,
      online: _flag(row["online"]) ?? true,
      legalName: _text(row["legal_name"]),
      taxId: _text(row["tax_id"]),
      phone: _text(row["phone"]),
      address: _text(row["address"]),
      landmark: _text(row["landmark"]),
      city: _text(row["city"]),
      region: _text(row["region"]),
      postalCode: _text(row["postal_code"]),
      latitude: point ? latitude : null,
      longitude: point ? longitude : null,
      maps: point ? _text(row["maps"]) : "",
      position: _number(row["position"])?.round() ?? 0
    );
  }
}

String _text(dynamic value) => value?.toString().trim() ?? "";

double? _number(dynamic value) => value is num
  ? value.toDouble()
  : double.tryParse(value?.toString() ?? "");

/// MySQL flags arrive as `1`/`0`, `"1"`/`"0"` or booleans, depending on the
/// driver path.
bool? _flag(dynamic value) => switch (value?.toString().trim().toLowerCase()) {
  "1" || "true" => true,
  "0" || "false" => false,
  _ => null
};
