import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/delivery_area_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/deliveries/settings/delivery_format.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// One area: its colour and name, what shape it is and how big, its figures,
/// and what can be done with it.
class AreaTile extends StatelessWidget {
  const AreaTile({
    super.key,
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
