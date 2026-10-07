import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES

// SERVICES

// WIDGETS


/// The one control of the tab: whether the settled tickets are listed too.
class ReceivablesBar extends StatelessWidget {
  const ReceivablesBar({super.key, required this.openOnly, required this.onOpenOnly});

  final bool openOnly;
  final void Function(bool value) onOpenOnly;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Row(children: [
      FeedbackButton(
        action: () => onOpenOnly(!openOnly),
        height: AppSize.button,
        message: S.of(context).finance_receivables_open_only,
        padding: EdgeInsets.symmetric(horizontal: AppSize.spaceXS),
        radius: AppSize.cornerInset(AppSize.gap),
        color: openOnly ? scheme.line : scheme.surfaceOver,
        feedbackColor: scheme.lineOver,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            openOnly ? CI.chekmark : CI.circle,
            size: AppSize.text,
            color: openOnly ? scheme.text.primary : scheme.text.secondary
          ),
          SizedBox(width: AppSize.gap),
          TextMedium(
            S.of(context).finance_receivables_open_only,
            bold: openOnly,
            multiplier: 0.9,
            color: openOnly ? scheme.text.primary : scheme.text.secondary
          )
        ])
      )
    ]);
  }
}
