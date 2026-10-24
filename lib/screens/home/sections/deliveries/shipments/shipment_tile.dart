import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/shipments/shipment_model.dart';
import 'package:app/services/shipments/shipments_service.dart';

// WIDGETS
import 'package:app/screens/modals/shared/settings/settings_block.dart';

import './shipment_format.dart';

/// One shipment of the board: its number and state, the customer and where it
/// goes, its window and who carries it. A tap opens its panel; a shipment
/// waiting on the company is marked so it is not read past.
class ShipmentTile extends StatelessWidget {
  const ShipmentTile({
    super.key,
    required this.shipment,
    required this.service,
    required this.onTap,
    this.lit = false
  });

  final Shipment shipment;
  final ShipmentsService service;
  final void Function() onTap;

  /// Its pin is the one hovered or picked on the map.
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final window = shipment.window;
    final busy = service.busy == shipment.id;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.gap),
      child: FeedbackButton(
        action: onTap,
        padding: EdgeInsets.all(AppSize.spaceXS),
        radius: AppSize.cornerInset(AppSize.gap),
        color: lit ? scheme.surfaceFeedback : scheme.surfaceOver,
        feedbackColor: scheme.line,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            if (shipment.attention) ...[
              Container(
                width: AppSize.gap,
                height: AppSize.gap,
                decoration: BoxDecoration(color: scheme.chart.warning, shape: BoxShape.circle)
              ),
              SizedBox(width: AppSize.gap)
            ],
            Expanded(child: TextSmall(shipmentTitle(context, shipment), bold: true, ellipsis: true)),
            SizedBox(width: AppSize.gap),
            if (busy)
              SizedBox(width: AppSize.text, height: AppSize.text, child: const Loading())
            else
              SettingsTag(
                label: shipmentStateName(service, shipment),
                color: shipmentStateColor(context, shipment.state)
              )
          ]),
          SizedBox(height: AppSize.gap * 0.5),
          TextSmall(
            [
              if (shipment.customer.isNotEmpty) shipment.customer,
              shipmentDestinationLabel(context, shipment.destination)
            ].join(" · "),
            ellipsis: true,
            color: scheme.text.secondary
          ),
          SizedBox(height: AppSize.gap * 0.5),
          TextSmall(
            [
              window == null ? s.shipments_window_none : shipmentWindowLabel(context, window),
              shipmentCarrierLabel(context, shipment.carrier),
              if (!shipment.charged) shipmentCollectLabel(context, shipment.collect, shipment.currency)
            ].join(" · "),
            ellipsis: true,
            color: window == null ? scheme.text.secondary : scheme.text.primary
          ),
          if (shipment.tender case final ShipmentTender tender) ...[
            SizedBox(height: AppSize.gap * 0.5),
            TextSmall(shipmentTenderLabel(context, tender), ellipsis: true, color: scheme.text.secondary)
          ]
        ])
      )
    );
  }
}
