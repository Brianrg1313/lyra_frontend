import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/shipments/shipment_model.dart';
import 'package:app/services/shipments/shipping_settings_service.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// **How the branch's hours are cut into franjas**: how long each lasts, how
/// many deliveries fit in one (empty is no limit), how long an order takes to
/// prepare, how many days ahead are offered, and how wide a window a customer
/// is offered on a day filling up. Each figure is checked against the
/// backend's range before it is sent. Read only without `shipments.configure`.
class SlotSettings extends StatefulWidget {
  const SlotSettings({super.key, required this.service, required this.editable});

  final ShippingSettingsService service;
  final bool editable;

  @override
  State<SlotSettings> createState() => _SlotSettingsState();
}

class _SlotSettingsState extends State<SlotSettings> {
  final _form = FormController();
  late final _span = InputController(key: "SPAN", form: _form, pattern: "[0-9]", max: 3);
  late final _capacity = InputController(key: "CAPACITY", form: _form, pattern: "[0-9]", max: 3);
  late final _lead = InputController(key: "LEAD", form: _form, pattern: "[0-9]", max: 4);
  late final _days = InputController(key: "DAYS", form: _form, pattern: "[0-9]", max: 2);
  late final _width = InputController(key: "WIDTH", form: _form, pattern: "[0-9]", max: 3);

  @override
  void initState() {
    super.initState();
    _fill(widget.service.settings);
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  void _fill(ShippingSettings settings) {
    _span.textController.text = "${settings.span}";
    _capacity.textController.text = settings.capacity == null ? "" : "${settings.capacity}";
    _lead.textController.text = "${settings.lead}";
    _days.textController.text = "${settings.days}";
    _width.textController.text = "${settings.width}";
  }

  /// A whole number in [range], or null (an empty capacity is "no limit" and
  /// read apart).
  static int? _read(String text, ({int min, int max}) range) {
    final value = int.tryParse(text.trim());

    return value == null || value < range.min || value > range.max ? null : value;
  }

  Future<void> _save() async {
    final s = S.of(context);
    final span = _read(_span.value, ShippingSettings.spanRange);
    final lead = _read(_lead.value, ShippingSettings.leadRange);
    final days = _read(_days.value, ShippingSettings.daysRange);
    final width = _read(_width.value, ShippingSettings.widthRange);
    final noLimit = _capacity.value.trim().isEmpty;
    final capacity = noLimit ? null : _read(_capacity.value, ShippingSettings.capacityRange);

    if (span == null || lead == null || days == null || width == null || (!noLimit && capacity == null)) {
      FloatFlag.of(context).error(message: s.shipping_slots_invalid);
      return;
    }

    try {
      await widget.service.save(ShippingSettings(span: span, capacity: capacity, lead: lead, days: days, width: width));
      if (!mounted) return;

      _fill(widget.service.settings);
      FloatFlag.of(context).message(s.shipping_slots_saved);
    } catch (error) {
      FloatFlag.showFromError(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final settings = widget.service.settings;

    if (!widget.editable) {
      return SettingsBlock(
        title: s.shipping_slots_title,
        child: SettingsList(rows: [
          SettingsValue(icon: CI.calendar, label: s.shipping_slots_span, value: s.shipping_minutes(settings.span)),
          SettingsValue(
            icon: CI.delivery,
            label: s.shipping_slots_capacity,
            value: settings.capacity == null ? s.shipping_slots_no_limit : "${settings.capacity}"
          ),
          SettingsValue(icon: CI.task_list, label: s.shipping_slots_lead, value: s.shipping_minutes(settings.lead)),
          SettingsValue(icon: CI.calendar, label: s.shipping_slots_days, value: "${settings.days}"),
          SettingsValue(icon: CI.calendar, label: s.shipping_slots_width, value: s.shipping_minutes(settings.width))
        ])
      );
    }

    return SettingsBlock(
      title: s.shipping_slots_title,
      subtitle: s.shipping_slots_subtitle,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Input(title: s.shipping_slots_span, placeholder: s.shipping_slots_span_hint, controller: _span),
        Input(title: s.shipping_slots_capacity, placeholder: s.shipping_slots_capacity_hint, controller: _capacity),
        Input(title: s.shipping_slots_lead, placeholder: s.shipping_slots_lead_hint, controller: _lead),
        Input(title: s.shipping_slots_days, placeholder: s.shipping_slots_days_hint, controller: _days),
        Input(title: s.shipping_slots_width, placeholder: s.shipping_slots_width_hint, controller: _width),
        SizedBox(height: AppSize.spaceXS),
        Button(
          title: s.save,
          action: () {
            if (!widget.service.writing) unawaited(_save());
          }
        )
      ])
    );
  }
}
