// SERVICES
import 'package:app/services/shipments/shipment_model.dart';

/// Who should carry a shipment, as the panel picks it: a rider (a job id), a
/// carrier (a provider's code with its order or tracking number), or nobody.
class CarrierChoice {
  const CarrierChoice.rider(String this.employment) : provider = null, reference = "";

  const CarrierChoice.provider(String this.provider, {this.reference = ""}) : employment = null;

  const CarrierChoice.none() : employment = null, provider = null, reference = "";

  final String? employment;
  final String? provider;
  final String reference;

  bool get isNone => employment == null && provider == null;

  /// The choice a shipment's carrier stands for.
  static CarrierChoice of(ShipmentCarrier? carrier) {
    if (carrier?.employment case final String id) return CarrierChoice.rider(id);
    if (carrier?.provider case final String code) return CarrierChoice.provider(code, reference: carrier!.reference);

    return const CarrierChoice.none();
  }

  @override
  bool operator ==(Object other) =>
    other is CarrierChoice &&
    other.employment == employment &&
    other.provider == provider &&
    other.reference == reference;

  @override
  int get hashCode => Object.hash(employment, provider, reference);
}

/// `PUT /shipments` moving [shipment] to [state] (one of its `next`).
Map<String, dynamic> shipmentStateRequest(Shipment shipment, ShipmentState state, {String? receiver}) => {
  "ID": shipment.id,
  "STATE": state.code,
  if (receiver != null && receiver.trim().isNotEmpty && receiver.trim() != shipment.receiver) "RECEIVER": receiver.trim()
};

/// `PUT /shipments` with **only what changed** against [shipment], or null when
/// nothing did. Empty travels as `""` (the backend takes it off): no carrier,
/// no window (both ends), no cost. A point travels as a pair, always with the
/// address beside it.
///
/// Assigning a carrier to an unassigned shipment makes it `assigned`, and
/// taking it off makes it `unassigned` again: the backend moves the state, so
/// no `STATE` is sent here.
Map<String, dynamic>? editShipmentRequest(
  Shipment shipment, {
  CarrierChoice? carrier,
  ShipmentWindow? window,
  bool clearWindow = false,
  double? cost,
  bool clearCost = false,
  String? note,
  String? receiver,
  String? address,
  ({double latitude, double longitude})? point,
  bool clearPoint = false
}) {
  final body = <String, dynamic>{};

  if (carrier != null && carrier != CarrierChoice.of(shipment.carrier)) {
    if (carrier.employment case final String id) {
      body["EMPLOYMENT"] = id;
    } else if (carrier.provider case final String code) {
      body["PROVIDER"] = code;
      body["REFERENCE"] = carrier.reference.trim();
    } else {
      body["EMPLOYMENT"] = "";
    }
  }

  if (clearWindow && shipment.window != null) {
    body["FROM"] = "";
    body["TO"] = "";
  } else if (window != null && window != shipment.window) {
    body["FROM"] = window.from.toUtc().toIso8601String();
    body["TO"] = window.to.toUtc().toIso8601String();
  }

  if (clearCost && shipment.cost != null) {
    body["COST"] = "";
  } else if (cost != null && cost != shipment.cost) {
    body["COST"] = cost;
  }

  if (note != null && note.trim() != shipment.note) body["NOTE"] = note.trim();
  if (receiver != null && receiver.trim() != shipment.receiver) body["RECEIVER"] = receiver.trim();

  final destination = shipment.destination;
  final addressChanged = address != null && address.trim() != destination.address;
  final pointChanged = clearPoint
    ? destination.hasPoint
    : point != null && (point.latitude != destination.latitude || point.longitude != destination.longitude);

  if (addressChanged || pointChanged) {
    final kept = clearPoint ? null : point ?? (destination.hasPoint
      ? (latitude: destination.latitude!, longitude: destination.longitude!)
      : null);

    body["ADDRESS"] = (address ?? destination.address).trim();
    body["LATITUDE"] = kept == null ? "" : double.parse(kept.latitude.toStringAsFixed(6));
    body["LONGITUDE"] = kept == null ? "" : double.parse(kept.longitude.toStringAsFixed(6));
  }

  if (body.isEmpty) return null;

  return {"ID": shipment.id, ...body};
}

/// `PUT /shipments/settings` with only what changed against [current]. An
/// emptied capacity travels as `""` (no limit).
Map<String, dynamic> shippingSettingsRequest(ShippingSettings current, ShippingSettings edited) => {
  if (edited.span != current.span) "SPAN": edited.span,
  if (edited.capacity != current.capacity) "CAPACITY": edited.capacity ?? "",
  if (edited.lead != current.lead) "LEAD": edited.lead,
  if (edited.days != current.days) "DAYS": edited.days,
  if (edited.width != current.width) "WIDTH": edited.width
};
