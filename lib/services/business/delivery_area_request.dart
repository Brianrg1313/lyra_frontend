/// Bodies of the delivery area writes (`POST` / `PUT` / `DELETE
/// /business/delivery/areas/`).
///
/// The owning business does not go in any body: it travels in the
/// `business_id` header of every request. Coordinates travel in the
/// platform's own shape, `{LATITUDE, LONGITUDE}` in WGS84 degrees with six
/// decimals, the one every `/scorpius` request takes (`Geometry.point`).
library;

// PACKAGES
import 'package:latlong2/latlong.dart';

// SERVICES
import 'package:app/services/business/delivery_area_model.dart';

/// Builds the body that adds an area.
///
/// Only the shape of its [kind] travels: a circle is its middle and its
/// kilometres, a polygon its outline. What was left empty is not sent, and a
/// [branch] left out is an area on the map every branch serves.
Map<String, dynamic> createDeliveryAreaRequest({
  String? branch,
  required String name,
  required DeliveryAreaKind kind,
  LatLng? center,
  double? radius,
  List<LatLng> points = const [],
  double? fee,
  double? minimum
}) => {
  "BRANCH": ?branch,
  "NAME": name.trim(),
  ..._shape(kind, center, radius, points),
  "FEE": ?fee,
  "MINIMUM": ?minimum
};

/// Builds the body that edits [from].
///
/// Everything the editor draws travels, and an emptied figure travels as
/// `null`: the backend writes only the keys it receives, so a missing key is
/// "leave it" and `null` is "erase it" — a fee emptied is the option's price
/// again.
Map<String, dynamic> updateDeliveryAreaRequest({
  required DeliveryArea from,
  required String name,
  required DeliveryAreaKind kind,
  LatLng? center,
  double? radius,
  List<LatLng> points = const [],
  double? fee,
  double? minimum
}) => {
  "ID": from.id,
  "NAME": name.trim(),
  ..._shape(kind, center, radius, points),
  "FEE": fee,
  "MINIMUM": minimum
};

/// Says which areas are in force: one map shared by every branch, or one per
/// branch (`PUT /business/delivery/`). Switching deletes nothing.
Map<String, dynamic> deliveryScopeRequest(DeliveryScope scope) =>
  {"DELIVERY_SCOPE": scope.value};

/// Pauses or resumes an area without touching its shape.
Map<String, dynamic> deliveryAreaActiveRequest(DeliveryArea area, bool active) =>
  {"ID": area.id, "ACTIVE": active};

/// Builds the body that removes an area.
Map<String, dynamic> removeDeliveryAreaRequest(String id) => {"ID": id};

Map<String, dynamic> _shape(
  DeliveryAreaKind kind,
  LatLng? center,
  double? radius,
  List<LatLng> points
) => switch (kind) {
  DeliveryAreaKind.radius => {
    "KIND": kind.value,
    "LATITUDE": ?_round(center?.latitude),
    "LONGITUDE": ?_round(center?.longitude),
    "RADIUS": ?radius
  },
  DeliveryAreaKind.polygon => {
    "KIND": kind.value,
    "POLYGON": [
      for (final point in points) {
        "LATITUDE": _round(point.latitude),
        "LONGITUDE": _round(point.longitude)
      }
    ]
  }
};

/// Six decimals, ~11 cm: what the backend keeps a coordinate with.
double? _round(double? value) =>
  value == null ? null : (value * 1e6).round() / 1e6;
