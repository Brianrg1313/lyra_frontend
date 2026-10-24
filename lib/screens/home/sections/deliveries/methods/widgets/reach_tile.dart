import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_delivery_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/deliveries/delivery_format.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// An own delivery's reach in the areas list: whose it is, how it was
/// measured, what they ride. It is not a `delivery_areas` row: it has no
/// pause, and removing it removes the whole method it belongs to.
class ReachTile extends StatelessWidget {
  const ReachTile({
    super.key,
    required this.option,
    required this.color,
    required this.currency,
    required this.onFocus,
    required this.onEdit,
    required this.onRemove
  });

  /// An own option with a reach.
  final DeliveryOption option;
  final Color color;
  final String currency;
  final void Function() onFocus;
  final void Function() onEdit;

  /// Removes the method (the caller asks first).
  final void Function() onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final vehicle = option.vehicle;

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
              Icon(CI.delivery, size: AppSize.text, color: color),
              SizedBox(width: AppSize.gap),
              Expanded(child: TextMedium(
                deliveryOptionName(context, option),
                bold: true,
                ellipsis: true
              )),
              SettingsAction(
                icon: CI.edit,
                message: S.of(context).deliveries_reach_edit,
                action: onEdit
              ),
              SizedBox(width: AppSize.gap / 2),
              SettingsAction(
                icon: CI.trash,
                message: S.of(context).business_delivery_remove,
                action: onRemove
              )
            ]),
            SizedBox(height: AppSize.gap),
            TextSmall(_shape(context), ellipsis: true, color: scheme.text.secondary),
            if (vehicle != null || option.minimum != null) ...[
              SizedBox(height: AppSize.gap),
              Wrap(
                spacing: AppSize.gap,
                runSpacing: AppSize.gap,
                children: [
                  if (vehicle != null) SettingsTag(
                    label: vehicle.label(context),
                    color: scheme.text.secondary
                  ),
                  if (option.minimum != null) SettingsTag(
                    icon: CI.cart_shopping,
                    label: S.of(context).deliveries_area_minimum_tag(
                      deliveryAmount(option.minimum!, currency)
                    ),
                    color: scheme.text.secondary
                  )
                ]
              )
            ]
          ]
        )
      )
    );
  }

  /// "Travel time · 30 min", "Road distance · 15 km", "Draw it".
  String _shape(BuildContext context) {
    final reach = option.reach!;
    final value = reach.value;
    final size = value == null ? null : switch (reach.kind) {
      DeliveryReachKind.time => S.of(context).business_delivery_eta_minutes(value.round()),
      DeliveryReachKind.drawn => null,
      _ => S.of(context).deliveries_area_km(deliveryNumber(value))
    };
    final kind = switch (reach.kind) {
      DeliveryReachKind.radius => S.of(context).business_delivery_reach_radius,
      DeliveryReachKind.time => S.of(context).business_delivery_reach_time,
      DeliveryReachKind.road => S.of(context).business_delivery_reach_road,
      DeliveryReachKind.drawn => S.of(context).deliveries_area_drawn
    };

    return size == null ? kind : "$kind · $size";
  }
}
