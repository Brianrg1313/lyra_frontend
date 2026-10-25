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

/// **Who takes it and when**: the two picks a dispatcher makes on every order,
/// side by side and each written the moment it is made (`editShipmentRequest`
/// with that field alone). They are steps, not fields among others, so they
/// carry no save button; the details below do.
///
/// Riders are the branch's people (`GET /shipments/carriers`, any active job
/// of the branch until the backend narrows them to riders) and the country's
/// platforms and couriers; the backend moves an unassigned shipment to
/// assigned by itself. The window is one of the branch's franjas with room
/// left. An order waiting to be confirmed takes its window but nobody
/// (`shipment_unconfirmed`), so the rider waits.
class ShipmentDispatch extends StatefulWidget {
  const ShipmentDispatch({super.key, required this.shipment, required this.service});

  final Shipment shipment;
  final ShipmentsService service;

  @override
  State<ShipmentDispatch> createState() => _ShipmentDispatchState();
}

class _ShipmentDispatchState extends State<ShipmentDispatch> {
  ShipmentCarriers? _carriers;

  /// The franjas offered by the picker, read when it first opens.
  List<DeliverySlot>? _slots;

  Shipment get _shipment => widget.shipment;

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

  Future<void> _pickRider(BuildContext anchor) async {
    final s = S.of(context);
    ShipmentCarriers carriers;

    try {
      carriers = await widget.service.loadCarriers();
    } catch (error) {
      FloatFlag.showFromError(error);
      return;
    }

    if (!anchor.mounted || !mounted) return;
    if (_carriers == null) setState(() => _carriers = carriers);

    final picked = await showSelectMenu(
      context: anchor,
      selected: switch (CarrierChoice.of(_shipment.carrier)) {
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

    await _write(
      editShipmentRequest(_shipment, carrier: choice),
      choice.isNone ? s.shipment_rider_removed : s.shipment_rider_assigned
    );
  }

  Future<void> _pickWindow(BuildContext anchor) async {
    final s = S.of(context);

    try {
      _slots ??= await widget.service.windows();
    } catch (error) {
      FloatFlag.showFromError(error);
      return;
    }

    if (!anchor.mounted || !mounted) return;

    final slots = _slots!;
    final window = _shipment.window;

    if (slots.isEmpty) {
      FloatFlag.of(context).alert(message: s.shipment_window_no_slots);
    }

    final picked = await showSelectMenu(
      context: anchor,
      selected: window == null ? "" : _windowValue(window),
      searchPlaceholder: s.shipment_window_search,
      emptyText: s.shipment_window_no_slots,
      maxOptions: 8,
      options: [
        SelectOption(value: "", placeholder: s.shipments_window_none, icon: CI.remove_image),
        for (final slot in slots) SelectOption(
          value: _windowValue(slot.window),
          placeholder: shipmentWindowLabel(context, slot.window),
          subtitle: slot.seats == null
            ? s.shipment_window_taken(slot.taken)
            : s.shipment_window_seats(slot.seats!, slot.taken),
          icon: CI.calendar
        )
      ]
    );

    if (picked == null || !mounted) return;

    final chosen = picked.value.isEmpty
      ? null
      : slots.firstWhere((slot) => _windowValue(slot.window) == picked.value).window;

    await _write(
      editShipmentRequest(_shipment, window: chosen, clearWindow: chosen == null),
      s.shipment_window_saved
    );
  }

  static String _windowValue(ShipmentWindow window) =>
    "${window.from.millisecondsSinceEpoch}-${window.to.millisecondsSinceEpoch}";

  Future<void> _write(Map<String, dynamic>? body, String done) async {
    if (body == null) return;

    try {
      await widget.service.move(body);
      if (mounted) FloatFlag.of(context).message(done);
    } catch (error) {
      FloatFlag.showFromError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final shipment = _shipment;
    final confirming = shipment.confirming;
    final busy = widget.service.busy != null;
    final nobody = !confirming && _carriers != null && _carriers!.riders.isEmpty;
    final window = shipment.window;

    return SettingsBlock(
      title: s.shipment_dispatch,
      subtitle: s.shipment_dispatch_subtitle,
      child: IgnorePointer(
        ignoring: busy,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _Pick(
            label: s.shipment_rider,
            note: confirming ? s.shipment_rider_confirm_first : nobody ? s.shipment_rider_nobody : null,
            waiting: confirming,
            child: SettingsSelect(
              label: shipmentCarrierLabel(context, shipment.carrier),
              icon: shipment.carrier?.provider == null ? CI.employee : CI.delivery,
              color: shipment.carrier == null ? scheme.text.secondary : null,
              open: _pickRider
            )
          ),
          SizedBox(height: AppSize.spaceS),
          _Pick(
            label: s.shipment_window,
            child: SettingsSelect(
              label: window == null ? s.shipments_window_none : shipmentWindowLabel(context, window),
              icon: CI.calendar,
              color: window == null ? scheme.text.secondary : null,
              open: _pickWindow
            )
          )
        ])
      )
    );
  }
}

/// A pick with its name over it, set like the form's titles below so the
/// panel's labels read as one column. One that [waiting] is faded and inert.
class _Pick extends StatelessWidget {
  const _Pick({required this.label, required this.child, this.note, this.waiting = false});

  final String label;
  final Widget child;

  /// Why the pick may come up short, under it.
  final String? note;

  final bool waiting;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: EdgeInsets.only(left: AppSize.spaceXS, bottom: AppSize.gap),
        child: TextMedium(label)
      ),
      IgnorePointer(
        ignoring: waiting,
        child: AnimatedOpacity(
          opacity: waiting ? 0.45 : 1,
          duration: const Duration(milliseconds: 150),
          child: child
        )
      ),
      if (note != null) Padding(
        padding: EdgeInsets.only(left: AppSize.spaceXS, top: AppSize.gap),
        child: TextSmall(note!, lines: 3, color: scheme.text.secondary)
      )
    ]);
  }
}
