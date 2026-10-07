import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// Opens the delivery area page. Drawn like the [SettingsSelect] beside it, so
/// the two read as one row of controls.
class DeliveryAreaButton extends StatelessWidget {
  const DeliveryAreaButton({super.key, required this.action});

  final void Function() action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return FeedbackButton(
      action: action,
      height: AppSize.button,
      padding: EdgeInsets.symmetric(horizontal: AppSize.gap),
      radius: AppSize.cornerInset(AppSize.spaceXS),
      color: scheme.surface.withAlpha(150),
      feedbackColor: scheme.surface,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CI.globe_shopping, size: AppSize.text * 0.9, color: scheme.icon),
          SizedBox(width: AppSize.gap * 0.75),
          TextSmall(S.of(context).deliveries_area)
        ]
      )
    );
  }
}
