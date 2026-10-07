import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:latlong2/latlong.dart';

// SERVICES
import 'package:app/services/business/delivery_area_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/deliveries/settings/delivery_format.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

import './area_layers.dart';

/// What the tapped point gets: the areas holding it, or that none does.
class AreaProbe extends StatelessWidget {
  const AreaProbe({super.key, required this.areas, required this.point, required this.onClear});

  final DeliveryAreasModel areas;
  final LatLng point;
  final void Function() onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final holding = areas.holding(point);

    return SettingsBlock(
      title: holding.isEmpty
        ? S.of(context).deliveries_area_probe_out
        : S.of(context).deliveries_area_probe_in,
      subtitle: holding.length > 1
        ? S.of(context).deliveries_area_probe_overlap
        : null,
      action: SettingsAction(
        icon: CI.remove_image,
        message: S.of(context).deliveries_area_probe_clear,
        action: onClear
      ),
      child: holding.isEmpty
        ? TextSmall(
            S.of(context).deliveries_area_probe_out_note,
            lines: 3,
            color: scheme.text.secondary
          )
        : Wrap(
            spacing: AppSize.gap,
            runSpacing: AppSize.gap,
            children: [
              for (final area in holding) SettingsTag(
                icon: CI.globe_shopping,
                label: area.fee == null
                  ? area.name
                  : "${area.name} · ${deliveryFeeLabel(context, area.fee, areas.currency)}",
                color: areaColor(context, areas.areas.indexOf(area))
              )
            ]
          )
    );
  }
}
