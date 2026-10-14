import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_location_request.dart';
import 'package:app/services/shipments/shipment_model.dart';
import 'package:app/services/shipments/shipment_request.dart';
import 'package:app/services/shipments/shipments_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';
import 'package:app/screens/home/sections/deliveries/shipments/shipment_format.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// **Who carries it, when, and what it cost**: the dispatcher's form. Picks
/// are drafts until saved, and one save sends only what changed
/// (`editShipmentRequest`).
///
/// The carrier is one of the branch's people or a platform or courier of the
/// country (with its order or tracking number); the window is one of the
/// branch's franjas with room left. A sale with no point of its own (a counter
/// sale) takes an address and a point here; one that came with the customer's
/// pin keeps it, measured by the backend on every read.
///
/// The drafts follow the row while nothing is edited, so a window the
/// customer chose through the bot shows up in an open form.
class ShipmentForm extends StatefulWidget {
  const ShipmentForm({super.key, required this.shipment, required this.service});

  final Shipment shipment;
  final ShipmentsService service;

  @override
  State<ShipmentForm> createState() => _ShipmentFormState();
}

class _ShipmentFormState extends State<ShipmentForm> {
  final _form = FormController();
  late final _reference = InputController(key: "REFERENCE", form: _form, max: 120);
  late final _cost = InputController(key: "COST", form: _form, pattern: "[0-9.,]", max: 12);
  late final _note = InputController(key: "NOTE", form: _form, max: 500);
  late final _receiver = InputController(key: "RECEIVER", form: _form, max: 120);
  late final _address = InputController(key: "ADDRESS", form: _form, max: 255);
  late final _point = InputController(key: "POINT", form: _form, max: 300);

  late CarrierChoice _carrier;
  ShipmentWindow? _window;
  bool _dirty = false;

  /// The franjas offered by the picker, read when it first opens.
  List<DeliverySlot>? _slots;

  Shipment get _shipment => widget.shipment;

  /// Whether the sale lacks a point of its own: then the address is asked here.
  bool get _locatable => !_shipment.destination.hasPoint || (_shipment.stored && _shipment.chat == null);

  @override
  void initState() {
    super.initState();
    _fill();

    for (final input in [_reference, _cost, _note, _receiver, _address, _point]) {
      input.textController.addListener(_edited);
    }
  }

  @override
  void didUpdateWidget(ShipmentForm old) {
    super.didUpdateWidget(old);

    if (!_dirty && !identical(old.shipment, widget.shipment)) _fill();
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  /// The drafts as the row stands.
  void _fill() {
    final shipment = _shipment;
    final destination = shipment.destination;

    _carrier = CarrierChoice.of(shipment.carrier);
    _window = shipment.window;
    _set(_reference, shipment.carrier?.reference ?? "");
    _set(_cost, shipment.cost == null ? "" : _plain(shipment.cost!));
    _set(_note, shipment.note);
    _set(_receiver, shipment.receiver);
    _set(_address, destination.address);
    _set(_point, destination.hasPoint
      ? "${destination.latitude!.toStringAsFixed(6)}, ${destination.longitude!.toStringAsFixed(6)}"
      : "");
    _dirty = false;
  }

  void _set(InputController input, String text) {
    if (input.textController.text != text) input.textController.text = text;
  }

  void _edited() {
    if (_dirty) return;

    final shipment = _shipment;
    final changed = _reference.value != (shipment.carrier?.reference ?? "") ||
      _cost.value != (shipment.cost == null ? "" : _plain(shipment.cost!)) ||
      _note.value != shipment.note ||
      _receiver.value != shipment.receiver ||
      _address.value != shipment.destination.address;

    if (changed) setState(() => _dirty = true);
  }

  Future<void> _pickCarrier(BuildContext anchor) async {
    final s = S.of(context);
    ShipmentCarriers carriers;

    try {
      carriers = await widget.service.loadCarriers();
    } catch (error) {
      FloatFlag.showFromError(error);
      return;
    }

    if (!anchor.mounted || !mounted) return;

    final picked = await showSelectMenu(
      context: anchor,
      selected: _carrierValue(_carrier),
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

    setState(() {
      _carrier = value.startsWith("rider:")
        ? CarrierChoice.rider(value.substring(6))
        : value.startsWith("provider:")
          ? CarrierChoice.provider(value.substring(9), reference: _reference.value)
          : const CarrierChoice.none();
      _dirty = true;
      _names[value] = picked.placeholder;
    });
  }

  /// Names of the carriers picked here, for the field before the row says them.
  final Map<String, String> _names = {};

  static String _carrierValue(CarrierChoice choice) => switch (choice) {
    CarrierChoice(employment: final String id) => "rider:$id",
    CarrierChoice(provider: final String code) => "provider:$code",
    _ => ""
  };

  String _carrierLabel() {
    if (_carrier == CarrierChoice.of(_shipment.carrier)) {
      return shipmentCarrierLabel(context, _shipment.carrier);
    }

    if (_carrier.isNone) return S.of(context).shipments_carrier_none;

    return _names[_carrierValue(_carrier)] ?? _carrierValue(_carrier);
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

    if (slots.isEmpty) {
      FloatFlag.of(context).alert(message: s.shipment_window_no_slots);
    }

    final picked = await showSelectMenu(
      context: anchor,
      selected: _window == null ? "" : _windowValue(_window!),
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

    setState(() {
      _window = picked.value.isEmpty
        ? null
        : slots.firstWhere((slot) => _windowValue(slot.window) == picked.value).window;
      _dirty = true;
    });
  }

  static String _windowValue(ShipmentWindow window) =>
    "${window.from.millisecondsSinceEpoch}-${window.to.millisecondsSinceEpoch}";

  Future<void> _save() async {
    final s = S.of(context);
    final cost = _cost.value.trim();

    if (cost.isNotEmpty && !RegExp(r"^\d+(?:[.,]\d{1,2})?$").hasMatch(cost)) {
      FloatFlag.of(context).error(message: s.shipment_cost_invalid);
      return;
    }

    LocationPoint? point;
    final pointText = _point.value.trim();

    if (_locatable && pointText.isNotEmpty) {
      point = parseLocationPoint(pointText);

      if (point == null) {
        FloatFlag.of(context).error(message: s.shipment_point_invalid);
        return;
      }
    }

    final carrier = _carrier.provider == null
      ? _carrier
      : CarrierChoice.provider(_carrier.provider!, reference: _reference.value.trim());

    final body = editShipmentRequest(
      _shipment,
      carrier: carrier,
      window: _window,
      clearWindow: _window == null,
      cost: cost.isEmpty ? null : double.parse(cost.replaceAll(",", ".")),
      clearCost: cost.isEmpty,
      note: _note.value,
      receiver: _receiver.value,
      address: _locatable ? _address.value : null,
      point: _locatable ? point : null,
      clearPoint: _locatable && pointText.isEmpty
    );

    if (body == null) {
      setState(_fill);
      return;
    }

    try {
      final row = await widget.service.move(body);
      if (!mounted) return;

      _dirty = false;
      if (row != null) setState(_fill);
      FloatFlag.of(context).message(s.shipment_saved);
    } catch (error) {
      FloatFlag.showFromError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final scheme = ThemeColor.of(context);
    final busy = widget.service.busy != null;

    return SettingsBlock(
      title: s.shipment_carrying,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextSmall(s.shipment_carrier, color: scheme.text.secondary),
        SizedBox(height: AppSize.gap * 0.5),
        SettingsSelect(label: _carrierLabel(), icon: CI.delivery, open: _pickCarrier),
        if (_carrier.provider != null) ...[
          SizedBox(height: AppSize.gap),
          Input(
            title: s.shipment_reference,
            placeholder: s.shipment_reference_hint,
            controller: _reference
          )
        ],
        SizedBox(height: AppSize.spaceS),
        TextSmall(s.shipment_window, color: scheme.text.secondary),
        SizedBox(height: AppSize.gap * 0.5),
        SettingsSelect(
          label: _window == null ? s.shipments_window_none : shipmentWindowLabel(context, _window!),
          icon: CI.calendar,
          open: _pickWindow
        ),
        SizedBox(height: AppSize.spaceS),
        Input(
          title: s.shipment_cost,
          placeholder: s.shipment_cost_hint,
          controller: _cost,
          leftIcon: Icon(CI.receipt, color: scheme.icon)
        ),
        Input(title: s.shipment_note, placeholder: s.shipment_note_hint, controller: _note, lines: 3),
        Input(
          title: s.shipment_receiver,
          placeholder: s.shipment_receiver_hint,
          controller: _receiver,
          leftIcon: Icon(CI.user_circle, color: scheme.icon)
        ),
        if (_locatable) ...[
          Input(
            title: s.shipment_address,
            placeholder: s.shipment_address_hint,
            controller: _address,
            leftIcon: Icon(CI.home, color: scheme.icon)
          ),
          Input(
            title: s.shipment_point,
            placeholder: s.shipment_point_hint,
            controller: _point,
            leftIcon: Icon(CI.globe_shopping, color: scheme.icon)
          )
        ],
        SizedBox(height: AppSize.spaceXS),
        Button(
          title: s.save,
          action: () {
            if (!busy) unawaited(_save());
          }
        )
      ])
    );
  }

  static String _plain(double value) =>
    value.toStringAsFixed(2).replaceFirst(RegExp(r"\.?0+$"), "");
}
