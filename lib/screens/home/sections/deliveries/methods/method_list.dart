import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_delivery_model.dart';
import 'package:app/services/business/business_delivery_request.dart';
import 'package:app/services/business/business_delivery_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/section_message.dart';
import 'package:app/screens/home/sections/business/settings/profile_block.dart';
import 'package:app/screens/home/sections/business/settings/profile_field.dart';

import 'package:app/screens/home/sections/deliveries/delivery_format.dart';
import './widgets/delivery_gate.dart';
import './widgets/delivery_notes_field.dart';
import './widgets/delivery_option_field.dart';

/// The desk's Methods view: the company's delivery methods (edit, remove),
/// whether a customer can collect instead, and the note that holds for every
/// delivery. A new method is added from the panel's title ("New delivery
/// method"), never from here: one way in.
///
/// Whether the company delivers is not asked: adding a method says yes (see
/// `MethodFlowPanel`). Only a company that said no is told so here, with the
/// way to turn it back on, because its methods are then not offered.
class MethodList extends StatelessWidget {
  const MethodList({super.key, required this.onEdit});

  /// Opens a method's form in the panel.
  final void Function(DeliveryOption option) onEdit;

  /// Most options a company may keep (the backend's `Delivery.#max`). At the
  /// limit no new one is offered: the backend would refuse it.
  static const int limit = 20;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<BusinessDeliveryService>();
    final delivery = service.delivery;

    if (delivery == null) {
      return service.status == BusinessDeliveryStatus.error
        ? SectionMessage(
            icon: CI.info,
            title: S.of(context).business_delivery_error_title,
            subtitle: S.of(context).business_delivery_error_subtitle,
            action: service.retry,
            actionLabel: S.of(context).business_list_retry
          )
        : const Center(child: Loading());
    }

    final options = delivery.options;
    final off = delivery.delivers == false;

    Future<void> flag(DeliveryFlag flag, bool? value) => service.setFlag(context, flag, value);

    return ScrollableWidget(
      showBar: false,
      padding: EdgeInsets.only(bottom: AppSize.padding),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (off) ...[
          _Off(onTurnOn: () => flag(DeliveryFlag.delivers, true)),
          SizedBox(height: AppSize.spaceS)
        ],
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
                  onRemove: () => _remove(context, service, option)
                )
              )
          ]
        ),
        SizedBox(height: AppSize.padding),
        // Not a way of delivering, so neither faded nor asked as one: a
        // customer who can collect is answered whatever the methods say. Read
        // only: each branch says it in its form, and the backend measures the
        // company's answer from theirs (`PICKUP` here is `pickup_is_per_branch`).
        ProfileBlock(
          title: S.of(context).deliveries_method_pickup,
          fields: [
            ProfileField(
              icon: CI.store,
              label: S.of(context).business_delivery_pickup,
              description: S.of(context).business_delivery_pickup_note,
              value: switch (delivery.pickup) {
                true => S.of(context).business_delivery_yes,
                false => S.of(context).business_delivery_no,
                null => S.of(context).business_delivery_unset
              }
            )
          ]
        ),
        SizedBox(height: AppSize.padding),
        DeliveryNotesField(
          // A fresh field when the saved note changes under it (another
          // device, a retry), instead of a draft that silently disagrees.
          key: ValueKey(delivery.notes),
          notes: delivery.notes,
          onSave: (notes) => service.setNotes(context, notes)
        )
      ]
    );
  }

  /// Removes a method, after asking. What it warns about is what happens:
  /// customers stop being offered it, and whether the company delivers does
  /// not change.
  Future<void> _remove(BuildContext context, BusinessDeliveryService service, DeliveryOption option) async {
    final confirmed = await showAlertModal(
      context: context,
      title: S.of(context).business_delivery_remove_title,
      message: S.of(context).business_delivery_remove_message(deliveryOptionName(context, option)),
      confirmText: S.of(context).business_delivery_remove,
      cancelText: S.of(context).cancel
    );

    if (!confirmed || !context.mounted) return;

    await service.removeOption(context, option.id);
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
