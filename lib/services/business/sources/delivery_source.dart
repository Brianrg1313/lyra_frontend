// PACKAGES
import 'package:latlong2/latlong.dart';

// SERVICES
import 'package:app/services/business/business_delivery_model.dart';
import 'package:app/services/business/delivery_area_model.dart';

/// How and where the company delivers (`docs/offline/specs/deliveries.md`).
///
/// Throws the normalised error (`{message, action}`), or `UnreadableAnswer` for an
/// answer its model can't read. Write bodies are the `*_request.dart` maps the
/// services already build.
abstract interface class DeliverySource {
  Future<BusinessDeliveryModel> delivery();

  /// The carriers the company may pick from.
  Future<DeliveryCatalog> providers();

  /// Writes the company's delivery settings.
  Future<void> editDelivery(Map<String, dynamic> request);

  Future<void> createOption(Map<String, dynamic> request);

  Future<void> updateOption(Map<String, dynamic> request);

  Future<void> removeOption(String id);

  Future<DeliveryAreasModel> areas();

  Future<void> createArea(Map<String, dynamic> request);

  Future<void> updateArea(Map<String, dynamic> request);

  Future<void> removeArea(String id);

  /// Cloud only (the routing engine). How far one gets from [from] in
  /// [minutes] by [mode]: the largest outline, simplified for editing, or null
  /// when there is no road out of the point.
  Future<List<LatLng>?> travelShape(LatLng from, int minutes, DeliveryTravelMode mode);
}
