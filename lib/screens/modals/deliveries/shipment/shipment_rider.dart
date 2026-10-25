import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/shipments/shipment_model.dart';
import 'package:app/services/shipments/shipment_request.dart';
import 'package:app/services/shipments/shipments_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/home/sections/deliveries/shipments/shipment_format.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// **Who takes it**: the branch's people (`GET /shipments/carriers`, any active
/// job of the branch until the backend narrows them to riders) and the
/// country's platforms and couriers. A pick is written at once, alone
/// (`editShipmentRequest` with the carrier only): assigning is the step the
/// dispatcher takes, not a field among others, and the backend moves an
/// unassigned shipment to assigned by itself.
///
/// A carrier's reference stays in the form below. An order waiting to be
/// confirmed takes nobody (`shipment_unconfirmed`), so the select waits.
class ShipmentRider extends StatefulWidget {
  const ShipmentRider({super.key, required this.shipment, required this.service});

  final Shipment shipment;
  final ShipmentsService service;

  @override
  State<ShipmentRider> createState() => _ShipmentRiderState();
}

class _ShipmentRiderState extends State<ShipmentRider> {
  ShipmentCarriers? _carriers;

  @override
  void initState() {
    super.initState();
    unawaited(_read());
  }

  Future<void> _read() async {
    try {
      final carriers = await widget.service.loadCarriers();
      if (mounted) setState(() => _carriers = carriers);
    } catch (error) {
      // The picker asks again when opened, and says why if it fails there.
    }
  }

  Future<void> _pick(BuildContext anchor) async {
    final s = S.of(context);
    final shipment = widget.shipment;
    ShipmentCarriers carriers;

    try {
      carriers = await widget.service.loadCarriers();
    } catch (error) {
      FloatFlag.showFromError(error);
      return;
    }

    if (!anchor.mounted || !mounted) return;
    if (_carriers == null) setState(() => _carriers = carriers);

    final current = CarrierChoice.of(shipment.carrier);
    final picked = await showSelectMenu(
      context: anchor,
      selected: switch (current) {
        CarrierChoice(employment: final String id) => "rider:$id",
        CarrierChoice(provider: final String code) => "provider:$code",
        _ => ""
      },
      searchPlaceholder: s.shipment_carrier_search,
      emptyText: s.shipment_carrier_empty,
      maxOptions: 8,
      options: [
        SelectOption(value: "", placeholder: s.shipments_carrier_none, icon: CI.remove_image),
        for (final rider in carriers.riders) SelectOption(
          value: "rider:${rider.id}",
          placeholder: rider.name.isEmpty ? s.shipments_carrier_rider : rider.name,
          subtitle: rider.title.isEmpty ? s.shipment_carrier_team : rider.title,
          icon: CI.employee
        ),
        for (final provider in carriers.providers) SelectOption(
          value: "provider:${provider.code}",
          placeholder: provider.name.isEmpty ? provider.code : provider.name,
          subtitle: provider.kind == "courier" ? s.shipment_carrier_courier : s.shipment_carrier_platform,
          icon: provider.kind == "courier" ? CI.delivery_plane : CI.shop_mobile
        )
      ]
    );

    if (picked == null || !mounted) return;

    final value = picked.value;
    final choice = value.startsWith("rider:")
      ? CarrierChoice.rider(value.substring(6))
      : value.startsWith("provider:")
        ? CarrierChoice.provider(value.substring(9))
        : const CarrierChoice.none();

    final body = editShipmentRequest(widget.shipment, carrier: choice);
    if (body == null) return;

    try {
      await widget.service.move(body);
      if (!mounted) return;

      FloatFlag.of(context).message(choice.isNone ? s.shipment_rider_removed : s.shipment_rider_assigned);
    } catch (error) {
      FloatFlag.showFromError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final shipment = widget.shipment;
    final confirming = shipment.confirming;
    final nobody = _carriers != null && _carriers!.riders.isEmpty;
    final busy = widget.service.busy != null;

    final subtitle = confirming
      ? s.shipment_rider_confirm_first
      : nobody
        ? s.shipment_rider_nobody
        : s.shipment_rider_subtitle;

    return SettingsBlock(
      title: s.shipment_rider,
      subtitle: subtitle,
      child: IgnorePointer(
        ignoring: confirming || busy,
        child: AnimatedOpacity(
          opacity: confirming ? 0.45 : 1,
          duration: const Duration(milliseconds: 150),
          child: SettingsSelect(
            label: shipmentCarrierLabel(context, shipment.carrier),
            icon: shipment.carrier?.provider == null ? CI.employee : CI.delivery,
            color: shipment.carrier == null ? scheme.text.secondary : null,
            open: _pick
          )
        )
      )
    );
  }
}
