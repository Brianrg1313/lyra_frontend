import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/shipments/shipment_model.dart';
import 'package:app/services/shipments/shipment_request.dart';
import 'package:app/services/shipments/shipments_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/home/sections/deliveries/shipments/shipment_format.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// **Where the shipment may go from here**: one button per state of its
/// `next`, named as the backend names them, in their state's colour. Only the
/// valid moves are offered, so a refusal is the backend changing its mind
/// (another screen moved it first), shown as it says it.
///
/// Assigning somebody is not a move here: picking a carrier in the form below
/// makes an unassigned shipment assigned on its own.
class ShipmentMoves extends StatelessWidget {
  const ShipmentMoves({super.key, required this.shipment, required this.service});

  final Shipment shipment;
  final ShipmentsService service;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final busy = service.busy != null;
    final moves = [
      for (final state in service.nextOf(shipment))
        // Assigned needs a carrier: the form's pick is that move.
        if (state != ShipmentState.assigned || shipment.carrier != null) state
    ];

    if (moves.isEmpty) return const SizedBox.shrink();

    return SettingsBlock(
      title: s.shipment_moves,
      subtitle: s.shipment_moves_subtitle,
      child: Wrap(
        spacing: AppSize.gap,
        runSpacing: AppSize.gap,
        children: [
          for (final state in moves) FeedbackButton(
            action: busy ? null : () => _move(context, state),
            height: AppSize.button,
            padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS),
            radius: AppSize.cornerInset(AppSize.gap),
            color: scheme.surface.withAlpha(150),
            feedbackColor: scheme.surface,
            message: service.nameOf(state, fallback: state.code),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: AppSize.gap,
                height: AppSize.gap,
                decoration: BoxDecoration(color: shipmentStateColor(context, state), shape: BoxShape.circle)
              ),
              SizedBox(width: AppSize.gap),
              TextSmall(service.nameOf(state, fallback: state.code), bold: true)
            ])
          )
        ]
      )
    );
  }

  Future<void> _move(BuildContext context, ShipmentState state) async {
    try {
      await service.move(shipmentStateRequest(shipment, state));
    } catch (error) {
      FloatFlag.showFromError(error);
    }
  }
}

/// **An order paid at the door that nobody confirmed yet**: it is on the board
/// for whoever prepares it, but no carrier takes it and it does not move until
/// a person confirms it through its conversation (`collecting`), which makes it
/// unassigned. Without `shipments.dispatch`, or with no conversation to confirm
/// it in, it only says so.
class ShipmentConfirm extends StatelessWidget {
  const ShipmentConfirm({super.key, required this.shipment, required this.service});

  final Shipment shipment;
  final ShipmentsService service;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final busy = service.busy != null;

    return SettingsBlock(
      title: s.shipment_confirming,
      subtitle: s.shipment_confirming_subtitle,
      child: service.canDispatch && shipment.chat != null
        ? Button(
            title: s.shipment_confirm,
            action: () {
              if (!busy) _confirm(context);
            }
          )
        : const SizedBox.shrink()
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final s = S.of(context);
    final flag = FloatFlag.of(context);

    try {
      await service.confirm(shipment);
      flag.message(s.shipment_confirmed);
    } catch (error) {
      FloatFlag.showFromError(error);
    }
  }
}
