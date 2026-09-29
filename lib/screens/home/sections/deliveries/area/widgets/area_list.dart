import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:latlong2/latlong.dart';

// SERVICES
import 'package:app/services/business/delivery_area_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/section_message.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';
import 'package:app/screens/home/sections/deliveries/settings/delivery_format.dart';

import 'area_layers.dart';

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
          _Probe(areas: areas, point: point, onClear: onClearProbe)
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
            _AreaTile(
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

/// What the tapped point gets: the areas holding it, or that none does.
class _Probe extends StatelessWidget {
  const _Probe({required this.areas, required this.point, required this.onClear});

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

/// One area: its colour and name, what shape it is and how big, its figures,
/// and what can be done with it.
class _AreaTile extends StatelessWidget {
  const _AreaTile({
    required this.area,
    required this.color,
    required this.currency,
    required this.onFocus,
    required this.onEdit,
    required this.onToggle,
    required this.onRemove
  });

  final DeliveryArea area;
  final Color color;
  final String currency;
  final void Function() onFocus;
  final void Function() onEdit;
  final void Function() onToggle;
  final void Function() onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.spaceXS),
      child: FeedbackButton(
        action: onFocus,
        message: S.of(context).deliveries_area_focus,
        padding: EdgeInsets.all(AppSize.spaceS),
        radius: AppSize.corner,
        color: scheme.surfaceOver,
        feedbackColor: scheme.line,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: AppSize.text,
                height: AppSize.text,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.25),
                  border: Border.all(color: color, width: 2),
                  borderRadius: BorderRadius.circular(AppSize.gap / 2)
                )
              ),
              SizedBox(width: AppSize.gap),
              Expanded(child: TextMedium(
                area.name,
                bold: true,
                ellipsis: true,
                color: area.active ? null : scheme.text.secondary
              )),
              SettingsAction(
                icon: CI.edit,
                message: S.of(context).deliveries_area_edit,
                action: onEdit
              ),
              SizedBox(width: AppSize.gap / 2),
              SettingsAction(
                icon: area.active ? CI.eye_hidden : CI.eye,
                message: area.active
                  ? S.of(context).deliveries_area_pause
                  : S.of(context).deliveries_area_resume,
                action: onToggle
              ),
              SizedBox(width: AppSize.gap / 2),
              SettingsAction(
                icon: CI.trash,
                message: S.of(context).deliveries_area_remove,
                action: onRemove
              )
            ]),
            SizedBox(height: AppSize.gap),
            TextSmall(
              _shape(context),
              ellipsis: true,
              color: scheme.text.secondary
            ),
            SizedBox(height: AppSize.gap),
            Wrap(
              spacing: AppSize.gap,
              runSpacing: AppSize.gap,
              children: [
                SettingsTag(
                  icon: CI.wallet,
                  label: area.fee == null
                    ? S.of(context).deliveries_area_fee_option
                    : deliveryFeeLabel(context, area.fee, currency),
                  color: area.fee == null ? scheme.text.secondary : scheme.primary
                ),
                if (area.minimum != null) SettingsTag(
                  icon: CI.cart_shopping,
                  label: S.of(context).deliveries_area_minimum_tag(
                    deliveryAmount(area.minimum!, currency)
                  ),
                  color: scheme.text.secondary
                ),
                if (!area.active) SettingsTag(
                  label: S.of(context).deliveries_area_paused,
                  color: scheme.snackBar.error
                )
              ]
            )
          ]
        )
      )
    );
  }

  /// "Within 3 km · 28.3 km²", "Drawn on the map · 12.4 km²".
  String _shape(BuildContext context) {
    final size = S.of(context).deliveries_area_size(deliveryNumber(area.squareKm));

    return switch (area.kind) {
      DeliveryAreaKind.radius when area.radius != null =>
        "${deliveryRadiusLabel(context, area.radius!)} · $size",
      _ => "${S.of(context).deliveries_area_drawn} · $size"
    };
  }
}
