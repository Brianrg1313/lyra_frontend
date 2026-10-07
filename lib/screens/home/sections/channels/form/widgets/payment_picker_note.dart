import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/badges/badge_place.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/home/badges/badge_mark.dart';

/// What is said in place of the grid: there is nothing to choose from yet, or
/// the accounts could not be read.
class PaymentPickerNote extends StatelessWidget {
  const PaymentPickerNote({super.key, required this.text, this.action, this.actionLabel, this.badge});

  final String text;
  final void Function()? action;
  final String? actionLabel;

  /// The company-wide alert behind an empty list (no way of being paid), on the icon.
  final BadgePlace? badge;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final retry = action;
    final label = actionLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          if (badge != null) BadgeCorner(
            place: badge!,
            dot: true,
            outside: true,
            child: Icon(CI.info, size: AppSize.text * 1.2, color: scheme.icon)
          )
          else Icon(CI.info, size: AppSize.text * 1.2, color: scheme.icon),
          SizedBox(width: AppSize.spaceS),
          Expanded(child: TextSmall(
            text,
            lines: 3,
            ellipsis: true,
            color: scheme.text.secondary
          ))
        ]),
        if (retry != null && label != null) ...[
          SizedBox(height: AppSize.spaceXS),
          Button(width: null, title: label, action: retry)
        ]
      ]
    );
  }
}
