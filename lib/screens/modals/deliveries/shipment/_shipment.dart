import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/shipments/shipments_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/section_message.dart';

import './shipment_facts.dart';
import './shipment_form.dart';
import './shipment_moves.dart';
import './shipment_rider.dart';
import './shipment_ticket.dart';

/// Opens one shipment of the board over the deliveries desk.
///
/// [service] is the desk's: the panel follows its row, so a move made here, on
/// another screen or by the bot (a window the customer chose) shows at once.
Future<void> showShipment(BuildContext context, {required ShipmentsService service, required String id}) async {
  final width = math.min(_width, MediaQuery.of(context).size.width * .5);

  await showSideModal(
    context: context,
    title: S.of(context).shipment_title,
    minWidth: width,
    maxWidth: width,
    builder: (context) => ShipmentModal(service: service, id: id)
  );
}

const double _width = 460;

/// **One delivery, and what the branch does with it**, in the order a
/// dispatcher asks: whose order it is and what goes in the bag (the ticket
/// stub), whether it still needs confirming, who takes it, where it may go
/// next, its window and cost, where it goes, the money and what happened to
/// it. Without `shipments.dispatch` it is read only.
class ShipmentModal extends StatelessWidget {
  const ShipmentModal({super.key, required this.service, required this.id});

  final ShipmentsService service;
  final String id;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: service,
    builder: (context, _) {
      final shipment = service.byId(id);

      if (shipment == null) {
        return SectionMessage(
          icon: CI.delivery,
          title: S.of(context).shipment_gone,
          subtitle: S.of(context).shipment_gone_subtitle
        );
      }

      return ScrollableWidget(
        padding: EdgeInsets.only(bottom: AppSize.padding),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShipmentTicket(key: ValueKey("ticket-${shipment.id}"), shipment: shipment, service: service),
          if (shipment.confirming) ShipmentConfirm(shipment: shipment, service: service),
          if (service.canDispatch) ...[
            ShipmentRider(shipment: shipment, service: service),
            if (service.nextOf(shipment).isNotEmpty) ShipmentMoves(shipment: shipment, service: service),
            ShipmentForm(key: ValueKey(shipment.id), shipment: shipment, service: service)
          ] else
            ShipmentCarrying(shipment: shipment),
          ShipmentDestinationBlock(shipment: shipment),
          ShipmentMoney(shipment: shipment),
          ShipmentHistory(shipment: shipment, service: service)
        ]
      );
    }
  );
}
