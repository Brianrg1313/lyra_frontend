import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/delivery_area_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/deliveries/delivery_format.dart';
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// What the tapped point gets: the areas in force holding it (cheapest first),
/// or that none does, and the branch the order would leave from.
class AreaProbe extends StatelessWidget {
  const AreaProbe({
    super.key,
    required this.holding,
    required this.currency,
    required this.colorOf,
    required this.onClear,
    this.from
  });

  /// The active areas in force holding the point, cheapest first.
  final List<DeliveryArea> holding;

  final String currency;

  /// Each area's colour, the one the map draws it with.
  final Color Function(DeliveryArea area) colorOf;

  /// Name of the branch the order would leave from (`deliveringBranch`), or
  /// `null` when no branch is on the map.
  final String? from;

  final void Function() onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (holding.isEmpty)
            TextSmall(
              S.of(context).deliveries_area_probe_out_note,
              lines: 3,
              color: scheme.text.secondary
            )
          else
            Wrap(
              spacing: AppSize.gap,
              runSpacing: AppSize.gap,
              children: [
                for (final area in holding) SettingsTag(
                  icon: CI.globe_shopping,
                  label: area.fee == null
                    ? area.name
                    : "${area.name} · ${deliveryFeeLabel(context, area.fee, currency)}",
                  color: colorOf(area)
                )
              ]
            ),
          // Where it would leave from is only news where it is delivered.
          if (holding.isNotEmpty && from != null) ...[
            SizedBox(height: AppSize.gap),
            SettingsTag(
              icon: CI.store,
              label: S.of(context).deliveries_area_probe_from(from!),
              color: scheme.text.secondary
            )
          ]
        ]
      )
    );
  }
}
