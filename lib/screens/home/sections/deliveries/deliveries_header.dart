import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/home/sections/deliveries/settings/_settings.dart';

/// The section's actions, floating over the map's top right corner (the
/// title is the panel's).
///
/// "New delivery" has no endpoint behind it yet, so it answers coming soon.
/// "Settings" opens the delivery settings sub-page (`DeliverySettingsSection`);
/// it sits on a surface so it reads over the tiles.
class DeliveriesHeader extends StatelessWidget {
  const DeliveriesHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Surface(
          radius: AppSize.corner,
          child: FeedbackButton(
            height: AppSize.button,
            feedbackColor: scheme.surfaceFeedback,
            padding: EdgeInsets.symmetric(horizontal: AppSize.padding),
            action: () => Navis.push(context, DeliverySettingsSection.path),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CI.setting, size: AppSize.text, color: scheme.icon),
                SizedBox(width: AppSize.gap),
                TextMedium(S.of(context).deliveries_settings)
              ]
            )
          )
        ),
        SizedBox(width: AppSize.gap),
        Button(
          width: null,
          title: S.of(context).deliveries_create,
          leftIcon: Icon(CI.plus, color: scheme.button.text),
          action: () => FloatFlag.of(context).message(S.of(context).coming_soon)
        )
      ]
    );
  }
}
