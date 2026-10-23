import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/delivery_area_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/section_message.dart';

import './area_layers.dart';
import './area_tile.dart';

/// The desk's panel while looking: which map is open and how the areas are
/// shared ([header]), what the point tapped on the map gets ([probe], or the
/// hint to tap one), the way to add one ([add]) right above them, and every
/// area of the open map, each with its colour on the map, its size and its
/// figures.
class AreaList extends StatelessWidget {
  const AreaList({
    super.key,
    required this.header,
    this.add,
    required this.areas,
    required this.currency,
    required this.probe,
    this.footer,
    required this.onFocus,
    required this.onEdit,
    required this.onToggle,
    required this.onRemove
  });

  final Widget header;

  /// Starts a new area ("Add area"), above the areas it adds to.
  final Widget? add;

  /// The open map's areas, in order.
  final List<DeliveryArea> areas;

  final String currency;

  /// What the tapped point gets, or `null` when none was tapped.
  final Widget? probe;

  /// Under the areas: what happens outside them.
  final Widget? footer;

  /// Moves the map to an area.
  final void Function(DeliveryArea area) onFocus;

  final void Function(DeliveryArea area) onEdit;

  /// Pauses or resumes one.
  final void Function(DeliveryArea area) onToggle;

  final void Function(DeliveryArea area) onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return ScrollableWidget(
      showBar: false,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        SizedBox(height: AppSize.spaceS),
        probe ?? Padding(
          padding: EdgeInsets.only(bottom: AppSize.spaceS),
          child: TextSmall(
            S.of(context).deliveries_area_probe_hint,
            lines: 3,
            color: scheme.text.secondary
          )
        ),
        if (add != null) ...[
          add!,
          SizedBox(height: AppSize.spaceS)
        ],
        if (areas.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSize.spaceL),
            child: SectionMessage(
              icon: CI.globe_shopping,
              title: S.of(context).deliveries_area_empty_title,
              subtitle: S.of(context).deliveries_area_empty_subtitle
            )
          )
        else
          for (var i = 0; i < areas.length; i++)
            AreaTile(
              area: areas[i],
              color: areaColor(context, i, active: areas[i].active),
              currency: currency,
              onFocus: () => onFocus(areas[i]),
              onEdit: () => onEdit(areas[i]),
              onToggle: () => onToggle(areas[i]),
              onRemove: () => onRemove(areas[i])
            ),
        if (footer != null) ...[
          SizedBox(height: AppSize.spaceS),
          footer!
        ]
      ]
    );
  }
}
