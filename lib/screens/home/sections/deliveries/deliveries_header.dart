import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/home/sections/deliveries/settings/_settings.dart';

/// Bar above the two panels: the section title and its actions.
///
/// "Center" only shows while there is a map and the company has a point on it.
/// "New delivery" has no endpoint behind it yet, so it answers coming soon.
/// "Settings" opens the delivery settings sub-page (`DeliverySettingsSection`).
class DeliveriesHeader extends StatelessWidget {
  const DeliveriesHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Surface(
      padding: EdgeInsets.fromLTRB(
        AppSize.padding, AppSize.gap,
        AppSize.gap, AppSize.gap
      ),
      child: SizedBox(
        height: AppSize.button,
        child: Row(children: [
          Expanded(child: TextMedium(
            S.of(context).deliveries,
            bold: true,
            ellipsis: true
          )),
          SizedBox(width: AppSize.gap),
          FeedbackButton(
            height: AppSize.button,
            feedbackColor: ThemeColor.of(context).surfaceFeedback,
            padding: EdgeInsets.symmetric(horizontal: AppSize.padding),
            action: () => FloatFlag.of(context).message(S.of(context).coming_soon),
            child: Center(child: TextMedium(S.of(context).deliveries_create))
          ),
          SizedBox(width: AppSize.gap),
          FeedbackButton(
            height: AppSize.button,
            feedbackColor: ThemeColor.of(context).surfaceFeedback,
            padding: EdgeInsets.symmetric(horizontal: AppSize.padding),
            action: () => Navis.push(context, DeliverySettingsSection.path),
            child: Center(child: TextMedium(S.of(context).deliveries_settings))
          )
        ])
      )
    );
  }
}
