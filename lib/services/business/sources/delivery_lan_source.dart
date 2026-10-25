// PACKAGES
import 'package:latlong2/latlong.dart';
import 'package:lyra_protocol/lyra_protocol.dart';

// SERVICES
import 'package:app/services/business/business_delivery_model.dart';
import 'package:app/services/business/delivery_area_model.dart';
import 'package:app/services/business/sources/delivery_cloud_source.dart';
import 'package:app/services/business/sources/delivery_source.dart';
import 'package:app/services/capabilities/capability_service.dart';
import 'package:app/services/lan/lan_service.dart';
import 'package:app/services/pos/sources/pos_lan_source.dart';
import 'package:app/toolkit/backend/deployment.dart';
import 'package:app/toolkit/settings/initial_builder.dart' show businessService;

/// [DeliverySource] over the master (`docs/offline/specs/deliveries.md`): only on a device in
/// `hybrid`, where the settings and the areas are the master's and sync with the cloud.
///
/// The master answers money in minor units of the company's currency, distances in metres and an
/// outline as `[latitude, longitude]` pairs; this source lays that out as the cloud's rows
/// (kilometres, amounts, snake case) for the models, and turns the services' cloud bodies into
/// the master's keys and units. The travel-time outline is the routing engine's, in the cloud.
class DeliveryLanSource implements DeliverySource {
  const DeliveryLanSource(this._lan);

  final LanService _lan;

  @override
  Future<BusinessDeliveryModel> delivery() async {
    final answer = await _lan.call(Ops.deliveryGet);
    if (answer is! Map) throw const UnreadableAnswer("delivery.get");

    return BusinessDeliveryModel.fromJson(settingsJson(answer));
  }

  @override
  Future<DeliveryCatalog> providers() async {
    final answer = await _lan.call(Ops.deliveryProviders);
    if (answer is! Map) throw const UnreadableAnswer("delivery.providers");

    return DeliveryCatalog.fromJson(answer);
  }

  @override
  Future<void> editDelivery(Map<String, dynamic> request) =>
    _lan.call(Ops.deliverySet, args: args(request, settingKeys));

  @override
  Future<void> createOption(Map<String, dynamic> request) =>
    _lan.call(Ops.deliveryOptionsCreate, args: args(request, optionKeys));

  @override
  Future<void> updateOption(Map<String, dynamic> request) =>
    _lan.call(Ops.deliveryOptionsEdit, args: args(request, optionKeys));

  @override
  Future<void> removeOption(String id) => _lan.call(Ops.deliveryOptionsRemove, args: {"id": id});

  @override
  Future<DeliveryAreasModel> areas() async {
    final answer = await _lan.call(Ops.deliveryAreasList);
    if (answer is! Map) throw const UnreadableAnswer("delivery.areas.list");

    return DeliveryAreasModel.fromJson(areasJson(answer));
  }

  @override
  Future<void> createArea(Map<String, dynamic> request) =>
    _lan.call(Ops.deliveryAreasCreate, args: args(request, areaKeys));

  @override
  Future<void> updateArea(Map<String, dynamic> request) =>
    _lan.call(Ops.deliveryAreasEdit, args: args(request, areaKeys));

  @override
  Future<void> removeArea(String id) => _lan.call(Ops.deliveryAreasRemove, args: {"id": id});

  /// The cloud's routing engine while it answers (`CapabilityService.cloudServices`); without it the
  /// editor's other two ways of drawing are left.
  @override
  Future<List<LatLng>?> travelShape(LatLng from, int minutes, DeliveryTravelMode mode) {
    if (!CapabilityService().cloudServices) throw UnsupportedError("Travel times need the internet");

    return const DeliveryCloudSource().travelShape(from, minutes, mode);
  }

  @override
  Future<List<LatLng>?> roadShape(LatLng from, double km, DeliveryTravelMode mode) {
    if (!CapabilityService().cloudServices) throw UnsupportedError("Road distances need the internet");

    return const DeliveryCloudSource().roadShape(from, km, mode);
  }

  /// The settings' body keys, as the master names them.
  static const settingKeys = {
    "DELIVERS": "delivers", "PICKUP": "pickup", "MEETING_POINT": "meeting", "NOTES": "notes",
    "DELIVERY_SCOPE": "scope"
  };

  /// An option's body keys, as the master names them.
  static const optionKeys = {
    "ID": "id", "MODE": "mode", "PROVIDER": "provider", "LABEL": "label", "COVERAGE": "coverage",
    "RADIUS": "radius", "ZONES": "zones", "FEE": "fee", "FREE_FROM": "freeFrom", "ETA_MIN": "etaMin",
    "ETA_MAX": "etaMax", "NOTES": "notes", "POSITION": "position"
  };

  /// An area's body keys, as the master names them.
  static const areaKeys = {
    "ID": "id", "BRANCH": "branch", "NAME": "name", "KIND": "kind", "LATITUDE": "latitude", "LONGITUDE": "longitude",
    "RADIUS": "radius", "POLYGON": "polygon", "FEE": "fee", "MINIMUM": "minimum", "ACTIVE": "active",
    "POSITION": "position"
  };

  /// [request] in the master's keys and units; a key it has, `null` included, travels.
  static Map<String, Object?> args(Map<String, dynamic> request, Map<String, String> keys) {
    final digits = _digits;

    return {
      for (final MapEntry(:key, :value) in request.entries) ?keys[key]: _value(key, value, digits)
    };
  }

  static Object? _value(String key, Object? value, int digits) => switch (key) {
    "FEE" || "FREE_FROM" || "MINIMUM" => PosLanSource.minor(value, digits),
    "RADIUS" => value is num ? (value * 1000).round() : value,
    "ZONES" when value is List => [
      for (final zone in value)
        if (zone is Map) {"name": zone["NAME"], "fee": PosLanSource.minor(zone["FEE"], digits)} else zone
    ],
    "POLYGON" when value is List => [
      for (final point in value)
        if (point is Map) [point["LATITUDE"], point["LONGITUDE"]] else point
    ],
    _ => value
  };

  /// `delivery.get` as `GET /business/delivery/` answers it.
  static Map<String, Object?> settingsJson(Map answer) {
    final digits = PosLanSource.decimalsOf(answer["currency"]);

    return {
      ...answer,
      "options": [
        for (final option in answer["options"] as List? ?? const [])
          if (option is Map) {
            "id": option["id"],
            "mode": option["mode"],
            "provider": option["provider"],
            "provider_name": option["providerName"],
            "icon": option["icon"],
            "label": option["label"],
            "coverage": option["coverage"],
            "radius": _kilometres(option["radius"]),
            "zones": [
              for (final zone in option["zones"] as List? ?? const [])
                if (zone is Map) {"name": zone["name"], "fee": PosLanSource.major(zone["fee"], digits)}
            ],
            "fee": PosLanSource.major(option["fee"], digits),
            "free_from": PosLanSource.major(option["freeFrom"], digits),
            "eta_min": option["etaMin"],
            "eta_max": option["etaMax"],
            "notes": option["notes"],
            "position": option["position"]
          }
      ]
    };
  }

  /// `delivery.areas.list` as `GET /business/delivery/areas/` answers it.
  static Map<String, Object?> areasJson(Map answer) {
    final digits = PosLanSource.decimalsOf(answer["currency"]);

    return {
      "currency": answer["currency"],
      "scope": answer["scope"],
      "areas": [
        for (final area in answer["areas"] as List? ?? const [])
          if (area is Map) {
            ...area,
            "radius": _kilometres(area["radius"]),
            "fee": PosLanSource.major(area["fee"], digits),
            "minimum": PosLanSource.major(area["minimum"], digits)
          }
      ]
    };
  }

  static double? _kilometres(Object? metres) => metres is num ? metres / 1000 : null;

  /// Decimals of the company's main currency, which every delivery amount is in.
  static int get _digits => PosLanSource.decimalsOf(businessService.currencyCode);
}
