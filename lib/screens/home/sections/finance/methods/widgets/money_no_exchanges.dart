import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/home/sections/finance/methods/methods_heading.dart';

/// What sits beside the main card while the company takes nothing else.
class MoneyNoExchanges extends StatelessWidget {
  const MoneyNoExchanges({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return SizedBox(
      width: kMoneyCardWidth,
      child: Padding(
        padding: EdgeInsets.all(AppSize.padding),
        child: Row(children: [
          Icon(CI.info, size: AppSize.text, color: scheme.text.secondary),
          SizedBox(width: AppSize.gap),
          Expanded(child: TextSmall(
            S.of(context).finance_currencies_empty,
            color: scheme.text.secondary,
            lines: 3
          ))
        ])
      )
    );
  }
}
