import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_delivery_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/business/settings/profile_block.dart';
import 'package:app/screens/home/sections/business/settings/profile_field.dart';

import 'delivery_option_field.dart';

/// The ways the company delivers, one row each, with adding in the block's
/// title — adding belongs to the list, not to any of its rows.
///
/// With none there is an empty row and not a loose notice, like the profile's
/// emails: the block is drawn the same, and a grey line where the other
/// blocks have data reads as a list that failed to load.
class DeliveryOptionsBlock extends StatelessWidget {
  const DeliveryOptionsBlock({
    super.key,
    required this.delivery,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove
  });

  final BusinessDeliveryModel delivery;
  final void Function() onAdd;
  final void Function(DeliveryOption option) onEdit;
  final void Function(DeliveryOption option) onRemove;

  /// Most options a company may keep (the backend's `Delivery.#max`). At the
  /// limit adding is not offered: the backend would refuse it, and a list a
  /// customer cannot read through is not an answer.
  static const int limit = 20;

  @override
  Widget build(BuildContext context) {
    final options = delivery.options;

    return ProfileBlock(
      title: S.of(context).business_delivery_section_options,
      action: options.length < limit
        ? ProfileTextAction(
            label: S.of(context).business_delivery_add,
            action: onAdd
          )
        : null,
      fields: [
        // Off, the options are kept and listed: they are what comes back when
        // delivery is turned on again. That they are not offered today has to
        // be said where they are, or they read as offered.
        if (delivery.delivers == false && options.isNotEmpty) const _Off(),
        if (options.isEmpty)
          ProfileField(
            icon: CI.delivery,
            label: S.of(context).business_delivery_empty,
            description: S.of(context).business_delivery_empty_note,
            value: ""
          )
        else
          for (final option in options) DeliveryOptionField(
            option: option,
            currency: delivery.currency,
            onEdit: () => onEdit(option),
            onRemove: () => onRemove(option)
          )
      ]
    );
  }
}

/// Says that delivery is turned off, above the options it keeps.
class _Off extends StatelessWidget {
  const _Off();

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(CI.info, size: AppSize.text, color: scheme.snackBar.error),
        SizedBox(width: AppSize.spaceXS),
        Expanded(child: TextSmall(
          S.of(context).business_delivery_off_note,
          lines: 3,
          color: scheme.text.secondary
        ))
      ]
    );
  }
}
