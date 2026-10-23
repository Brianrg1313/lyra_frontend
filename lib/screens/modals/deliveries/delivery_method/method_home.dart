import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_delivery_model.dart';
import 'package:app/services/business/business_delivery_request.dart';

// WIDGETS
import 'package:app/screens/home/sections/business/settings/profile_block.dart';
import 'package:app/screens/home/sections/business/settings/profile_field.dart';

import './delivery_flag_field.dart';
import './delivery_gate.dart';
import './delivery_option_field.dart';
import './method_card.dart';

/// The panel's first page: the one question —how do you deliver?— as three
/// cards, and under them what the company already has: its methods, each
/// editable, and whether a customer can collect instead.
///
/// Whether the company delivers is not asked: adding a method says yes (see
/// `DeliveryMethodModal`). Only a company that said no is told so here, with
/// the way to turn it back on, because its methods are then not offered.
class DeliveryMethodHome extends StatelessWidget {
  const DeliveryMethodHome({
    super.key,
    required this.delivery,
    required this.catalog,
    required this.onPick,
    required this.onEdit,
    required this.onRemove,
    required this.onFlag
  });

  final BusinessDeliveryModel delivery;

  /// The carriers of the company's country, for the cards' examples. `null`
  /// while it is read, or when it could not be.
  final DeliveryCatalog? catalog;

  final void Function(DeliveryMode mode) onPick;
  final void Function(DeliveryOption option) onEdit;
  final void Function(DeliveryOption option) onRemove;

  /// Saves one flag; `null` is "not set".
  final Future<void> Function(DeliveryFlag flag, bool? value) onFlag;

  /// Most options a company may keep (the backend's `Delivery.#max`). At the
  /// limit the cards are not offered: the backend would refuse another.
  static const int limit = 20;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final options = delivery.options;
    final off = delivery.delivers == false;

    return ScrollableWidget(
      padding: EdgeInsets.only(bottom: AppSize.padding),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextSmall(
          S.of(context).deliveries_method_subtitle,
          lines: 3,
          color: scheme.text.secondary
        ),
        SizedBox(height: AppSize.spaceM),
        TextMedium(S.of(context).deliveries_method_how, bold: true),
        SizedBox(height: AppSize.spaceS),
        if (options.length < limit)
          for (final mode in catalog?.modes ?? DeliveryMode.values) Padding(
            padding: EdgeInsets.only(bottom: AppSize.gap),
            child: DeliveryMethodCard(
              mode: mode,
              examples: [for (final provider in catalog?.of(mode) ?? const []) provider.name],
              onPick: () => onPick(mode)
            )
          )
        else
          TextSmall(
            S.of(context).deliveries_method_limit(limit),
            lines: 2,
            color: scheme.text.secondary
          ),
        if (off) ...[
          SizedBox(height: AppSize.spaceS),
          _Off(onTurnOn: () => onFlag(DeliveryFlag.delivers, true))
        ],
        SizedBox(height: AppSize.padding),
        ProfileBlock(
          title: S.of(context).deliveries_method_yours,
          fields: [
            if (options.isEmpty)
              ProfileField(
                icon: CI.delivery,
                label: S.of(context).deliveries_method_yours_empty,
                description: S.of(context).deliveries_method_yours_empty_note,
                value: ""
              )
            else
              for (final option in options) DeliveryGate(
                off: off,
                child: DeliveryOptionField(
                  option: option,
                  currency: delivery.currency,
                  onEdit: () => onEdit(option),
                  onRemove: () => onRemove(option)
                )
              )
          ]
        ),
        SizedBox(height: AppSize.padding),
        // Not a way of delivering, so neither faded nor asked as one: a
        // customer who can collect is answered whatever the methods say.
        ProfileBlock(
          title: S.of(context).deliveries_method_pickup,
          fields: [
            DeliveryFlagField(
              flag: DeliveryFlag.pickup,
              value: delivery.pickup,
              icon: CI.store,
              label: S.of(context).business_delivery_pickup,
              description: S.of(context).business_delivery_pickup_note,
              onChanged: onFlag
            )
          ]
        )
      ]
    );
  }
}

/// Says that delivery is turned off, and turns it back on.
class _Off extends StatelessWidget {
  const _Off({required this.onTurnOn});

  final void Function() onTurnOn;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Surface.over(
      padding: EdgeInsets.all(AppSize.spaceS),
      child: Row(children: [
        Icon(CI.info, size: AppSize.text, color: scheme.chart.serious),
        SizedBox(width: AppSize.gap),
        Expanded(child: TextSmall(
          S.of(context).business_delivery_off_note,
          lines: 3,
          color: scheme.text.secondary
        )),
        SizedBox(width: AppSize.gap),
        FeedbackButton(
          action: onTurnOn,
          padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS, vertical: AppSize.gap),
          radius: AppSize.corner,
          feedbackColor: scheme.surfaceFeedback,
          child: TextSmall(S.of(context).deliveries_method_turn_on, bold: true, color: scheme.primary)
        )
      ])
    );
  }
}
