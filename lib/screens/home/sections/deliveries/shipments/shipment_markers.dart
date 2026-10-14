import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/shipments/shipment_model.dart';
import 'package:app/services/shipments/shipments_service.dart';

import './shipment_format.dart';

/// Where the board's shipments go, one dot per destination in its state's
/// colour; the picked one shows its number. Tapping one opens its panel. A
/// shipment with no point (a counter sale nobody located) is only in the list.
class ShipmentMarkers extends StatelessWidget {
  const ShipmentMarkers({super.key, required this.onOpen, this.lit});

  final void Function(Shipment shipment) onOpen;
  final String? lit;

  static double get _width => AppSize.action * 4;
  static double get _height => AppSize.action * 1.2;

  @override
  Widget build(BuildContext context) {
    final shipments = context.select<ShipmentsService, List<Shipment>>((service) => service.shipments);

    final drawn = [
      for (final shipment in shipments) if (shipment.id != lit) shipment,
      for (final shipment in shipments) if (shipment.id == lit) shipment
    ];

    return MarkerLayer(markers: [
      for (final shipment in drawn)
        if (shipment.destination case ShipmentDestination(:final double latitude, :final double longitude))
          Marker(
            point: LatLng(latitude, longitude),
            width: _width,
            height: _height,
            alignment: Alignment.topCenter,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _ShipmentPin(
                shipment: shipment,
                lit: shipment.id == lit,
                onTap: () => onOpen(shipment)
              )
            )
          )
    ]);
  }
}

class _ShipmentPin extends StatelessWidget {
  const _ShipmentPin({required this.shipment, required this.lit, required this.onTap});

  final Shipment shipment;
  final bool lit;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final color = shipmentStateColor(context, shipment.state);
    final dot = AppSize.text * 1.1;

    return FocusableWidget(
      action: onTap,
      message: shipmentTitle(context, shipment),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (lit) Container(
          padding: EdgeInsets.symmetric(horizontal: AppSize.gap, vertical: AppSize.gap * 0.3),
          margin: EdgeInsets.only(bottom: AppSize.gap * 0.5),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border.all(color: color, width: 1.5),
            borderRadius: BorderRadius.circular(AppSize.corner)
          ),
          child: TextSmall(shipmentTitle(context, shipment), bold: true, ellipsis: true)
        ),
        Container(
          width: dot,
          height: dot,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: scheme.surface, width: 2),
            boxShadow: [BoxShadow(color: scheme.background.withAlpha(140), blurRadius: AppSize.gap)]
          ),
          child: Icon(CI.delivery, size: dot * 0.55, color: scheme.surface)
        )
      ])
    );
  }
}
