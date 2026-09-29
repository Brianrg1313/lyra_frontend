import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;

// PACKAGES
import 'package:latlong2/latlong.dart';

// SERVICES
import 'package:app/services/business/delivery_area_model.dart';
import 'package:app/services/business/delivery_area_request.dart';
import 'package:app/toolkit/api.dart';

enum DeliveryAreasStatus { idle, loading, ready, error }

/// Where the active company delivers, drawn on the map
/// (`/business/delivery/areas/`), and the travel-time outline an area can be
/// started from (`POST /scorpius/v1/isochrone`).
///
/// Provided by the delivery area page (`DeliveryAreaSection`), not app-wide:
/// every endpoint answers for the business in the `business_id` header, and a
/// business switch remounts the page.
///
/// Every write rereads the whole list instead of patching it: the backend
/// orders the areas and may simplify a shape it stores.
class DeliveryAreasService extends ChangeNotifier {
  DeliveryAreasStatus _status = DeliveryAreasStatus.idle;
  DeliveryAreasModel? _areas;

  /// `true` while a write is in flight, so two cannot overlap.
  bool _writing = false;

  bool _disposed = false;

  DeliveryAreasStatus get status => _status;

  /// The areas, or `null` until they are read.
  DeliveryAreasModel? get areas => _areas;

  bool get isWriting => _writing;

  /// The backend's ceiling of areas per company.
  static const int limit = 20;

  /// Reads the areas. Without [force] they are read once per page.
  Future<void> load({bool force = false}) async {
    if (_status == DeliveryAreasStatus.loading) return;
    if (!force && _status == DeliveryAreasStatus.ready) return;

    _status = DeliveryAreasStatus.loading;
    notifyListeners();

    final areas = await _fetch();

    _areas = areas ?? _areas;
    _status = areas == null ? DeliveryAreasStatus.error : DeliveryAreasStatus.ready;

    notifyListeners();
  }

  Future<void> retry() => load(force: true);

  /// Adds an area, from `createDeliveryAreaRequest`.
  Future<bool> create(BuildContext context, Map<String, dynamic> request) =>
    _write(context, () => api.post(
      path: "/business/delivery/areas/",
      version: "v1",
      data: request
    ));

  /// Edits one, from `updateDeliveryAreaRequest` or `deliveryAreaActiveRequest`.
  Future<bool> update(BuildContext context, Map<String, dynamic> request) =>
    _write(context, () => api.put(
      path: "/business/delivery/areas/",
      version: "v1",
      data: request
    ));

  /// Removes one. Whoever calls it has already asked for confirmation.
  Future<bool> remove(BuildContext context, String id) =>
    _write(context, () => api.delete(
      path: "/business/delivery/areas/",
      version: "v1",
      data: removeDeliveryAreaRequest(id)
    ));

  /// How far one gets from [from] in [minutes] by [mode]: the largest outline
  /// the routing engine answers, simplified for editing. `null` when there is
  /// no road out of the point or the engine is down (503) — said by the
  /// caller, since the company can still draw the area by hand.
  ///
  /// It is a starting shape and nothing is stored from it here: what is saved
  /// is the polygon the company confirms.
  Future<List<LatLng>?> travelShape(
    LatLng from,
    int minutes,
    DeliveryTravelMode mode
  ) async {
    try {
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
    } catch (error) {
      if (kDebugMode) print("deliveryTravelShape failed: $error");

      return null;
    }
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

  /// The common body of every write: hold the lock, send it, report a
  /// failure in the floating flag, and reread without going through
  /// `loading` (the map stays on screen).
  Future<bool> _write(
    BuildContext context,
    Future<dynamic> Function() call
  ) async {
    if (_writing) return false;

    _writing = true;
    notifyListeners();

    try {
      await call();
    } catch (error) {
      if (kDebugMode) print("deliveryAreaWrite failed: $error");

      _writing = false;
      notifyListeners();

      if (context.mounted) {
        FloatFlag.of(context).fromError(
          error is Map && error.isNotEmpty ? error : {"message": error.toString()}
        );
      }

      return false;
    }

    final areas = await _fetch();

    _writing = false;
    _areas = areas ?? _areas;
    notifyListeners();

    return true;
  }

  Future<DeliveryAreasModel?> _fetch() async {
    try {
      final data = await api.get(path: "/business/delivery/areas/", version: "v1");

      return data is Map || data is List ? DeliveryAreasModel.fromJson(data) : null;
    } catch (error) {
      if (kDebugMode) print("loadDeliveryAreas failed: $error");

      return null;
    }
  }

  /// A read can answer after the page that asked for it is gone (a business
  /// switch remounts it), and notifying a disposed notifier throws.
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
