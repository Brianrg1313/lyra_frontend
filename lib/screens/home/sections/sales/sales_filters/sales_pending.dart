import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/sales/sales_service.dart';

// WIDGETS


/// Sales moved while the list was somewhere it could not follow them.
///
/// It only ever appears past the first page, or after a catch-up that failed:
/// on the first page the board picks the movements up by itself. It is a button
/// and not an automatic reload for one reason — rebuilding a list from the top
/// takes away the row somebody was reading, and on a work list that is the row
/// they were about to act on.
class SalesPending extends StatelessWidget {
  const SalesPending({super.key, required this.service});

  final SalesService service;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return FeedbackButton(
      action: service.refresh,
      height: AppSize.button,
      message: S.of(context).sales_pending(service.pending),
      padding: EdgeInsets.symmetric(horizontal: AppSize.spaceXS),
      radius: AppSize.cornerInset(AppSize.gap),
      color: scheme.line,
      feedbackColor: scheme.lineOver,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(CI.notification, size: AppSize.text, color: scheme.text.primary),
        SizedBox(width: AppSize.gap),
        TextMedium(
          S.of(context).sales_pending(service.pending),
          bold: true,
          multiplier: 0.9,
          color: scheme.text.primary
        )
      ])
    );
  }
}
