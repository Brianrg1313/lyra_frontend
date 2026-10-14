import 'package:flutter/widgets.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:intl/intl.dart' show DateFormat;

// SERVICES
import 'package:app/services/shipments/shipment_model.dart';
import 'package:app/services/shipments/shipments_service.dart';

/// How a shipment is written on the desk and in its panel. The names of the
/// states are the backend's (its catalog, else the row's own label): a state
/// added there shows up here without a new version of the app.

/// A state's name.
String shipmentStateName(ShipmentsService service, Shipment shipment) =>
  service.nameOf(shipment.state, fallback: shipment.label.isNotEmpty ? shipment.label : shipment.state.code);

/// A state's colour: waiting on the company warns, a failure is critical,
/// delivered is good, on its way is the primary.
Color shipmentStateColor(BuildContext context, ShipmentState state) {
  final scheme = ThemeColor.of(context);

  return switch (state) {
    ShipmentState.unassigned => scheme.chart.warning,
    ShipmentState.assigned => scheme.text.primary,
    ShipmentState.picked || ShipmentState.enRoute => scheme.primary,
    ShipmentState.delivered => scheme.chart.good,
    ShipmentState.failed => scheme.chart.critical,
    ShipmentState.returned => scheme.text.secondary
  };
}

/// What a shipment is called: its number or ticket, else "Delivery".
String shipmentTitle(BuildContext context, Shipment shipment) =>
  shipment.name.isNotEmpty ? shipment.name : S.of(context).shipments_untitled;

/// A window as one line: `Wed 14 Oct, 09:00–11:00` (the end's day too when it
/// ends another day).
String shipmentWindowLabel(BuildContext context, ShipmentWindow window) {
  final locale = Localizations.localeOf(context).toString();
  final day = DateFormat.MMMEd(locale);
  final hour = DateFormat.Hm(locale);
  final sameDay = window.from.year == window.to.year &&
    window.from.month == window.to.month &&
    window.from.day == window.to.day;

  return sameDay
    ? "${day.format(window.from)}, ${hour.format(window.from)}–${hour.format(window.to)}"
    : "${day.format(window.from)}, ${hour.format(window.from)} – ${day.format(window.to)}, ${hour.format(window.to)}";
}

/// A moment of the history: `14 Oct, 09:30`.
String shipmentMomentLabel(BuildContext context, DateTime at) =>
  DateFormat.MMMd(Localizations.localeOf(context).toString()).add_Hm().format(at);

/// Who carries it, or "Nobody yet".
String shipmentCarrierLabel(BuildContext context, ShipmentCarrier? carrier) {
  if (carrier == null) return S.of(context).shipments_carrier_none;

  final name = carrier.name.isNotEmpty ? carrier.name : (carrier.provider ?? S.of(context).shipments_carrier_rider);

  return carrier.reference.isEmpty ? name : "$name · ${carrier.reference}";
}

/// Where it goes, in one line: the address, else the place and area the
/// conversation settled, else "No address".
String shipmentDestinationLabel(BuildContext context, ShipmentDestination destination) {
  if (destination.address.isNotEmpty) return destination.address;

  final named = [destination.place, destination.area].where((part) => part.isNotEmpty).join(", ");
  if (named.isNotEmpty) return named;

  return destination.hasPoint
    ? S.of(context).shipments_destination_pin
    : S.of(context).shipments_destination_none;
}
