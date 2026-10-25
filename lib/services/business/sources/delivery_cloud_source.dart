// PACKAGES
import 'package:latlong2/latlong.dart';

// SERVICES
import 'package:app/services/business/business_delivery_model.dart';
import 'package:app/services/business/business_delivery_request.dart';
import 'package:app/services/business/delivery_area_model.dart';
import 'package:app/services/business/delivery_area_request.dart';
import 'package:app/services/business/sources/delivery_source.dart';
import 'package:app/toolkit/backend/api.dart';
import 'package:app/toolkit/backend/deployment.dart';

/// [DeliverySource] over the backend's REST api, and the isochrone over the
/// map backend (`POST /scorpius/v1/isochrone`).
class DeliveryCloudSource implements DeliverySource {
  const DeliveryCloudSource();

  @override
  Future<BusinessDeliveryModel> delivery() async {
    final data = await api.get(path: "/business/delivery/", version: "v1");
    if (data is! Map) throw const UnreadableAnswer("business/delivery");

    return BusinessDeliveryModel.fromJson(data);
  }

  @override
  Future<DeliveryCatalog> providers() async {
    final data = await api.get(path: "/business/delivery/providers/", version: "v1");
    if (data is! Map) throw const UnreadableAnswer("business/delivery/providers");

    return DeliveryCatalog.fromJson(data);
  }

  @override
  Future<void> editDelivery(Map<String, dynamic> request) =>
    api.put(path: "/business/delivery/", version: "v1", data: request);

  @override
  Future<void> createOption(Map<String, dynamic> request) =>
    api.post(path: "/business/delivery/options/", version: "v1", data: request);

  @override
  Future<void> updateOption(Map<String, dynamic> request) =>
    api.put(path: "/business/delivery/options/", version: "v1", data: request);

  @override
  Future<void> removeOption(String id) => api.delete(
    path: "/business/delivery/options/",
    version: "v1",
    data: removeDeliveryOptionRequest(id)
  );

  @override
  Future<DeliveryAreasModel> areas() async {
    final data = await api.get(path: "/business/delivery/areas/", version: "v1");
    if (data is! Map && data is! List) throw const UnreadableAnswer("business/delivery/areas");

    return DeliveryAreasModel.fromJson(data);
  }

  @override
  Future<void> createArea(Map<String, dynamic> request) =>
    api.post(path: "/business/delivery/areas/", version: "v1", data: request);

  @override
  Future<void> updateArea(Map<String, dynamic> request) =>
    api.put(path: "/business/delivery/areas/", version: "v1", data: request);

  @override
  Future<void> removeArea(String id) => api.delete(
    path: "/business/delivery/areas/",
    version: "v1",
    data: removeDeliveryAreaRequest(id)
  );

  @override
  Future<List<LatLng>?> travelShape(LatLng from, int minutes, DeliveryTravelMode mode) async {
    final data = await scorpius.post(
      path: "/isochrone",
      version: "v1",
      data: {
        "POINT": {"LATITUDE": from.latitude, "LONGITUDE": from.longitude},
        "MINUTES": [minutes],
        "MODE": mode.value
      }
    );

    return _largestRing(data);
  }

  @override
  Future<List<LatLng>?> roadShape(LatLng from, double km, DeliveryTravelMode mode) async {
    final data = await scorpius.post(
      path: "/isochrone",
      version: "v1",
      data: {
        "POINT": {"LATITUDE": from.latitude, "LONGITUDE": from.longitude},
        "KM": [km],
        "MODE": mode.value
      }
    );

    return _largestRing(data);
  }

  /// The outer ring of the largest polygon of the first area answered
  /// (`[{minutes, polygons: [[ring, ...holes], ...]}]`). An island a route
  /// reaches across a bridge is left out: an area is one outline.
  static List<LatLng>? _largestRing(dynamic data) {
    if (data is! List || data.isEmpty || data.first is! Map) return null;

    final polygons = (data.first as Map)["polygons"];

    if (polygons is! List) return null;

    List<LatLng>? best;
    var size = 0.0;

    for (final polygon in polygons) {
      if (polygon is! List || polygon.isEmpty) continue;

      final ring = readRing(polygon.first);
      final area = ringSquareKm(ring);

      if (area > size) {
        size = area;
        best = ring;
      }
    }

    return best == null ? null : simplifyRing(best, limit: maxRingPoints);
  }
}
