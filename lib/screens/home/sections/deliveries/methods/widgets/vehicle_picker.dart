import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_delivery_model.dart';

// WIDGETS
import './form_section.dart';

/// What the company's own couriers ride, one tile per vehicle with its icon.
/// Tapping the one picked again leaves it unsaid.
class DeliveryVehiclePicker extends StatelessWidget {
  const DeliveryVehiclePicker({super.key, required this.selected, required this.onChanged});

  final DeliveryVehicle? selected;
  final void Function(DeliveryVehicle? vehicle) onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return FormSection(
      title: S.of(context).business_delivery_vehicle,
      child: Row(children: [
        for (final (index, vehicle) in DeliveryVehicle.values.indexed) ...[
          if (index > 0) SizedBox(width: AppSize.gap),
          Expanded(child: _Tile(
            vehicle: vehicle,
            on: vehicle == selected,
            onTap: () => onChanged(vehicle == selected ? null : vehicle),
            scheme: scheme
          ))
        ]
      ])
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.vehicle, required this.on, required this.onTap, required this.scheme});

  final DeliveryVehicle vehicle;
  final bool on;
  final void Function() onTap;
  final SchemeColor scheme;

  @override
  Widget build(BuildContext context) {
    final color = on ? scheme.button.text : scheme.text.primary;

    return FeedbackButton(
      action: onTap,
      message: vehicle.label(context),
      padding: EdgeInsets.symmetric(vertical: AppSize.spaceXS, horizontal: AppSize.gap),
      radius: AppSize.corner,
      color: on ? scheme.primary : scheme.surfaceOver,
      feedbackColor: on ? scheme.primary : scheme.surfaceFeedback,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(vehicle.icon, size: AppSize.text * 1.6, color: on ? color : scheme.icon),
          SizedBox(height: AppSize.gap * 0.5),
          TextSmall(vehicle.label(context), bold: on, ellipsis: true, color: color)
        ]
      )
    );
  }
}
