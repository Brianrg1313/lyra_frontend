import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// The grid's first card for whoever can write: where the next product goes, the size of the
/// others, so creating one is found where the products are and not only in the bar.
class MadeProductNewCard extends StatelessWidget {
  const MadeProductNewCard({super.key, required this.onCreate});

  final void Function() onCreate;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);
    final radius = AppSize.cornerInset(AppSize.spaceXS);
    final circle = AppSize.action;

    return FeedbackButton(
      action: onCreate,
      radius: radius,
      color: scheme.surface,
      feedbackColor: scheme.surfaceFeedback,
      child: Surface.line(
        radius: radius,
        color: scheme.surface,
        borderColor: scheme.line,
        padding: EdgeInsets.all(AppSize.padding),
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: circle,
            height: circle,
            decoration: BoxDecoration(color: scheme.button.fill, shape: BoxShape.circle),
            child: Icon(CI.plus, size: AppSize.text * 1.2, color: scheme.button.text)
          ),
          SizedBox(height: AppSize.spaceS),
          TextMedium(s.made_product_new, bold: true, textAlign: TextAlign.center),
          SizedBox(height: AppSize.gap),
          TextSmall(s.made_product_new_note, lines: 2, textAlign: TextAlign.center, color: scheme.text.secondary)
        ]))
      )
    );
  }
}
