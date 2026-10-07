import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:latlong2/latlong.dart';

// SERVICES
import 'package:app/services/business/delivery_area_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/section_message.dart';

import './area_layers.dart';
import './area_probe.dart';
import './area_tile.dart';

/// Left panel while looking: which areas reach the point tapped on the map,
/// and every area, each with its colour on the map, its size and its figures.
class AreaList extends StatelessWidget {
  const AreaList({
    super.key,
    required this.areas,
    required this.probe,
    required this.onClearProbe,
    required this.onFocus,
    required this.onEdit,
    required this.onToggle,
    required this.onRemove
  });

  final DeliveryAreasModel areas;

  /// The point tapped on the map, or `null` when none was.
  final LatLng? probe;

  final void Function() onClearProbe;

  /// Moves the map to an area.
  final void Function(DeliveryArea area) onFocus;

  final void Function(DeliveryArea area) onEdit;

  /// Pauses or resumes one.
  final void Function(DeliveryArea area) onToggle;

  final void Function(DeliveryArea area) onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final point = probe;

    return ScrollableWidget(
      showBar: false,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (point != null)
          AreaProbe(areas: areas, point: point, onClear: onClearProbe)
        else
          Padding(
            padding: EdgeInsets.only(bottom: AppSize.spaceS),
            child: TextSmall(
              S.of(context).deliveries_area_probe_hint,
              lines: 3,
              color: scheme.text.secondary
            )
          ),
        if (areas.areas.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSize.spaceL),
            child: SectionMessage(
              icon: CI.globe_shopping,
              title: S.of(context).deliveries_area_empty_title,
              subtitle: S.of(context).deliveries_area_empty_subtitle
            )
          )
        else
          for (var i = 0; i < areas.areas.length; i++)
            AreaTile(
              area: areas.areas[i],
              color: areaColor(context, i, active: areas.areas[i].active),
              currency: areas.currency,
              onFocus: () => onFocus(areas.areas[i]),
              onEdit: () => onEdit(areas.areas[i]),
              onToggle: () => onToggle(areas.areas[i]),
              onRemove: () => onRemove(areas.areas[i])
            )
      ]
    );
  }
}
