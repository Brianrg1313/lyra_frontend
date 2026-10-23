import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/branch_service.dart';
import 'package:app/services/business/business_delivery_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/business/settings/profile_action.dart';
import 'package:app/screens/home/sections/business/settings/profile_field_frame.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

import 'package:app/screens/home/sections/deliveries/delivery_format.dart';

/// One way the company delivers, as a row of the options block.
///
/// The name is what the company or the catalog calls it, with the carrier's
/// brand beside it when the company gave the option a name of its own. Below
/// go who carries it and how far —the two closed answers— and then, as tags,
/// the figures a customer asks about: what it costs, from when it is free, how
/// long it takes and where it reaches.
///
/// A figure the company did not give is not drawn, except the price: "the
/// price varies" is an answer too.
class DeliveryOptionField extends StatelessWidget {
  const DeliveryOptionField({
    super.key,
    required this.option,
    required this.currency,
    required this.onEdit,
    required this.onRemove
  });

  final DeliveryOption option;

  /// The company's currency, which every fee is in.
  final String currency;

  final void Function() onEdit;
  final void Function() onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return ProfileFieldFrame(
      icon: option.mode.icon,
      label: deliveryOptionName(context, option),
      note: option.label.isNotEmpty && option.carrier.isNotEmpty
        ? option.carrier
        : null,
      description:
        "${option.mode.label(context)} · ${option.coverage.label(context)}",
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ProfileAction(
            icon: CI.edit,
            message: S.of(context).edit,
            action: onEdit
          ),
          SizedBox(width: AppSize.gap),
          ProfileAction(
            icon: CI.trash,
            message: S.of(context).business_delivery_remove,
            action: onRemove
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSize.gap,
            runSpacing: AppSize.gap,
            children: _tags(context)
          ),
          if (option.notes.isNotEmpty) ...[
            SizedBox(height: AppSize.gap),
            TextSmall(
              option.notes,
              lines: 3,
              ellipsis: true,
              color: scheme.text.secondary
            )
          ]
        ]
      )
    );
  }

  List<Widget> _tags(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final neutral = scheme.text.secondary;
    final eta = deliveryEtaLabel(context, option.etaMin, option.etaMax);
    final local = option.coverage == DeliveryCoverage.local;

    return [
      SettingsTag(
        icon: CI.wallet,
        label: deliveryFeeLabel(context, option.fee, currency),
        color: option.fee == 0 ? scheme.snackBar.success : neutral
      ),
      // "Free from" says nothing on an option that is already free.
      if (option.freeFrom != null && option.fee != 0) SettingsTag(
        icon: CI.gift,
        label: S.of(context).business_delivery_free_from(
          deliveryAmount(option.freeFrom!, currency)
        ),
        color: scheme.snackBar.success
      ),
      if (option.minimum != null) SettingsTag(
        icon: CI.cart_shopping,
        label: S.of(context).deliveries_area_minimum_tag(
          deliveryAmount(option.minimum!, currency)
        ),
        color: neutral
      ),
      if (eta.isNotEmpty) SettingsTag(
        icon: CI.calendar,
        label: eta,
        color: neutral
      ),
      if (local && option.radius != null) SettingsTag(
        icon: CI.globe_shopping,
        label: deliveryRadiusLabel(context, option.radius!),
        color: neutral
      ),
      if (local && option.zones.isNotEmpty) SettingsTag(
        icon: CI.list,
        label: deliveryZonesLabel(context, option.zones, currency),
        color: neutral
      ),
      if (!local && option.branch != null) SettingsTag(
        icon: CI.store,
        label: S.of(context).business_delivery_branch_from(
          BranchService().nameOf(option.branch).isEmpty
            ? S.of(context).finance_method_branch_other
            : BranchService().nameOf(option.branch)
        ),
        color: neutral
      )
    ];
  }
}
