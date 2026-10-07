import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/money/money_receivable_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/finance/money_format.dart';

/// The three numbers the tab is opened for: how much was sold on credit, how
/// much of it has come in and how much is outstanding.
///
/// They are the filter's and not the page's, which is why they sit above the
/// list and not under it.
class ReceivablesTotals extends StatelessWidget {
  const ReceivablesTotals({super.key, required this.totals, required this.currency});

  final MoneyReceivableTotals totals;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Wrap(
      spacing: AppSize.gap,
      runSpacing: AppSize.gap,
      children: [
        _Total(
          title: S.of(context).finance_receivables_sold,
          amount: moneyLabel(totals.sold, currency),
          color: scheme.text.primary
        ),
        _Total(
          title: S.of(context).finance_receivables_collected,
          amount: moneyLabel(totals.collected, currency),
          color: scheme.snackBar.success
        ),
        _Total(
          title: S.of(context).finance_receivables_outstanding,
          amount: moneyLabel(totals.outstanding, currency),
          color: scheme.snackBar.alert
        )
      ]
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({
    required this.title,
    required this.amount,
    required this.color
  });

  final String title;
  final String amount;
  final Color color;

  /// A fixed width for the same reason as the summary cards: they are laid out
  /// in a [Wrap] and need a measure of their own to decide when to break.
  static const double _width = 190;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return SizedBox(
      width: _width,
      child: Surface.over(
        padding: EdgeInsets.all(AppSize.spaceXS),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextSmall(title, color: scheme.text.secondary, ellipsis: true),
            SizedBox(height: AppSize.gap),
            TextMedium(amount, bold: true, color: color, ellipsis: true)
          ]
        )
      )
    );
  }
}
