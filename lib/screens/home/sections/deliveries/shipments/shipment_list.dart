import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/shipments/shipment_model.dart';
import 'package:app/services/shipments/shipments_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/deliveries/widgets/map_panel.dart';

import './shipment_format.dart';
import './shipment_tile.dart';

/// **The branch's deliveries**, in the desk's panel: the ones still going
/// (scheduled, pending, on their way; the service's view, never switched
/// here), the ones the panel's search matches, each one a tile that opens its
/// panel. The branch is named by the panel's branch field.
///
/// A shipment opens on its own when a customer's payment for a delivery is
/// approved: there is nothing to create here, so an empty board says where
/// they come from.
class ShipmentList extends StatelessWidget {
  const ShipmentList({super.key, required this.onOpen, this.lit, this.query = ""});

  final void Function(Shipment shipment) onOpen;

  /// The shipment picked on the map.
  final String? lit;

  /// The panel's search, trimmed and lower case (see [shipmentMatches]).
  final String query;

  @override
  Widget build(BuildContext context) {
    return _body(context, context.watch<ShipmentsService>());
  }

  Widget _body(BuildContext context, ShipmentsService service) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);

    Widget note(String title, String subtitle, {void Function()? retry}) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextSmall(title, bold: true, lines: 2),
        SizedBox(height: AppSize.gap * 0.5),
        TextSmall(subtitle, lines: 4, color: scheme.text.secondary),
        if (retry != null) ...[
          SizedBox(height: AppSize.gap),
          FeedbackButton(
            action: retry,
            padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS, vertical: AppSize.gap),
            radius: AppSize.corner,
            feedbackColor: scheme.surfaceFeedback,
            child: TextSmall(s.deliveries_map_retry, bold: true, color: scheme.primary)
          )
        ]
      ]
    );

    return switch (service.status) {
      ShipmentsStatus.error => note(s.shipments_error, s.shipments_error_subtitle, retry: service.retry),
      ShipmentsStatus.empty => service.view == ShipmentsView.going
        ? note(s.shipments_empty, s.shipments_empty_subtitle)
        : note(s.shipments_delivered_empty, s.shipments_delivered_empty_subtitle),
      ShipmentsStatus.ready => _list(context, service),
      _ => const Center(child: Loading())
    };
  }

  Widget _list(BuildContext context, ShipmentsService service) {
    final found = query.isEmpty
      ? service.shipments
      : [for (final shipment in service.shipments) if (shipmentMatches(context, shipment, query)) shipment];

    if (found.isEmpty) {
      return Align(
        alignment: Alignment.topLeft,
        child: TextSmall(S.of(context).deliveries_search_empty, lines: 2, color: ThemeColor.of(context).text.secondary)
      );
    }

    return ListView.builder(
        padding: EdgeInsets.only(bottom: MapPanel.inset),
        itemCount: found.length,
        itemBuilder: (context, index) {
          final shipment = found[index];

          return ShipmentTile(
            key: ValueKey(shipment.id),
            shipment: shipment,
            service: service,
            lit: shipment.id == lit,
            onTap: () => onOpen(shipment)
          );
        }
      );
  }
}
