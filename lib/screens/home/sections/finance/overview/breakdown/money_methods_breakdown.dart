import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/money/money_summary_model.dart';

import './money_breakdown_block.dart';
import './money_breakdown_figure.dart';

/// What moved through each settlement kind.
class MoneyMethodsBreakdown extends StatelessWidget {
  const MoneyMethodsBreakdown({super.key, required this.summary});

  final MoneySummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return MoneyBreakdownBlock(
      title: S.of(context).finance_by_method,
      children: [
        for (final row in summary.methods) Padding(
          padding: EdgeInsets.only(top: AppSize.gap),
          child: Row(children: [
            Expanded(child: TextSmall(
              // The backend writes the name; a kind it has no name for is
              // still drawn, with its code, rather than as a blank row.
              row.name.isNotEmpty ? row.name : row.method,
              ellipsis: true
            )),
            SizedBox(width: AppSize.gap),
            MoneyBreakdownFigure(
              value: row.income,
              currency: summary.currency,
              color: scheme.snackBar.success
            ),
            SizedBox(width: AppSize.spaceXS),
            MoneyBreakdownFigure(
              value: row.expense,
              currency: summary.currency,
              color: scheme.snackBar.error
            )
          ])
        )
      ]
    );
  }
}
