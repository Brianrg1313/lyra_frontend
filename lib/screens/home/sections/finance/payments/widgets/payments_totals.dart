import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/money/money_payment_model.dart';

// WIDGETS
import 'package:app/screens/home/sections/finance/money_format.dart';

/// What the whole filter adds up to, in each direction.
///
/// It is deliberately not the sum of the rows on screen: the list is one page
/// of a filter that can run into thousands of movements, and "cuanto llevo
/// pagado a proveedores este mes" is a question about the filter.
class PaymentsTotals extends StatelessWidget {
  const PaymentsTotals({super.key, required this.totals, required this.currency});

  final MoneyPaymentTotals totals;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Row(children: [
      _Total(
        icon: CI.arrow_down,
        label: S.of(context).finance_payments_in,
        value: totals.income.total,
        count: totals.income.count,
        currency: currency,
        color: scheme.snackBar.success
      ),
      SizedBox(width: AppSize.spaceM),
      _Total(
        icon: CI.arrow_top,
        label: S.of(context).finance_payments_out,
        value: totals.expense.total,
        count: totals.expense.count,
        currency: currency,
        color: scheme.snackBar.error
      )
    ]);
  }
}

class _Total extends StatelessWidget {
  const _Total({
    required this.icon,
    required this.label,
    required this.value,
    required this.count,
    required this.currency,
    required this.color
  });

  final IconData icon;
  final String label;
  final double value;
  final int count;
  final String currency;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: AppSize.text, color: color),
      SizedBox(width: AppSize.gap),
      TextSmall("$label:", color: scheme.text.secondary),
      SizedBox(width: AppSize.gap),
      TextMedium(
        moneyLabel(value, currency),
        bold: true,
        multiplier: 0.9,
        color: color
      ),
      SizedBox(width: AppSize.gap),
      TextSmall(
        "(${moneyCount(context, count)})",
        color: scheme.text.secondary,
        multiplier: 0.9
      )
    ]);
  }
}
