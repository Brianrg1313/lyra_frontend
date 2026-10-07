import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/money/money_summary_model.dart';

import './money_breakdown_block.dart';
import './money_breakdown_figure.dart';

/// What moved under each concept.
class MoneyConceptsBreakdown extends StatelessWidget {
  const MoneyConceptsBreakdown({super.key, required this.summary});

  final MoneySummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return MoneyBreakdownBlock(
      title: S.of(context).finance_by_concept,
      children: [
        for (final row in summary.concepts) Padding(
          padding: EdgeInsets.only(top: AppSize.gap),
          child: Row(children: [
            Icon(
              row.direction.isIncoming ? CI.arrow_down : CI.arrow_top,
              size: AppSize.text * 0.9,
              color: row.direction.isIncoming
                ? scheme.snackBar.success
                : scheme.snackBar.error
            ),
            SizedBox(width: AppSize.gap),
            Expanded(child: TextSmall(
              row.name.isNotEmpty ? row.name : row.concept,
              ellipsis: true
            )),
            SizedBox(width: AppSize.gap),
            MoneyBreakdownFigure(
              value: row.total,
              currency: summary.currency,
              color: row.direction.isIncoming
                ? scheme.snackBar.success
                : scheme.snackBar.error
            )
          ])
        )
      ]
    );
  }
}
