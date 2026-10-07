import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES

// SERVICES

// WIDGETS


/// One area of the spend: what it is, what it is made of, and what it cost.
class MoneyBotRow extends StatelessWidget {
  const MoneyBotRow({
    super.key,
    required this.icon,
    required this.title,
    required this.amount,
    required this.detail
  });

  final IconData icon;
  final String title;
  final String amount;

  /// What this line covers, or what it counts. It carries **no money**: the
  /// amounts of a card are its four totals and nothing else, so that the figure
  /// somebody came to read is never one of eight on the sheet.
  final String detail;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Padding(
      padding: EdgeInsets.only(top: AppSize.gap),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSize.text * 0.9, color: scheme.text.secondary),
          SizedBox(width: AppSize.gap),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextSmall(title, ellipsis: true),
              TextSmall(
                detail,
                color: scheme.text.secondary,
                multiplier: 0.85,
                ellipsis: true
              )
            ]
          )),
          SizedBox(width: AppSize.gap),
          // Bold and in the plain text colour, like the total above: these four
          // and that one are the prices of this card, and they are meant to be
          // findable without reading a word around them.
          TextMedium(amount, bold: true, color: scheme.text.primary)
        ]
      )
    );
  }
}
