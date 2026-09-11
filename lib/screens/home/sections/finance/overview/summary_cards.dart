import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/money/money_summary_model.dart';

import '../money_format.dart';

/// The four figures the money screen opens with: what came in, what went out,
/// what left on credit and what that leaves.
///
/// They wrap instead of scrolling: unlike the tab bar these are read together
/// —the net only means something beside the two it comes from— so in a narrow
/// window they go onto a second line rather than pushing one of them out of
/// sight.
///
/// **The credit card is not income and is drawn apart from the other three.** A
/// ticket sold on account is the store's own tab: the goods left and the money
/// did not arrive. Counting a promise as money is how a register ends the day
/// short, so it is reported as what it is —money owed— and the receivables tab
/// is where it is chased.
class MoneySummaryCards extends StatelessWidget {
  const MoneySummaryCards({super.key, required this.summary});

  final MoneySummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final currency = summary.currency;

    return Wrap(
      spacing: AppSize.gap,
      runSpacing: AppSize.gap,
      children: [
        _Card(
          icon: CI.arrow_down,
          title: S.of(context).finance_income,
          amount: moneyLabel(summary.income, currency),
          accent: scheme.snackBar.success,
          // The two halves of the income are the whole reason it is split: the
          // register's takings come from the tickets and the rest from the
          // payments recorded by hand, and a shop that suddenly takes in half
          // as much wants to know which of the two moved.
          detail: "${S.of(context).finance_income_sales}"
            " ${moneyLabel(summary.sales.total, currency)}"
            "  ·  ${S.of(context).finance_income_payments}"
            " ${moneyLabel(summary.payments.total, currency)}"
        ),
        _Card(
          icon: CI.arrow_top,
          title: S.of(context).finance_expenses,
          amount: moneyLabel(summary.expenses.total, currency),
          accent: scheme.snackBar.error,
          detail: S.of(context).finance_movements(
            moneyCount(context, summary.expenses.count)
          )
        ),
        _Card(
          icon: CI.wallet,
          title: S.of(context).finance_net,
          amount: moneyLabel(summary.net, currency),
          // The net is not green or red by itself: it is the subtraction, and
          // its colour is whichever side it landed on.
          accent: summary.net < 0
            ? scheme.snackBar.error
            : scheme.snackBar.success,
          detail: S.of(context).finance_net_hint
        ),
        _Card(
          icon: CI.invoice_list,
          title: S.of(context).finance_credit,
          amount: moneyLabel(summary.credit.total, currency),
          accent: scheme.snackBar.alert,
          detail: S.of(context).finance_credit_hint
        )
      ]
    );
  }
}

/// One figure, on its own block over the body's sheet.
class _Card extends StatelessWidget {
  const _Card({
    required this.icon,
    required this.title,
    required this.amount,
    required this.accent,
    required this.detail
  });

  final IconData icon;
  final String title;
  final String amount;

  /// The colour of the icon and of the amount. It is what tells the four apart
  /// at a glance, which is how this row is read.
  final Color accent;

  /// The line under the amount: what it is made of, or what it means.
  final String detail;

  /// A fixed width and not a `Flexible`: the four are laid out in a [Wrap], so
  /// they need a measure of their own to decide when to break the line.
  static const double _width = 230;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return SizedBox(
      width: _width,
      child: Surface.over(
        padding: EdgeInsets.all(AppSize.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Icon(icon, size: AppSize.text, color: accent),
              SizedBox(width: AppSize.gap),
              Expanded(child: TextSmall(
                title,
                color: scheme.text.secondary,
                ellipsis: true
              ))
            ]),
            SizedBox(height: AppSize.spaceXS),
            TextLarge(amount, color: accent, ellipsis: true),
            SizedBox(height: AppSize.gap),
            TextSmall(
              detail,
              color: scheme.text.secondary,
              multiplier: 0.9,
              ellipsis: true
            )
          ]
        )
      )
    );
  }
}
