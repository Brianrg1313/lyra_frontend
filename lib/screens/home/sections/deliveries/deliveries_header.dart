import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:core/button.dart';

/// The section's actions, floating over the map's top right corner: "New
/// delivery method" (its steps take the panel over) and "New delivery".
///
/// "New delivery" has no endpoint behind it yet, so it answers coming soon.
class DeliveriesHeader extends StatelessWidget {
  const DeliveriesHeader({super.key, required this.onNewMethod});

  /// `null` while the panel is taken (a method or an area under way): it
  /// is not offered then.
  final void Function()? onNewMethod;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onNewMethod != null) ...[
          FeedbackButton(
            action: onNewMethod,
            height: AppSize.action,
            padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS),
            radius: AppSize.corner,
            color: scheme.surface,
            feedbackColor: scheme.surfaceFeedback,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CI.plus, size: AppSize.text, color: scheme.icon),
                SizedBox(width: AppSize.gap),
                TextSmall(S.of(context).deliveries_method_new, bold: true)
              ]
            )
          ),
          SizedBox(width: AppSize.gap)
        ],
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
