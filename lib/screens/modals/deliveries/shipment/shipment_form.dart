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
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// **The details of a delivery**: what is typed about it, as drafts until
/// saved; one save sends only what changed (`editShipmentRequest`), and the
/// button shows only once something did, so an untouched form is just its
/// fields.
///
/// Who carries it and when are picked above and written at once
/// (`ShipmentDispatch`); a platform or courier's order or tracking number is
/// typed here. A sale with no point of its own (a counter sale) takes an
/// address and a point here; one that came with the customer's pin keeps it,
/// measured by the backend on every read.
///
/// The drafts follow the row while nothing is edited, so a window the
/// customer chose through the bot shows up in an open form.
///
/// An order waiting to be confirmed takes only its note and address
/// (the backend refuses the rest, `shipment_unconfirmed`): no reference, cost
/// or receiver is offered until it is confirmed.
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

  bool _dirty = false;

  /// Set while [_fill] writes the drafts, which is not an edit.
  bool _filling = false;

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

    _filling = true;
    _set(_reference, shipment.carrier?.reference ?? "");
    _set(_cost, shipment.cost == null ? "" : _plain(shipment.cost!));
    _set(_note, shipment.note);
    _set(_receiver, shipment.receiver);
    _set(_address, shipment.destination.address);
    _set(_point, _pointOf(shipment));
    _filling = false;
    _dirty = false;
  }

  static String _pointOf(Shipment shipment) {
    final destination = shipment.destination;

    return destination.hasPoint
      ? "${destination.latitude!.toStringAsFixed(6)}, ${destination.longitude!.toStringAsFixed(6)}"
      : "";
  }

  void _set(InputController input, String text) {
    if (input.textController.text != text) input.textController.text = text;
  }

  /// Follows every keystroke both ways, so typing a field back to what it was
  /// hides the buttons again.
  void _edited() {
    if (_filling) return;

    final shipment = _shipment;
    final changed = _reference.value != (shipment.carrier?.reference ?? "") ||
      _cost.value != (shipment.cost == null ? "" : _plain(shipment.cost!)) ||
      _note.value != shipment.note ||
      _receiver.value != shipment.receiver ||
      _address.value != shipment.destination.address ||
      _point.value != _pointOf(shipment);

    if (changed != _dirty) setState(() => _dirty = changed);
  }

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

    final provider = _shipment.carrier?.provider;
    final carrier = provider == null ? null : CarrierChoice.provider(provider, reference: _reference.value.trim());

    final body = editShipmentRequest(
      _shipment,
      carrier: carrier,
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
    final confirming = _shipment.confirming;

    return SettingsBlock(
      title: s.shipment_details,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (!confirming && _shipment.carrier?.provider != null) Input(
          title: s.shipment_reference,
          placeholder: s.shipment_reference_hint,
          controller: _reference
        ),
        if (!confirming) Input(
          title: s.shipment_cost,
          placeholder: s.shipment_cost_hint,
          controller: _cost,
          leftIcon: Icon(CI.receipt, color: scheme.icon)
        ),
        if (!confirming) Input(
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
        Input(title: s.shipment_note, placeholder: s.shipment_note_hint, controller: _note, lines: 3),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: !_dirty ? const SizedBox(width: double.infinity) : Padding(
            padding: EdgeInsets.only(top: AppSize.gap),
            child: Row(children: [
              Expanded(child: Button(title: s.shipment_discard, action: () => setState(_fill))),
              SizedBox(width: AppSize.gap),
              Expanded(child: MainButton(
                title: s.save,
                action: () {
                  if (!busy) unawaited(_save());
                }
              ))
            ])
          )
        )
      ])
    );
  }

  static String _plain(double value) =>
    value.toStringAsFixed(2).replaceFirst(RegExp(r"\.?0+$"), "");
}
