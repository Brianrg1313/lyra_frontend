import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// The deliveries still on their way, at the foot of the desk's panel.
///
/// Placeholder: the backend has no endpoint for the list yet, so it only says
/// what will be here.
class PendingDeliveries extends StatelessWidget {
  const PendingDeliveries({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Row(children: [
      Icon(CI.delivery, size: AppSize.text * 1.4, color: scheme.icon),
      SizedBox(width: AppSize.spaceS),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextSmall(
            "${S.of(context).deliveries_pending_title} · ${S.of(context).coming_soon}",
            bold: true,
            ellipsis: true
          ),
          TextSmall(
            S.of(context).deliveries_pending_soon,
            lines: 2,
            ellipsis: true,
            color: scheme.text.secondary
          )
        ]
      ))
    ]);
  }
}
