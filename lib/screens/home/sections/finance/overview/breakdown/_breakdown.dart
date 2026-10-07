import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/money/money_summary_model.dart';

import './money_concepts_breakdown.dart';
import './money_methods_breakdown.dart';

/// Where the money of the window came in and went out through.
///
/// The two breakdowns answer different questions and that is why they are two
/// blocks and not one table with a column for each:
///
/// * **By method** —cash, transfer, mobile— is what a register is reconciled
///   against: the drawer is counted, the bank statement is read. A method goes
///   both ways, so it carries the two figures and the balance between them.
/// * **By concept** —a supplier, a refund, a settlement— is what the money was
///   for. A concept only goes one way (its direction is part of what it means),
///   so it carries one figure and its direction says which side of the screen
///   it belongs on.
///
/// They are grouped by settlement kind and not by the company's own accounts:
/// two bank accounts of one shop are both transfers, and "cuanto entro en
/// efectivo" is a question about the rail.
class MoneyBreakdown extends StatelessWidget {
  const MoneyBreakdown({super.key, required this.summary});

  final MoneySummary summary;

  /// Below this width the two blocks stop fitting side by side with their four
  /// columns and go one under the other. It is measured against the body of the
  /// section, not the window: the side bar takes its share first.
  static const double _twoColumns = 760;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final methods = MoneyMethodsBreakdown(summary: summary);
      final concepts = MoneyConceptsBreakdown(summary: summary);

      if (constraints.maxWidth < _twoColumns) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            methods,
            SizedBox(height: AppSize.gap),
            concepts
          ]
        );
      }

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: methods),
          SizedBox(width: AppSize.gap),
          Expanded(child: concepts)
        ]
      );
    }
  );
}
